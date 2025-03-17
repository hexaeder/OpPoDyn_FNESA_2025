module WorkshopCompanion

# precompile all packages
using Graphs
using IJulia
using Literate
using ModelingToolkit
using NetworkDynamics
using NetworkDynamicsInspector
using OpPoDyn
using OrdinaryDiffEqNonlinearSolve
using OrdinaryDiffEqRosenbrock
using PrecompileTools
using WGLMakie

@compile_workload begin
    template = joinpath(@__DIR__, "..", "notebook_template.jl")
    outdir = mktempdir()
    Literate.script(template, outdir; name="precompile_workload", execute=true)
end

end # module WorkshopCompanion
