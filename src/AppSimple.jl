# To run this CLI app manually:
# julia --project=@. -m JessamineBenchmark.AppSimple

module AppSimple

using ArgParse
using CSV
using DataFrames

using JessamineSciKitLearn

# autofix_names = true: Means an option like --random-state
# results in a dictionary item with key "random_state".
s = ArgParseSettings(autofix_names = true)

@add_arg_table! s begin
    ["--random-state"],
    begin
	help = "seed for random number generator"
        arg_type = UInt64
        default = 0x677e87db530bd280
    end,
    ["--data-file"],
    begin
        help = "file with data table"
        arg_type = String
        required = true
    end,
    ["--op-inventory"],
    begin
	help = "operation inventory"
        arg_type = String
        default = "Polynomial"
    end

end

function (@main)(args = ARGS)
    # Load the data file
    parsed_args = parse_args(args, s)
    data_file = parsed_args["data_file"]
    df = load_data_file(data_file)

    # Extract the input and output columns
    output_column = :label
    y = df[!, output_column]
    X = df[!, Not(output_column)]

    # Feed it to JessamineSciKitLearn

    result = regression_main(X, y, parsed_args)

    @info "Result is $result"

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
