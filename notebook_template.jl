#=
# OpPoDyn.jl - A Power System Dynamics Library
## Introduction

##
=#
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

constructors = Dict("MTKBus"=>MTKBus, "MTKLine"=>MTKLine, "CopositeInjector"=>CompositeInjector, "pfPQ"=>pfPQ, "pfPV"=>pfPV, "pfSlack"=>pfSlack, "Bus"=>Bus, "Line"=>Line, "PiLine_fault"=>PiLine_fault, "ZIPLoad"=>ZIPLoad, "SauerPaiMachine"=>SauerPaiMachine, "AVRTypeI"=>AVRTypeI, "TGOV1"=>TGOV1, "CompositeInjector"=>CompositeInjector,)
edgems, vertexms = @time NetworkDynamics.load_components(constructors, joinpath(pkgdir(OpPoDyn), "docs", "examples", "ieee39.yaml"));
nw = Network(copy.(edgems), copy.(vertexms))

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

v31_mag = norm(get_initial_state(nw, VIndex(31, [:busbar₊u_r, :busbar₊u_i])))
v39_mag = norm(get_initial_state(nw, VIndex(39, [:busbar₊u_r, :busbar₊u_i])))
set_default!(nw, VIndex(31,:load₊Vset), v31_mag)
set_default!(nw, VIndex(39,:load₊Vset), v39_mag)
OpPoDyn.initialize!(nw)

#=
## Define of a Perturbation

=#
_enable_short = ComponentAffect([], [:pibranch₊shortcircuit]) do u, p, ctx
    @info "Activate short circuit on line $(ctx.src)=>$(ctx.dst) at t = $(ctx.t)"
    p[:pibranch₊shortcircuit] = 1
end
_disable_line = ComponentAffect([], [:pibranch₊active]) do u, p, ctx
    @info "Deactivate line $(ctx.src)=>$(ctx.dst) at t = $(ctx.t)"
    p[:pibranch₊active] = 0
end
shortcircuit_cb = PresetTimeComponentCallback(0.1, _enable_short)
deactivate_cb = PresetTimeComponentCallback(0.1+0.0833, _disable_line)

add_callback!(nw[EIndex(6)], shortcircuit_cb)
add_callback!(nw[EIndex(6)], deactivate_cb)
nw[EIndex(6)]



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
## Inspection of the results
=#
inspect(sol; restart=true, reset=true, display=ServerDisp())
