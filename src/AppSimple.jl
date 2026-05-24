# To run this CLI app manually:
# julia --project=@. -m JessamineBenchmark.AppSimple

module AppSimple

using ArgParse
using CSV
using DataFrames
using Dates
using JSON
using JessamineSciKitLearn
using JessamineSciKitLearn: @cfield

include("ArgsJessamine.jl")

# autofix_names = true: Means an option like --random-state
# results in a dictionary item with key "random_state".
s = ArgParseSettings(autofix_names = true, add_version = true)

args_overall = [
    ["--random-state"],
    Dict(
        :help => "seed for random number generator",
        :arg_type => UInt64,
        :default => 0x677e87db530bd280
    ),
    ["--data-file", "-d"],
    Dict(
        :help => "file with data table",
        :arg_type => String,
        :required => true
    ),
    ["--max-time"],
    Dict(
	:help => "maximum time in seconds",
        :arg_type => Int,
        :default => nothing
    ),
]

args_output = [
    ["--output-file", "-o"],
    Dict(
	:help => "output file path",
        :arg_type => String
    )
]

add_arg_table!(s, args_overall..., args_output..., args_jessamine...)

function (@main)(args = ARGS)
    prespec = parse_args(args, s)

    # Set time limit
    @cfield prespec max_time 30
    stop_deadline = now() + Dates.Second(max_time)
    prespec["stop_deadline"] = stop_deadline

    # Load the data file
    data_file = prespec["data_file"]
    df = load_data_file(data_file)

    # Extract the input and output columns
    output_column = :label
    y = df[!, output_column]
    X = df[!, Not(output_column)]

    # Feed it to JessamineSciKitLearn

    result = regression_main_detailed(X, y, prespec)

    @info "Result is $result"

    short_result = (
        best_agent = result.best_agent,
        genome_spec = result.genome_spec,
        y_num_str = result.y_num_str)

    output_file = get(prespec, "output_file", nothing)
    if !isnothing(output_file)
        @info "Writing to $output_file"
        JSON.json(output_file, short_result)
    end

    return 0
end

function load_data_file(path)
    # Choose a delimiter based on the file name
    if occursin(".tsv", path)
        return CSV.read(path, DataFrame, delim = '\t')
    elseif occursin(".csv", path)
        return CSV.read(path, DataFrame, delim = ',')
    else
        # Choose automatically
        return CSV.read(path, DataFrame)
    end
end


end
