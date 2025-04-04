module WorkshopCompanion

# precompile all packages
using Graphs
using IJulia
using ModelingToolkit
using NetworkDynamics
using NetworkDynamicsInspector
using OpPoDyn
using OrdinaryDiffEqNonlinearSolve
using OrdinaryDiffEqRosenbrock
using PrecompileTools
using WGLMakie

@compile_workload begin
    # include("_precompile_workload.jl")
end

end # module WorkshopCompanion
