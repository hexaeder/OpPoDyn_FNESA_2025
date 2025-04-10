#=
# OpPoDyn.jl - A Power System Dynamics Library
## Introduction

cd("notebook")
import Pkg; Pkg.activate("notebook")
=#
using WorkshopCompanion
using OpPoDyn
using OpPoDyn.Library
using ModelingToolkit
using NetworkDynamics
using CairoMakie
using DataFrames
using OrdinaryDiffEqRosenbrock
using OrdinaryDiffEqNonlinearSolve
using DiffEqCallbacks
using LinearAlgebra
using NetworkDynamicsInspector
using ModelingToolkit
using ModelingToolkit: D_nounits as Dt, t_nounits as t
using Graphs

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
        Kp=0.1, [description="Droop coefficient"]
        Kq=0.1, [description="Reactive power droop coefficient"]
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

pfmodel = vertexms[30].metadata[:pfmodel]
droopbus = Bus(mtkbus; pf=pfmodel, vidx=30, name=:DroopInverter)
# vertexms[30] = droopbus

nw_droop = Network(vertexms, edgems)
describe_vertices(nw_droop; batch=3:6)

pf = solve_powerflow!(nw_droop)
set_default!(nw_droop, VIndex(31,:load₊Vset), pf."vm [pu]"[31])
set_default!(nw_droop, VIndex(39,:load₊Vset), pf."vm [pu]"[39])
# set_default!(nw_droop, VIndex(30,:inverter₊Vset),  pf."vm [pu]"[30])
OpPoDyn.initialize!(nw_droop)

dump_initial_state(nw_droop[VIndex(30)])

u0_droop = NWState(nw_droop)
# u0_droop.v[30, :inverter₊Kp] = 0.0005
# u0_droop.v[30, :inverter₊Kq] = -0.04
# u0_droop.v[30, :inverter₊τ] = 0.01
u0_droop.v[30, :ctrld_gen₊machine₊H] = 4.0
prob_droop = ODEProblem(nw_droop, copy(uflat(u0_droop)), (0,15), copy(pflat(u0_droop)); callback=get_callbacks(nw_droop))
sol_droop = solve(prob_droop, Rodas5P())
let fig = Figure()
    ax = Axis(fig[1, 1]; title="Frequency at Bus 30")
    ts = range(0, 5, length=1000)
    lines!(ax, ts, sol(ts; idxs=VIndex(30, :ctrld_gen₊machine₊ω)).u; label="Reference Solution")
    lines!(ax, ts, sol_droop(ts; idxs=VIndex(30, :ctrld_gen₊machine₊ω)).u; label="Droop Solution")
    # lines!(ax, ts, sol_droop(ts; idxs=VIndex(30, :inverter₊ω)).u; label="Droop Solution")
    axislegend(ax; position=:rb)
    ax = Axis(fig[2, 1]; title="Voltage magnitude at Bus 30")
    lines!(ax, ts, sol(ts; idxs=VIndex(30, :busbar₊u_mag)).u; label="Reference Solution")
    lines!(ax, ts, sol_droop(ts; idxs=VIndex(30, :busbar₊u_mag)).u; label="Droop Solution")
    axislegend(ax)
    # display(fig)
    fig
end


let fig = Figure()
    # ax = Axis(fig[1, 1]; title="Phase Angle at Bus 30")
    # ts = range(0, 0.28, length=1000)
    # lines!(ax, ts, sol(ts; idxs=VIndex(30, :busbar₊u_arg)).u; label="Reference Solution")
    # lines!(ax, ts, sol_droop(ts; idxs=VIndex(30, :busbar₊u_arg)).u; label="Droop Solution")
    # axislegend(ax)
    # ax = Axis(fig[2, 1]; title="Voltage Magnitude at Bus 30")
    # ts = range(0, 0.28, length=1000)
    # lines!(ax, ts, sol(ts; idxs=VIndex(30, :busbar₊u_mag)).u; label="Reference Solution")
    # lines!(ax, ts, sol_droop(ts; idxs=VIndex(30, :busbar₊u_mag)).u; label="Droop Solution")
    # axislegend(ax)
    ax = Axis(fig[1, 1]; title="Active power injection at Bus 30")
    ts = range(0, 15, length=1000)
    lines!(ax, ts, sol(ts; idxs=VIndex(30, :busbar₊P)).u; label="Reference Solution")
    lines!(ax, ts, sol_droop(ts; idxs=VIndex(30, :busbar₊P)).u; label="Droop Solution")
    axislegend(ax; position=:rb)
    ax = Axis(fig[2, 1]; title="Reactive power injection at Bus 30")
    lines!(ax, ts, sol(ts; idxs=VIndex(30, :busbar₊Q)).u; label="Reference Solution")
    lines!(ax, ts, sol_droop(ts; idxs=VIndex(30, :busbar₊Q)).u; label="Droop Solution")
    axislegend(ax)
    fig
end
let
    fig, ax, p = lines(sol_droop; idxs=VIndex(30, :inverter₊Pmeas));
    # lines!(sol_droop; idxs=VIndex(30, :inverter₊Pfilt))
    ax = Axis(fig[2, 1]; title="frequency")
    lines!(ax, sol_droop; idxs=VIndex(30, :inverter₊ω))
    fig
end
# inspect(sol_droop)
break


using NetworkDynamics: SII
using SciMLSensitivity
using SciMLSensitivity.ForwardDiff
using SciMLSensitivity.ReverseDiff
using SciMLSensitivity.Zygote
using Optimization, OptimizationPolyalgorithms

# sol(1:0.1:15, idxs=vidxs(sol_droop, 1:39, [:busbar₊u_r, :busbar₊u_i]))
# opt_ref = sol(1:0.1:15, idxs=vidxs(sol_droop, 1:39, [:busbar₊u_r, :busbar₊u_i]))
opt_ref = sol(0.0:0.1:15, idxs=VIndex(30, :busbar₊u_mag))
# lines(opt_ref.u)
# opt_ref = sol(0:0.1:15, idxs=[1,2])

# tunable_parameters = [:inverter₊Kp, :inverter₊Kq, :inverter₊τ]
tunable_parameters = [:ctrld_gen₊machine₊H]
tp_idx = SII.parameter_index(sol_droop, VIndex(30,tunable_parameters))
# _prob_droop_nocb = remake(prob_droop, callback=nothing)

cb_verbose[] = false
function loss(p)
    println("calc loss")
    # println("p = ", p)
    allp = similar(p, length(u0_droop.p))
    allp .= pflat(u0_droop.p)
    allp[tp_idx] .= p
    _sol = solve(prob_droop, Rodas5P(autodiff=true); p = allp, saveat = 0.01,
        initializealg = SciMLBase.NoInit(),
        # sensealg = InterpolatingAdjoint(; autojacvec=ReverseDiffVJP()),
        # sensealg = InterpolatingAdjoint(; autojacvec=true),
        # sensealg = GaussAdjoint(; autojacvec=true),
    )
    @assert SciMLBase.successful_retcode(_sol)
    # let
    #     fig, ax, p =lines(_sol; idxs=VIndex(30, :busbar₊u_mag))
    #     lines!(sol; idxs=VIndex(30, :busbar₊u_mag))
    #     fig
    # end
    # l = zero(eltype(p))
    # for (t, ref) in tuples(opt_ref)
    #     idx = findfirst(isequal(t), _sol.t)
    #     idx= 1
    #     l += sum(abs2, _sol[idx][1:2] - ref[1:2])
    # end
    #=
    let
        fig, ax, p = lines(opt_ref.u)
        lines!(_sol(opt_ref.t; idxs=VIndex(30, :busbar₊u_mag)).u)
        fig
    end
    =#
    res = opt_ref.u - _sol(opt_ref.t; idxs=VIndex(30, :busbar₊u_mag)).u
    # res = _sol(_sol.t; idxs=VIndex(30, :busbar₊u_mag)).u
    l = sum(abs2, res)
    # l = sum(abs2, _sol)
    # l = sum(_sol[3])
    # println("loss = ", l)
    println("end calc loss")
    return l
end

losses = Float64[]
states = Any[]
callback = function (state, l)
    push!(losses, l)
    push!(states, state)
    display(l)
    return false
end

# _sol[1]
# zip(_sol.t
#     opt_ref
#     res = _sol(_sol.t; idxs=VIndex(30, :busbar₊u_mag)).u

# @time ForwardDiff.gradient(loss, [0.0005, -0.04, 0.01])
# @time ForwardDiff.gradient(loss, states[begin].u)
# @time ForwardDiff.gradient(loss, states[end].u)
# @time ReverseDiff.gradient(loss, [0.0005, -0.04, 0.01])
# @time Zygote.gradient(loss, [0.0005, -0.04, 0.01])

# p0 = sol_droop(sol_droop.t[begin], idxs=collect(VIndex(30, tunable_parameters)))
p0 = [2.0]
optf = Optimization.OptimizationFunction((x, p) -> loss(x), Optimization.AutoForwardDiff())
optprob = Optimization.OptimizationProblem(optf, p0; callback)
# optsol = Optimization.solve(optprob, PolyOpt(), maxiters = 2)
# optsol = Optimization.solve(optprob, OptimizationPolyalgorithms.Optimisers.Descent(0.01), maxiters = 20)
optsol = Optimization.solve(optprob, OptimizationPolyalgorithms.Optimisers.Adam(0.1), maxiters = 30)

scatter(losses)

optsol.stats
optsol
loss([1.811])
loss([2.0])
loss([4.2])
nw[VIndex(30)]




# using OrdinaryDiffEq,
#       Optimization, OptimizationPolyalgorithms, SciMLSensitivity,
#       Zygote, Plots
using Optimization, OptimizationPolyalgorithms, SciMLSensitivity

function lotka_volterra!(du, u, p, t)
    x, y = u
    α, β, δ, γ = p
    du[1] = dx = α * x - β * x * y
    du[2] = dy = -δ * y + γ * x * y
end

# Initial condition
u0 = [1.0, 1.0]

# Simulation interval and intermediary points
tspan = (0.0, 10.0)
tsteps = 0.0:0.1:10.0

# LV equation parameter. p = [α, β, δ, γ]
p = [1.5, 1.0, 3.0, 1.0]

# Setup the ODE problem, then solve
prob = ODEProblem(lotka_volterra!, u0, tspan, p)
sol = solve(prob, Rodas5P())

function loss(p)
    sol = solve(prob, Rodas5P(), p = p, saveat = tsteps)
    loss = sum(abs2, sol .- 1)
    return loss
end

adtype = Optimization.AutoZygote()
optf = Optimization.OptimizationFunction((x, p) -> loss(x), adtype)
optprob = Optimization.OptimizationProblem(optf, p)

result_ode = Optimization.solve(optprob, PolyOpt(), maxiters = 100)






#=
## Inspection of the results
=#
# inspect(sol; restart=true, reset=true, display=ServerDisp())
