#=
# OpPoDyn.jl - A Power System Dynamics Library
## Introduction

cd("notebook")
import Pkg; Pkg.activate("notebook")
=#
using WorkshopCompanion
using OpPoDyn, OpPoDyn.Library
using NetworkDynamics, NetworkDynamicsInspector
using NetworkDynamics: SII
using ModelingToolkit
using ModelingToolkit: D_nounits as Dt, t_nounits as t
using OrdinaryDiffEqRosenbrock, OrdinaryDiffEqNonlinearSolve, DiffEqCallbacks
using SciMLSensitivity, Optimization, Optimisers
using LinearAlgebra
using CairoMakie, DataFrames, Graphs

@time nw = WorkshopCompanion.load_39bus()

#=
## Inspection of Models
=#
nw[VIndex(30)]
# also metadata like
nw[VIndex(30)].metadata[:equations]
# inspect the initial state
dump_initial_state(nw[VIndex(30)])

#=
## Solve Powerflow

=#
OpPoDyn.solve_powerflow!(nw)

# now we have our "boundaries" defined
dump_initial_state(nw[VIndex(39)])

#=
## Component Initialization
=#

findall(nw[VIndex(31)].metadata[:observed]) do eq
    contains(repr(eq.lhs), "u_r")
end
nw[VIndex(31)].metadata[:observed][30]

nw[VIndex(31)]
dump_initial_state(nw[VIndex(31)])

nw[VIndex(31)].metadata[:observed][2]
nw[VIndex(31)].metadata[:observed][18]
nw[VIndex(31)].metadata[:observed][24]
nw[VIndex(31)].metadata[:observed][25]
nw[VIndex(31)].metadata[:observed][30]



v31_mag = norm(get_initial_state(nw, VIndex(31, [:busbar₊u_r, :busbar₊u_i])))
v39_mag = norm(get_initial_state(nw, VIndex(39, [:busbar₊u_r, :busbar₊u_i])))
set_default!(nw, VIndex(31,:load₊Vset), v31_mag)
set_default!(nw, VIndex(39,:load₊Vset), v39_mag)
OpPoDyn.initialize!(nw)

#=
## Define of a Perturbation

=#
const cb_verbose = Ref(true)
_enable_short = ComponentAffect([], [:pibranch₊shortcircuit]) do u, p, ctx
    cb_verbose[] && @info "Activate short circuit on line $(ctx.src)=>$(ctx.dst) at t = $(ctx.t)"
    p[:pibranch₊shortcircuit] = 1
end
_disable_line = ComponentAffect([], [:pibranch₊active]) do u, p, ctx
    cb_verbose[] && @info "Deactivate line $(ctx.src)=>$(ctx.dst) at t = $(ctx.t)"
    p[:pibranch₊active] = 0
end
shortcircuit_cb = PresetTimeComponentCallback(0.1, _enable_short)
deactivate_cb = PresetTimeComponentCallback(0.2, _disable_line)

affected_edge = 11
add_callback!(nw[EIndex(11)], shortcircuit_cb)
add_callback!(nw[EIndex(11)], deactivate_cb)
nw[EIndex(11)]



#=
## Simulation
=#
u0 = NWState(nw)
prob = ODEProblem(nw, uflat(u0), (0,15), pflat(u0); callback=get_callbacks(nw))
sol = solve(prob, Rodas5P())

#=
## Plotting some results
=#
let fig = Figure()
    ax = Axis(fig[1, 1]; title="Power in affected line")
    ts = range(0, 0.28,length=1000)
    lines!(ax, ts, sol(ts; idxs=EIndex(6, :src₊P)).u; label="P (source end)")
    lines!(ax, ts, sol(ts; idxs=EIndex(6, :dst₊P)).u; label="P (destination end)")
    lines!(ax, ts, sol(ts; idxs=@obsex(-EIndex(6, :src₊P)-EIndex(6, :dst₊P))).u; linestyle=:dot, label="P loss")
    axislegend(ax)
    fig
end

let fig = Figure()
    ax = Axis(fig[1, 1]; title="Voltage at surrounding buses")
    ts = range(0, 0.3, length=1000)
    lines!(ax, ts, sol(ts; idxs=VIndex(3, :busbar₊u_mag)).u; label="u mag at 3")
    lines!(ax, ts, sol(ts; idxs=VIndex(4, :busbar₊u_mag)).u; label="u mag at 3")
    axislegend(ax, position=:rb)
    fig
end

let fig = Figure()
    ax = Axis(fig[1, 1]; title="Voltage magnitued everywhere")
    ts = range(0, 15, length=1000)
    for i in 1:39
        lines!(ax, ts, sol(ts; idxs=VIndex(i, :busbar₊u_mag)).u)
    end
    fig
end

vidxs(nw, 30, "ω")
let fig = Figure()
    ax = Axis(fig[1, 1]; title="Frequencies at Generators")
    ts = range(0, 15, length=1000)
    for i in 30:39
        lines!(ax, ts, sol(ts; idxs=only(vidxs(nw, i, r"machine₊ω$"))).u)
    end
    fig
end

#=
modifying the network
=#
vertexms = [nw[VIndex(i)] for i in 1:nv(nw)];
edgems = [nw[EIndex(i)] for i in 1:ne(nw)];

@mtkmodel DroopInverter begin
    @components begin
        terminal = Terminal()
    end
    @parameters begin
        Pset, [description="Active power setpoint", guess=1]
        Qset, [description="Reactive power setpoint", guess=0]
        Vset, [description="Voltage setpoint", guess=1]
        ω₀=1, [description="Nominal frequency"]
        Kp=1.0, [description="Droop coefficient"]
        Kq=0.01, [description="Reactive power droop coefficient"]
        τ = 0.1, [description="Power filter constant"]
    end
    @variables begin
        Pmeas(t), [description="Active power measurement", guess=1]
        Qmeas(t), [description="Reactive power measurement", guess=0]
        Pfilt(t), [description="Filtered active power", guess=1]
        Qfilt(t), [description="Filtered reactive power", guess=1]
        ω(t), [description="Frequency"]
        δ(t), [description="Voltage angle", guess=0]
        V(t), [description="Voltage magnitude"]
    end
    @equations begin
        Pmeas ~ terminal.u_r*terminal.i_r + terminal.u_i*terminal.i_i
        Qmeas ~ terminal.u_r*terminal.i_i - terminal.u_i*terminal.i_r
        τ * Dt(Pfilt) ~ Pmeas - Pfilt
        τ * Dt(Qfilt) ~ Qmeas - Qfilt
        ω ~ ω₀ - Kp * (Pfilt - Pset) # lower omega when P is higher than setpoint
        V ~ Vset - Kq * (Qfilt - Qset) # lower voltage when Q is higher than setpoint
        Dt(δ) ~ ω - ω₀
        terminal.u_r ~ V*cos(δ)
        terminal.u_i ~ V*sin(δ)
    end
end

@named inverter = DroopInverter()
mtkbus = MTKBus(inverter)

DROOP_IDX = 32
pfmodel = vertexms[DROOP_IDX].metadata[:pfmodel]
droopbus = Bus(mtkbus; pf=pfmodel, vidx=DROOP_IDX, name=:DroopInverter)
vertexms[DROOP_IDX] = droopbus

nw_droop = Network(vertexms, edgems)

pf = solve_powerflow!(nw_droop)
set_default!(nw_droop, VIndex(31,:load₊Vset), pf."vm [pu]"[31])
set_default!(nw_droop, VIndex(39,:load₊Vset), pf."vm [pu]"[39])
set_default!(nw_droop, VIndex(DROOP_IDX,:inverter₊Vset),  pf."vm [pu]"[DROOP_IDX])
OpPoDyn.initialize!(nw_droop)

dump_initial_state(nw_droop[VIndex(DROOP_IDX)])

u0_droop = NWState(nw_droop)
prob_droop = ODEProblem(nw_droop, copy(uflat(u0_droop)), (0,15), copy(pflat(u0_droop)); callback=get_callbacks(nw_droop))
sol_droop = solve(prob_droop, Rodas5P())
let fig = Figure()
    ts = range(0.3, 15, length=1000)
    ax = Axis(fig[1, 1]; title="Voltage magnitude at Bus $DROOP_IDX")
    lines!(ax, ts, sol(ts; idxs=VIndex(DROOP_IDX, :busbar₊u_mag)).u; label="Reference Solution", linestyle=:dash)
    lines!(ax, ts, sol_droop(ts; idxs=VIndex(DROOP_IDX, :busbar₊u_mag)).u; label="Droop Solution")
    axislegend(ax)
    fig
end

break


opt_ref = sol(0.3:0.1:10, idxs=[VIndex(1:39, :busbar₊u_r), VIndex(1:39, :busbar₊u_i)])
tunable_parameters = [:inverter₊Kp, :inverter₊Kq, :inverter₊τ]
tp_idx = SII.parameter_index(sol_droop, VIndex(DROOP_IDX, tunable_parameters))

cb_verbose[] = false
function loss(p)
    allp = similar(p, length(u0_droop.p))
    allp .= pflat(u0_droop.p)
    allp[tp_idx] .= p
    _sol = solve(prob_droop, Rodas5P(autodiff=true);
        p = allp, saveat = 0.01, tspan=(0.0, opt_ref.t[end]),
        initializealg = SciMLBase.NoInit(), 
    )
    SciMLBase.successful_retcode(_sol) || return Inf

    x = _sol(opt_ref.t; idxs=[VIndex(1:39, :busbar₊u_r), VIndex(1:39, :busbar₊u_i)])
    res = opt_ref.u - x.u
    return sum(abs2, reduce(vcat, res))
end

function plot_pset(this_p)
    if !(this_p isa Observable)
        this_p = Observable(this_p)
    end
    fig = Figure(size=(1000,500))
    busses = [3,4,25,DROOP_IDX]
    cols = 2
    rows = ceil(Int, length(busses) / cols)
    ts = range(0, 10, length=1000)
    # Use parameters from the last optimization state
    p_opt = @lift let
        _p = copy(pflat(u0_droop))
        _p[tp_idx] .= $this_p
        _p
    end
    # Create and solve problem with optimized parameters
    sol_opt = @lift solve(prob_droop, Rodas5P(); p=$p_opt)

    for (i, bus) in enumerate(busses)
        row, col = divrem(i-1, cols) .+ (0, 1)
        ax = Axis(fig[row+1, col]; title="Bus $bus Voltage Magnitude")
        ylims!(ax, 0.9, 1.15)
        lines!(ax, ts, sol(ts; idxs=VIndex(bus, :busbar₊u_mag)).u;
               label="Reference", linestyle=:solid, color=:blue)
        lines!(ax, ts, sol_droop(ts; idxs=VIndex(bus, :busbar₊u_mag)).u;
               label="Initial Droop", linestyle=:dash, color=:red)
        dat = @lift $sol_opt(ts; idxs=VIndex(bus, :busbar₊u_mag)).u
        lines!(ax, ts, dat; label="Optimized Droop", color=:green)
        i == 1 && axislegend(ax; position=:rb)
    end
    fig
end

p0 = sol_droop(sol_droop.t[begin], idxs=collect(VIndex(DROOP_IDX, tunable_parameters)))
optf = Optimization.OptimizationFunction((x, p) -> loss(x), Optimization.AutoForwardDiff())

pobs = Observable(p0)
plot_pset(pobs)
states = Any[]
callback = function (state, l)
    push!(states, state)
    pobs[] = state.u
    println(l)
    return false
end
optprob = Optimization.OptimizationProblem(optf, p0; callback)
optsol = Optimization.solve(optprob, OptimizationPolyalgorithms.Optimisers.Adam(0.1), maxiters = 7)

fig = plot_pset(pobs)
record(fig, "droop_optimization.mp4", states; framerate=3) do s
    pobs[] = s.u
    fig
end

inspect(sol_droop)
