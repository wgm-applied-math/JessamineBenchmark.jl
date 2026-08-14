using Pkg
Pkg.develop(PackageSpec(url="https://github.com/wgm-applied-math/Jessamine.jl.git"))
Pkg.develop(PackageSpec(url="https://github.com/wgm-applied-math/JessamineSymbolics.jl.git"))
Pkg.develop(PackageSpec(path=pwd()))
Pkg.instantiate()
