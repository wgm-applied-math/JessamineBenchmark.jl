"""
This script initialized the Julia package here.  It's not
needed now that I've run it and developed the code further.
"""
module GetStarted

using PkgTemplates

t = Template(
    user = "wgmitchener",
    authors = ["W. Garrett Mitchener <mitchenerg@charleston.edu> and others"],
    dir = ".",
    julia = v"1.12.6",
    plugins = [
        License(
            name = "GPL-3.0-or-later",
        ),
        Git(
            name = "W. Garrett Mitchener",
            email = "mitchenerg@charleston.edu",
            ssh = true,
            jl = true
        ),
        Documenter{GitHubActions}(
        #user = "wgmitchener",
        ),
        Formatter(
            style = "sciml",
        )
    ]
)

function (@main)(args = ARGS)
    t("JessamineBenchmark.jl")
end

end
