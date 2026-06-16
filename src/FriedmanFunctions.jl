@doc raw"""
Generate data from Friedman functions, which are commonly used for machine learning benchmarks.

In Friedman's original article,
[`friedman1`](@ref) is (61),
[`friedman2`](@ref) is (63a), and
[`friedman3`](@ref) is (63b).

Breiman, Leo. Bagging Predictors. *Machine Learning,* v24 no2 p123--140, 1996-08-01.
[doi:10.1007/BF00058655](http://doi.org/10.1007/BF00058655)

Friedman, Jerome H. Multivariate adaptive regression splines. *The Annals of Statistics* v19 no1 p1--67, 1991.
[JStor](https://www.jstor.org/stable/2241837)

To run this CLI app manually:

    julia --project=@. -m JessamineBenchmark.FriedmanFunctions
"""
module FriedmanFunctions

using ArgParse
using CSV
using DataFrames
using Distributions
using JessamineSciKitLearn: @cfield
using Pkg
using Random
using TOML

export friedman1, friedman2, friedman3
export make_rand_friedman1, make_rand_friedman2, make_rand_friedman3

include("Utils.jl")

@doc raw"""
    friedman1(x1, x2, x3, x4, x5)

Return ``10 \sin(π x_1 x_2) + 20 (x_3 - 1/2)^2 + 10 x_4 + 5 x_5``.
"""
function friedman1(x1, x2, x3, x4, x5)
    return 10*sin(π*x1*x2) + 20*(x3 - 1/2)^2 + 10*x4 + 5*x5
end


@doc raw"""
    friedman2(x1, x2, x3, x4)

Return ``\sqrt{x_1^2 + \left(x_2 x_3 - \frac{1}{x_2 x4}\right)}``.
"""
function friedman2(x1, x2, x3, x4)
    return sqrt(x1^2 + (x2*x3 - 1/(x2*x4)))
end


@doc raw"""
    friedman3(x1, x2, x3, x4)

Return ``\atan \left(\frac{x_2 x_3 - 1/(x_2 x_4)}{x_1}\right)``.
"""
function friedman3(x1, x2, x3, x4)
    return atan(x2*x3 - 1/(x2*x4), x1)
end

@doc raw"""

     make_rand_friedman1(kwargs...)

Make random samples of the inputs ``x_1, \dots, x_5`` as columns and apply [`friedman1`](@ref) to the result.
Make additional random samples as columns to use as distractors.

# Keywords
- `rng=Random.default_rng()`: Random number generator to use.
- `num_samples=100`: How many points (rows) to create.
- `num_distractors=0`: How many distractor columns to create.
- `input_dist=Uniform()`: Distribution of inputs and distractors.
- `noise_dist=Dirac(0)`: Distribution of noise; default means no noise.

# Returns
A `DataFrame` with the following columns:

- `y`: result of applying [`friedman1`](@ref) to inputs `x1`, ..., `x5`, plus noise.
- `x1`, ..., `x5`: the five inputs
- `x6`, ... : distractors

"""
function make_rand_friedman1(;rng=Random.default_rng(), num_samples=100, num_distractors=0, input_dist=Uniform(), noise_dist=Dirac(0))
    xs = [rand(rng, input_dist, num_samples) for _ in 1:5]
    distractors = [rand(rng, input_dist, num_samples) for _ in 1:num_distractors]
    noise = rand(rng, noise_dist, num_samples)
    y = friedman1.(xs...) + noise
    x_names = ["x$j" for j in 1:5]
    distractor_names = ["x$j" for j in 6:6+num_distractors]

    result = DataFrame(
        "y" => y,
        zippairs(x_names, xs)...,
        zippairs(distractor_names, distractors)...)

    return result
end


@doc raw"""
    make_rand_friedman2(kwargs...)

Make random samples of the inputs ``x_1, \dots, x_5`` as columns and apply [`friedman2`](@ref) to the result.
Make additional random samples as columns to use as distractors.

# Keywords
- `rng=Random.default_rng()`: Random number generator to use.
- `num_samples=100`: How many points (rows) to create.
- `x1_dist=Uniform(0, 100)`: Distribution for `x1`.
- `x2_dist=Uniform(2*π*40, 2*π*280)`: Distribution for `x2`.
- `x3_dist=Uniform(0, 1)`: Distribution for `x3`
- `x4_dist=Uniform(1, 11)`: Distribution for `x4`.
- `noise_dist=Dirac(0)`: Distribution of noise; default means no noise.

# Returns
A `DataFrame` with the following columns:

- `y`: result of applying [`friedman2`](@ref) to inputs `x1`, ..., `x4`, plus noise.
- `x1`, ..., `x4`: the four inputs
"""
function make_rand_friedman2(
    ;rng=Random.default_rng(),
    num_samples=100,
    x1_dist=Uniform(0, 100),
    x2_dist=Uniform(2*π*40, 2*π*280),
    x3_dist=Uniform(0, 1),
    x4_dist=Uniform(1, 11),
    noise_dist=Dirac(0))

    x1 = rand(rng, x1_dist, num_samples)
    x2 = rand(rng, x2_dist, num_samples)
    x3 = rand(rng, x3_dist, num_samples)
    x4 = rand(rng, x4_dist, num_samples)
    noise = rand(rng, noise_dist, num_samples)

    y = friedman2.(x1, x2, x3, x4) + noise

    x_names = ["x$j" for j in 1:4]

    return DataFrame(
        "y" => y,
        zippairs(x_names, [x1, x2, x3, x4])...
    )
end


@doc raw"""
    make_rand_friedman3(kwargs...)

Make random samples of the inputs ``x_1, \dots, x_5`` as columns and apply [`friedman3`](@ref) to the result.
Make additional random samples as columns to use as distractors.

# Keywords
- `rng=Random.default_rng()`: Random number generator to use.
- `num_samples=100`: How many points (rows) to create.
- `x1_dist=Uniform(0, 100)`: Distribution for `x1`.
- `x2_dist=Uniform(2*π*40, 2*π*280)`: Distribution for `x2`.
- `x3_dist=Uniform(0, 1)`: Distribution for `x3`
- `x4_dist=Uniform(1, 11)`: Distribution for `x4`.
- `noise_dist=Dirac(0)`: Distribution of noise; default means no noise.

# Returns
A `DataFrame` with the following columns:

- `y`: result of applying [`friedman3`](@ref) to inputs `x1`, ..., `x4`, plus noise.
- `x1`, ..., `x4`: the four inputs
"""
function make_rand_friedman3(
    ;rng=Random.default_rng(),
    num_samples=100,
    x1_dist=Uniform(0, 100),
    x2_dist=Uniform(2*π*40, 2*π*280),
    x3_dist=Uniform(0, 1),
    x4_dist=Uniform(1, 11),
    noise_dist=Dirac(0))

    x1 = rand(rng, x1_dist, num_samples)
    x2 = rand(rng, x2_dist, num_samples)
    x3 = rand(rng, x3_dist, num_samples)
    x4 = rand(rng, x4_dist, num_samples)
    noise = rand(rng, noise_dist, num_samples)

    y = friedman3.(x1, x2, x3, x4) + noise

    x_names = ["x$j" for j in 1:4]

    return DataFrame(
        "y" => y,
        zippairs(x_names, [x1, x2, x3, x4])...
    )
end


### Utilities

### Application interface

# autofix_names = true: Means an option like --random-state
# results in a dictionary item with key "random_state".
s = ArgParseSettings(
    autofix_names = true,
    add_version = true,
    version = string(Pkg.project().version))

args_config_file = [
    ["--config-file"],
    Dict(
        :help => "read configuration from a TOML file; can be repeated",
        :arg_type => String,
        :action => :append_arg
    ),
]

args_output = [
    ["output-file"],
    Dict(
        :help => "output file path",
        :required => true,
        :arg_type => String
    ),
    ["--config-dump-file"],
    Dict(
        :help => "save the overall argument configuration to a TOML file",
        :arg_type => String
    ),
]

args_generate_general = [
    ["--num-samples"],
    Dict(
        :help => "how many sample points (rows) to generate",
        :arg_type => Int64,
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

all_args = [args_config_file..., args_output..., args_generate_general...]

add_arg_table!(
    s,
    ["f1"],
    Dict(
        :help => "generate samples for Friedman #1",
        :action => :command
    )
)

add_arg_table!(
    s["f1"],
    all_args...,
    ["--num-distractors"],
    Dict(
        :help => "number of distractor columns to generate",
        :arg_type => Int64
    )
)

add_arg_table!(
    s,
    ["f2"],
    Dict(
        :help => "generate samples for Friedman #2",
        :action => :command
    )
)

add_arg_table!(s["f2"], all_args...)

add_arg_table!(
    s,
    ["f3"],
    Dict(
        :help => "generate samples for Friedman #3",
        :action => :command
    )
)

add_arg_table!(s["f3"], all_args...)

function cmd_f1 end
function cmd_f2 end
function cmd_f3 end

command_table = Dict(
"f1" => cmd_f1,
"f2" => cmd_f2,
"f3" => cmd_f3
)

function (@main)(args = ARGS)
    args_result = parse_args(args, s)
    command = args_result["%COMMAND%"]
    prespec_original = args_result[command]

    # Get rid of any nothings, they just cause trouble.
    prespec = filter(p -> !isnothing(p.second), prespec_original)

    # Load config files
    if haskey(prespec, "config_file")
        config_files = prespec["config_file"]
        for config_file in config_files
            cf = TOML.parsefile(config_file)
            # Merge so that args on the command line supersede
            # what's in a file.
            prespec = merge(cf, prespec)
        end
    end

    # Maybe store configuration
    dump_file = get(prespec, "config_dump_file", nothing)
    if !isnothing(dump_file)
        # It doesn't make sense to include the config_dump_file
        # key in the dump file, or the config_file array, so take them out.
        prespec_fixed = copy(prespec)
        delete!(prespec_fixed, "config_dump_file")
        delete!(prespec_fixed, "config_file")
        mkpath_and_open(dump_file, "w") do io
            TOML.print(io, prespec_fixed, sorted=true)
        end
    end

    @cfield prespec random_state 0xff1c9d3eb102d045
    Random.seed!(random_state)

    # Run main command
    command_table[command](prespec)
end

function cmd_f1(prespec)
    @cfield prespec num_samples 100
    @cfield prespec noise_std nothing Union{Nothing,Float64}
    @cfield prespec num_distractors 0
    output_file = prespec["output_file"]

    if isnothing(noise_std)
        noise_dist = Dirac(0.0)
    else
        noise_dist = Normal(0.0, noise_std)
    end

    df = make_rand_friedman1(;num_samples, num_distractors, noise_dist)

    mkpath_and_open(output_file, "w") do io
        CSV.write(io, df)
    end

    return 0
end

function cmd_f2(prespec)
    @cfield prespec num_samples 100
    @cfield prespec noise_std nothing Union{Nothing,Float64}
    output_file = prespec["output_file"]

    if isnothing(noise_std)
        noise_dist = Dirac(0.0)
    else
        noise_dist = Normal(0.0, noise_std)
    end

    df = make_rand_friedman2(;num_samples, noise_dist)

    mkpath_and_open(output_file, "w") do io
        CSV.write(io, df)
    end

    return 0
end


function cmd_f3(prespec)
    @cfield prespec num_samples 100
    @cfield prespec noise_std nothing Union{Nothing,Float64}
    output_file = prespec["output_file"]

    if isnothing(noise_std)
        noise_dist = Dirac(0.0)
    else
        noise_dist = Normal(0.0, noise_std)
    end

    df = make_rand_friedman3(;num_samples, noise_dist)

    mkpath_and_open(output_file, "w") do io
        CSV.write(io, df)
    end

    return 0
end


end # module
