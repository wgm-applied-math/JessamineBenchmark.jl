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

deploydocs(;
    repo="github.com/wgm-applied-math/JessamineBenchmark.jl",
    devbranch="main",
)
