args_verbosity = [
    ["--verbosity"],
    Dict(
        :help => "how verbose to be, greater results in more messages",
        :arg_type => Int64
    ),
]

args_rng = [
    ["--random-state"],
    Dict(
        :help => "seed for random number generator",
        # scikit-learn requires a 32-bit integer here, but Julia can handle a 64-bit integer
        :arg_type => UInt64
    ),
]

args_search = [
    ["--max-time"],
    Dict(
        :help => "maximum time in seconds",
        :arg_type => Int64,
    ),
    # TODO: "stop_deadline": [dt.datetime, None],
    ["--num-islands"],
    Dict(
        :help => "number of simultaneous islands per exploded specification",
        :arg_type => Int64,
    ),
    ["--max-generations"],
    Dict(
        :help => "maximum number of generations to run on each island",
        :arg_type => Int64,
    ),
    ["--stop-threshold"],
    Dict(
        :help => "stop after finding an agent with a rating at least this good",
        :arg_type => Float64
    ),
    ["--simplify"],
    Dict(
        :help => "whether to run a simplification epoch",
    ),
]

args_genome_spec = [
    ["--output-size"],
    Dict(
        :help => "genome output size",
        :arg_type => Int64
    ),
    ["--scratch-size"],
    Dict(
        :help => "genome scratch size",
        :arg_type => Int64
    ),
    ["--parameter-size"],
    Dict(
        :help => "genome parameter size",
        :arg_type => Int
    ),
    ["--num-time-steps"],
    Dict(
        :help => "number of genome time steps",
        :arg_type => Int64
    ),
]

args_mutation_spec = [
    ["--op-inventory"],
    Dict(
        :help => "operation inventory",
        :arg_type => String
    ),
    ["--p-mutate-op"],
    Dict(
        :help => "probability that an operation mutates",
        :arg_type => Float64,
    ),
    ["--p-mutate-index"],
    Dict(
        :help => "probability that an operand index mutates",
        :arg_type => Float64,
    ),
    ["--p-duplicate-index"],
    Dict(
        :help => "probability that an operand index is duplicated",
        :arg_type => Float64,
    ),
    ["--p-delete-index"],
    Dict(
        :help => "probability that an operand index is deleted",
        :arg_type => Float64,
    ),
    ["--p-duplicate-instruction"],
    Dict(
        :help => "probability that a whole instruction is duplicated",
        :arg_type => Float64,
    ),
    ["--p-delete-instruction"],
    Dict(
        :help => "probability that a whole instruction is deleted",
        :arg_type => Float64,
    ),
    ["--p-hop-instruction"],
    Dict(
        :help => "probability that an instruction hops to another block",
        :arg_type => Float64,
    ),
]

args_selection_spec = [
    ["--num-to-keep"],
    Dict(
        :help => "how many genomes to keep from one generation to the next (elitism)",
        :arg_type => Int64
    ),
    ["--num-to-generate"],
    Dict(
        :help => "how many genomes to generate for next generation",
        :arg_type => Int64
    ),
    ["--p-take-better"],
    Dict(
        :help => "probability that in a tournament, the better-rated genome is chosen as a parent",
        :arg_type => Float64,
    ),
    ["--p-take-very-best"],
    Dict(
        :help => "probability that in a tournament, the best-rated genome in the current population is chosen as a parent",
        :arg_type => Float64
    ),
]

args_regularization = [
    ["--lambda-b"],
    Dict(
        :help => "weight given to L2 norm of linear coefficients (ridge regression, Tikhonov regularization)",
        :arg_type => Float64
    ),
    ["--lambda-p"],
    Dict(
        :help => "weight given to L2 norm of nonlinear model constants",
        :arg_type => Float64
    ),
    ["--lambda-op"],
    Dict(
        :help => "weight given to total number of operands in genome",
        :arg_type => Float64
    ),
]


args_jessamine = [
    args_verbosity;
    args_search;
    args_genome_spec;
    args_mutation_spec;
    args_selection_spec;
    args_regularization
]
