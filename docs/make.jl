using GitHubActions
using Documenter

makedocs(;
    modules=[GitHubActions],
    authors="Chris de Graaf <me@cdg.dev> and contributors",
    repo="https://github.com/julia-actions/GitHubActions.jl/blob/{commit}{path}#L{line}",
    sitename="GitHubActions.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://julia-actions.github.io/GitHubActions.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/julia-actions/GitHubActions.jl",
)
