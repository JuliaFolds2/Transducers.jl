#!/bin/bash
# -*- mode: julia -*-
#=
JULIA="${JULIA:-julia --color=yes --startup-file=no}"
export JULIA_PROJECT="$(dirname ${BASH_SOURCE[0]})"

set -ex
${JULIA} -e 'using Pkg; Pkg.instantiate()'

export JULIA_LOAD_PATH="@"
exec ${JULIA} "${BASH_SOURCE[0]}" "$@"
=#

# if build process is getting stuck, it's probably because docs code that's running
# enable this to see what it's trying to run
#ENV["JULIA_DEBUG"] = "Documenter"

import BangBang
import JSON
import Literate
import LiterateTest
import LoadAllPackages
import OnlineStats
import Random
using Documenter
using Transducers
using CompositionsBase: CompositionsBase, ⨟

EXAMPLE_PAGES = [
    "Tutorial: Missing values" => "tutorials/tutorial_missings.md",
    "Tutorial: Parallelism" => "tutorials/tutorial_parallel.md",
    "Parallel word count" => "tutorials/words.md",
    "Empty result handling" => "howto/empty_result_handling.md",
    "Writing transducers" => "howto/transducers.md",
    "Writing reducibles" => "howto/reducibles.md",
    "Useful patterns" => "howto/useful_patterns.md",
]

LoadAllPackages.loadall(joinpath((@__DIR__), "Project.toml"))

function transducers_literate(;
    inputbase = joinpath(@__DIR__, "..", "examples"),
    outputbase = joinpath(@__DIR__, "src"),
    examples = EXAMPLE_PAGES,
    kwargs...,
)
    for (_, outpath) in examples
        name, = splitext(basename(outpath))
        inputfile = joinpath(inputbase, "$name.jl")
        outputdir = joinpath(outputbase, dirname(outpath))
        if name == "words"
            config = Dict()
        else
            config = LiterateTest.config()
        end
        Literate.markdown(
            inputfile,
            outputdir;
            config = config,
            flavor = Literate.DocumenterFlavor(),
            kwargs...,
        )
    end
end

# if we don't do this can wind up with stale files and bad things can happen
function transducers_rm_literate()
    dir = joinpath(@__DIR__,"src")
    for d ∈ joinpath.((dir,), ("howto", "tutorials"))
        if isdir(d)
            @info("removing stale directory $d")
            rm(d, recursive=true, force=true)
        end
    end
end

function transducers_rm_duplicated_docs()
    shareddocs =
        Docs.Binding.(Ref(Transducers), [:whenstart, :whencomplete, :whencombine]) .=>
            Ref(Docs.Binding(Transducers, :wheninit))
    for (dup, canonical) in shareddocs
        @info "Simplifying docstring: $dup => $canonical"
        pop!(Docs.meta(dup.mod), dup, nothing)
        canstr = only(values(Docs.meta(canonical.mod)[canonical].docs))
        txt = "See [`$(canonical.var)`](@ref $canonical)"
        @eval dup.mod $Docs.@doc $txt $(dup.var)
    end
end

function transducers_redirection_mapping()
    mapping = [
        # old page => new page
        "manual" => "reference/manual",
        "interface" => "reference/interface",
    ]

    old_examples = [
        "tutorials/tutorial_missings",
        "tutorials/tutorial_parallel",
        "tutorials/words",
        "howto/empty_result_handling",
        "howto/transducers",
        "howto/reducibles",
    ]

    for e in old_examples
        push!(mapping, joinpath("examples", basename(e)) => e)
    end

    return mapping
end

function transducers_make_redirections(;
    mapping = transducers_redirection_mapping(),
    build = joinpath((@__DIR__), "build"),
)
    for (old, new) in mapping
        oldpath = joinpath(build, old)
        newpath = joinpath(build, new)
        relurl = relpath(newpath, oldpath)
        html = """<meta http-equiv="refresh" content="0; url=$relurl"/>"""
        mkpath(oldpath)
        write(joinpath(oldpath, "index.html"), html)
    end
end

function should_push_preview(event_path = get(ENV, "GITHUB_EVENT_PATH", nothing))
    event_path === nothing && return false
    event = JSON.parsefile(event_path)
    pull_request = get(event, "pull_request", nothing)
    pull_request === nothing && return false
    labels = [x["name"] for x in pull_request["labels"]]
    # https://developer.github.com/v3/activity/events/types/#pullrequestevent
    yes = "push_preview" in labels
    if yes
        @info "Trying to push preview as label `push_preview` is specified." labels
    else
        @info "Not pushing preview as label `push_preview` is not specified." labels
    end
    return yes
end

Random.seed!(1234)
transducers_rm_literate()
transducers_rm_duplicated_docs()
transducers_literate()

examples = EXAMPLE_PAGES
doctest = get(ENV, "CI", "false") == "true"
doctest = true

tutorials = filter(((_, path),) -> startswith(path, "tutorials/"), examples)
howto = filter(((_, path),) -> startswith(path, "howto/"), examples)
# @assert issetequal(union(tutorials, howto), examples)

# tutorial_paths = map(tutorials) do (_, outpath)
#     inputbase = joinpath(@__DIR__, "..", "examples")
#     name, = splitext(basename(outpath))
#     joinpath(inputbase, "$name.md")
# end
# howto_paths = map(howto) do (_, outpath)
#     inputbase = joinpath(@__DIR__, "..", "examples")
#     name, = splitext(basename(outpath))
#     joinpath(inputbase, "$name.md")
# end

@info "`makedocs` with" doctest
makedocs(;
    modules = [Transducers, CompositionsBase],
    pages = [
        "Home" => "index.md",
        "Reference" =>
            ["Manual" => "reference/manual.md", "Interface" => "reference/interface.md"],
        "Tutorials" => tutorials,
        "How-to guides" => howto,
        "Explanation" => [
            "Parallelism" => "parallelism.md",  # TODO: merge this to index.md
            "Comparison to iterators" => "explanation/comparison_to_iterators.md",
            "Glossary" => "explanation/glossary.md",
            "State machines" => "explanation/state_machines.md",
            "Internals" => "explanation/internals.md",
        ],
    ],
    checkdocs=:none,
    #repo = "https://github.com/JuliaFolds2/Transducers.jl/blob/{commit}{path}#L{line}",
    sitename = "Transducers.jl",
    authors = "Takafumi Arakaki",
    doctest = doctest,
)

transducers_make_redirections()
deploydocs(;
    repo = "github.com/JuliaFolds2/Transducers.jl",
    push_preview = should_push_preview(),
)
