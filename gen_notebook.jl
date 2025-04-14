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

# Define custom preprocessing function to filter #norelease lines
function filter_norelease(content)
    lines = split(content, '\n')
    filtered_lines = filter(line -> !contains(line, "#norelease"), lines)
    return join(filtered_lines, '\n')
end

# generate two versions: filtered and non filtered
TMPDIR = mktempdir()
Literate.notebook(template, TMPDIR; execute=false, name="workshop", preprocess=filter_norelease)
Literate.notebook(template, TMPDIR; execute=false, name="workshop_full")

using TOML
project = TOML.parsefile(joinpath(BASEDIR, "Project.toml"))

companion_name = project["name"]
companion_uuid = project["uuid"]

# change name of env
project["name"] = "OpPoDynWorkshopEnv"
# remove the blocsk we don't need
delete!(project, "uuid")
delete!(project, "authors")
delete!(project, "version")

UNUSED_DEPS = ["Literate", "PrecompileTools"]
for dep in UNUSED_DEPS
    delete!(project["deps"], dep)
    delete!(project["compat"], dep)
end

project["deps"][companion_name] = companion_uuid

# for release, link to gitub. For local dev use local link
project["sources"][companion_name] = if haskey(ENV, "GITHUB_ACTIONS")
    Dict(
        "url" => "https://github.com/hexaeder/OpPoDyn_FNESA_2025",
        "rev" => ENV["GITHUB_SHA"]
    )
else
    Dict("path" => "..",)
end

# Save Project.toml for the notebook
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

# Move full version for testing
if isfile(joinpath(NBDIR, "workshop_full.ipynb"))
    @info "Replace notebook/workshop_full.ipynb with new version"
    rm(joinpath(NBDIR, "workshop_full.ipynb"))
else
    @info "Create notebook/workshop_full.ipynb"
end
mv(joinpath(TMPDIR, "workshop_full.ipynb"), joinpath(NBDIR, "workshop_full.ipynb"))

@info "Generated notebook files in notebook/ directory"
