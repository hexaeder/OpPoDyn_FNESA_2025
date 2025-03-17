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
Literate.notebook(template, TMPDIR; execute=false, name="Workshop")

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

current_rev = if haskey(ENV, "GITHUB_ACTIONS")
    ENV["GITHUB_SHA"]  # Available automatically in GitHub Actions
else
    "main"  # Default for local runs
end

project["sources"][companion_name] = Dict(
    "url" => "https://github.com/hexaeder/OpPoDyn_FNESA_2025",
    "rev" => current_rev
)

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

if isfile(joinpath(NBDIR, "Workshop.ipynb"))
    @info "Replace notebook/Workshop.ipynb with new version"
    rm(joinpath(NBDIR, "Workshop.ipynb"))
else
    @info "Create notebook/Workshop.ipynb"
end
mv(joinpath(TMPDIR, "Workshop.ipynb"), joinpath(NBDIR, "Workshop.ipynb"))
