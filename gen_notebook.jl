#!julia --startup-file=no

BASEDIR = @__DIR__
NBDIR = joinpath(BASEDIR, "notebook")

@info "Generating notebook from template"

# use global env in github actions
if !haskey(ENV, "GITHUB_ACTIONS")
    import Pkg; Pkg.activate(@__DIR__)
end

using Literate

template = joinpath(BASEDIR, "notebook_template.jl")
@assert isfile(template)

TMPDIR = mktempdir()
Literate.script(template, TMPDIR, name="_precompile_workload")
Literate.notebook(template, TMPDIR; execute=false, name="workshop")

using TOML
project = TOML.parsefile(joinpath(BASEDIR, "Project.toml"))

companion_name = project["name"]
companion_uuid = project["uuid"]

# remove the blocsk we don't need
delete!(project, "name")
delete!(project, "uuid")
delete!(project, "authors")
delete!(project, "version")

UNUSED_DEPS = ["Literate", "PrecompileTools"]
for dep in UNUSED_DEPS
    delete!(project["deps"], dep)
    delete!(project["compat"], dep)
end

project["deps"][companion_name] = companion_uuid

project["sources"][companion_name] = if haskey(ENV, "GITHUB_ACTIONS")
    # Available automatically in GitHub Actions
    Dict(
        "url" => "https://github.com/hexaeder/OpPoDyn_FNESA_2025",
        "rev" => ENV["GITHUB_SHA"]
    )
else
    Dict("path" => "..",)
end


open(joinpath(TMPDIR, "Project.toml"), "w") do io
    TOML.print(io, project)
end

ispath(NBDIR) || mkpath(NBDIR)

if isfile(joinpath(NBDIR, "Project.toml"))
    @info "Replace notebook/Project.toml with new version"
    rm(joinpath(NBDIR, "Project.toml"))
else
    @info "Create notebook/Project.toml"
end
mv(joinpath(TMPDIR, "Project.toml"), joinpath(NBDIR, "Project.toml"))

if isfile(joinpath(NBDIR, "workshop.ipynb"))
    @info "Replace notebook/workshop.ipynb with new version"
    rm(joinpath(NBDIR, "workshop.ipynb"))
else
    @info "Create notebook/workshop.ipynb"
end
mv(joinpath(TMPDIR, "workshop.ipynb"), joinpath(NBDIR, "workshop.ipynb"))

PRECOMPILE_TARGET = joinpath(BASEDIR, "src", "_precompile_workload.jl")
PRECOMPILE_SRC = joinpath(TMPDIR, "_precompile_workload.jl")
if isfile(PRECOMPILE_TARGET)
    # check if file content changed
    old = read(PRECOMPILE_TARGET, String)
    new = read(PRECOMPILE_SRC, String)
    if old == new
        @info "Precompile script did not change"
    else
        rm(PRECOMPILE_TARGET)
        mv(PRECOMPILE_SRC, PRECOMPILE_TARGET)
        @info "Replaced precompile script"
    end
else
    mv(PRECOMPILE_SRC, PRECOMPILE_TARGET)
    @info "Created precompile script"
end
