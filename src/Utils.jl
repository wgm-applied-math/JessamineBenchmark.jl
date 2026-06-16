function mkpath_and_open(path::String, args...; kwargs...)
    d = dirname(path)
    if !isempty(d)
        mkpath(d)
    end
    return open(path, args...; kwargs...)
end

function mkpath_and_open(f::Function, path::String, args...; kwargs...)
    d = dirname(path)
    if !isempty(d)
        mkpath(d)
    end
    return open(f, path, args...; kwargs...)
end

@doc raw"""
    zippairs(a, b)

Return an iterator that produces `[a[1] => b[1], a[2] => b[2], ...]`
"""
function zippairs(a, b)
    map(p -> (p[1] => p[2]), zip(a, b))
end
