using Documenter

using JessamineBenchmark
using JessamineBenchmark.SinFunction
using JessamineBenchmark.FriedmanFunctions

DocMeta.setdocmeta!(JessamineBenchmark, :DocTestSetup, :(using JessamineBenchmark); recursive=true)

makedocs(;
    modules=[
        JessamineBenchmark,
        JessamineBenchmark.SinFunction,
        JessamineBenchmark.FriedmanFunctions
    ],
    authors="W. G. Mitchener <mitchenerg@charleston.edu> and others",
    sitename="JessamineBenchmark.jl",
    format=Documenter.HTML(;
        canonical="https://wgm-applied-math.github.io/JessamineBenchmark.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
    checkdocs=:none,
)

# Documenter can also automatically deploy documentation to gh-pages.
# See "Hosting Documentation" and deploydocs() in the Documenter manual
# for more information.
deploydocs(
    repo = "github.com/wgm-applied-math/JessamineBenchmark.jl.git",
    devbranch = "main",
    versions = ["stable" => "v^", "v#.#", "dev" =>  "dev"] # Explicitly forces version tracking
)
