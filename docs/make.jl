using JessamineBenchmark
using Documenter

DocMeta.setdocmeta!(JessamineBenchmark, :DocTestSetup, :(using JessamineBenchmark); recursive=true)

makedocs(;
    modules=[JessamineBenchmark],
    authors="W. Garrett Mitchener <mitchenerg@charleston.edu> and others",
    sitename="JessamineBenchmark.jl",
    format=Documenter.HTML(;
        canonical="https://wgm-applied-math.github.io/JessamineBenchmark.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

# Documenter can also automatically deploy documentation to gh-pages.
# See "Hosting Documentation" and deploydocs() in the Documenter manual
# for more information.
deploydocs(;
    repo="github.com/wgm-applied-math/JessamineBenchmark.jl",
    devbranch="main",
    devurl = "dev",
    versions = ["stable" => "v^", "v#.#", "dev" =>  "dev"] # Explicitly forces version tracking
)
