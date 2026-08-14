@doc raw"""
Generate data from sin

To run this CLI app manually:

    julia --project=@. -m JessamineBenchmark.SinFunction
"""
module SinFunction

using ArgParse
using CSV
using DataFrames
using Distributions
using JessamineCLI
using JessamineCLI: @cfield
using Pkg
using Random
using TOML

export make_rand_sin

@doc raw"""

     make_rand_sin(kwargs...)

Make random samples of the input ``x`` as columns and apply `sin` to the result.
Make additional random samples as columns to use as distractors.

# Keywords
- `rng=Random.default_rng()`: Random number generator to use.
- `num_samples=100`: How many points (rows) to create.
- `input_dist=Uniform(-pi, pi)`: Distribution of inputs.
- `noise_dist=Dirac(0)`: Distribution of noise; default means no noise.

# Returns
A `DataFrame` with the following columns:

- `y`: result of applying `sin` to input `x` plus noise.
- `x`: input
"""
function make_rand_sin(;rng=Random.default_rng(), num_samples=100, num_distractors=0, input_dist=Uniform(-pi, pi), noise_dist=Dirac(0))
    x = rand(rng, input_dist, num_samples)
    noise = rand(rng, noise_dist, num_samples)
    y = sin.(x) + noise

    result = DataFrame(
        "y" => y,
        "x" => x
    )

    return result
end

### Utilities

### Application interface

# autofix_names = true: Means an option like --random-state
# results in a dictionary item with key "random_state".
s = ArgParseSettings(
    autofix_names = true,
    add_version = true,
    version = string(Pkg.project().version))

args_output = [
    ["output-file"],
    Dict(
        :help => "output file path",
        :required => true,
        :arg_type => String
    ),
]

args_generate_general = [
    ["--num-samples"],
    Dict(
        :help => "how many sample points (rows) to generate",
        :arg_type => Int64,
    ),
    ["--x-min"],
    Dict(
        :help => "minimum value of x",
        :arg_type => Float64
    ),
    ["--x-max"],
    Dict(
        :help => "maximum value of x",
        :arg_type => Float64
    ),
    ["--noise-std"],
    Dict(
        :help => "add noise to the y column, using a normal distribution with mean 0 and this standard deviation",
        :arg_type => Float64
    ),
    ["--random-state"],
    Dict(
        :help => "seed for random number generator",
        :arg_type => UInt64
    ),
]

all_args = [args_output..., args_generate_general...]

add_arg_table!(s, all_args...)

function (@main)(args = ARGS)
    prespec_original = parse_args(args, s)

    # Get rid of any nothings, they just cause trouble.
    prespec = filter(p -> !isnothing(p.second), prespec_original)

    @cfield prespec random_state 0x7f1717437f0ecf12
    Random.seed!(random_state)
    @cfield prespec num_samples 100
    @cfield prespec noise_std nothing Union{Nothing,Float64}
    output_file = prespec["output_file"]
    @cfield prespec x_min -π Float64
    @cfield prespec x_max π Float64
    if isnothing(noise_std)
        noise_dist = Dirac(0.0)
    else
        noise_dist = Normal(0.0, noise_std)
    end
    input_dist = Uniform(x_min, x_max)

    df = make_rand_sin(; input_dist, num_samples, noise_dist)

    mkpath_and_open(output_file, "w") do io
        CSV.write(io, df)
    end

    return 0
end

end # module
