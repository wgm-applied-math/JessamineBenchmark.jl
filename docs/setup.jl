using Pkg
@info "Dev Jessamine.jl"
Pkg.develop(PackageSpec(url="https://github.com/wgm-applied-math/Jessamine.jl.git"))
@info "Dev JessamineSymbolics.jl"
Pkg.develop(PackageSpec(url="https://github.com/wgm-applied-math/JessamineSymbolics.jl.git"))
@info "Dev JessamineCLI.jl"
Pkg.develop(PackageSpec(url="https://github.com/wgm-applied-math/JessamineCLI.jl.git"))
@info "Dev this package"
Pkg.develop(PackageSpec(path=pwd()))
@info "Instantiate"
Pkg.instantiate()
