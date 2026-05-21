# To run this CLI app manually:
# julia --project=@. -m JessamineBenchmnark.AppSimple

module AppSimple

using ArgParse
using CSV
using DataFrames

using JessamineSciKitLearn

s = ArgParseSettings()

@add_arg_table! s begin
    ["--rng-seed"],
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
    end
end

function (@main)(args = ARGS)
    parsed_args = parse_args(args, s)
    data_file = parsed_args["data-file"]
    df = load_data_file(data_file)
    @show df
    return 0
end

function load_data_file(path)
    # Choose a delimiter based on the file name
    if occursin(".tsv", path)
        return CSV.read(path, DataFrame, delim = '\t')
    elseif occursin(".csv", path)
        return CSV.read(path, DataFrame, delim = ',')
    else
        return CSV.read(path, DataFrame)
    end
end


end
