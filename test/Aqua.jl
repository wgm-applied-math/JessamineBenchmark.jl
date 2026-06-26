using Aqua

@testset "Aqua" begin
    Aqua.test_all(
        JessamineBenchmark;
        stale_deps=(ignore=[:Revise],),
        deps_compat=(ignore=[:Jessamine, :JessamineSymbolics, :JessamineCLI],),
    )
end
