@doc raw"""
Generate data from Friedman functions, which are commonly used for machine learning benchmarks.

Breiman, Leo. Bagging Predictors. *Machine Learning*, v. 24 no. 2, pp. 123--140. 1996-08-01.
[doi:10.1007/BF00058655](http://doi.org/10.1007/BF00058655)
"""
module FriedmanFunctions

using DataFrames
using Distributions
using Random

export friedman1, friedman2, friedman3
export make_rand_friedman1, make_rand_friedman2, make_rand_friedman3

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
- `n_points=100`: How many points (rows) to create.
- `n_distractors=0`: How many distractor columns to create.
- `input_dist=Uniform()`: Distribution of inputs and distractors.
- `noise_dist=Dirac(0)`: Distribution of noise; default means no noise.

# Returns
A `DataFrame` with the following columns:

- `y`: result of applying [`friedman1`](@ref) to inputs `x1`, ..., `x5`, plus noise.
- `x1`, ..., `x5`: the five inputs
- `x6`, ... : distractors

"""
function make_rand_friedman1(;rng=Random.default_rng(), n_points=100, n_distractors=0, input_dist=Uniform(), noise_dist=Dirac(0))
    xs = [rand(rng, input_dist, n_points) for _ in 1:5]
    distractors = [rand(rng, input_dist, n_points) for _ in 1:n_distractors]
    noise = rand(rng, noise_dist, n_points)
    y = friedman1.(xs...) + noise
    x_names = ["x$j" for j in 1:5]
    distractor_names = ["x$j" for j in 6:6+n_distractors]

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
- `n_points=100`: How many points (rows) to create.
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
    n_points=100,
    x1_dist=Uniform(0, 100),
    x2_dist=Uniform(2*π*40, 2*π*280),
    x3_dist=Uniform(0, 1),
    x4_dist=Uniform(1, 11),
    noise_dist=Dirac(0))

    x1 = rand(rng, x1_dist, n_points)
    x2 = rand(rng, x2_dist, n_points)
    x3 = rand(rng, x3_dist, n_points)
    x4 = rand(rng, x4_dist, n_points)
    noise = rand(rng, noise_dist, n_points)

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
- `n_points=100`: How many points (rows) to create.
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
    n_points=100,
    x1_dist=Uniform(0, 100),
    x2_dist=Uniform(2*π*40, 2*π*280),
    x3_dist=Uniform(0, 1),
    x4_dist=Uniform(1, 11),
    noise_dist=Dirac(0))

    x1 = rand(rng, x1_dist, n_points)
    x2 = rand(rng, x2_dist, n_points)
    x3 = rand(rng, x3_dist, n_points)
    x4 = rand(rng, x4_dist, n_points)
    noise = rand(rng, noise_dist, n_points)

    y = friedman3.(x1, x2, x3, x4) + noise

    x_names = ["x$j" for j in 1:4]

    return DataFrame(
        "y" => y,
        zippairs(x_names, [x1, x2, x3, x4])...
    )
end


### Utilities

@doc raw"""
    zippairs(a, b)

Return an iterator that produces `[a[1] => b[1], a[2] => b[2], ...]`
"""
function zippairs(a, b)
    map(p -> (p[1] => p[2]), zip(a, b))
end


end # module
