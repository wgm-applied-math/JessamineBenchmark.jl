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
using Pkg
using TOML

include("ArgsJessamine.jl")

# autofix_names = true: Means an option like --random-state
# results in a dictionary item with key "random_state".
s = ArgParseSettings(
    autofix_names = true,
    add_version = true,
    version = string(Pkg.project().version))

args_overall = [
    ["--config-file"],
    Dict(
        :help => "read configuration from a TOML file; can be repeated",
        :arg_type => String,
        :action => :append_arg
    ),
    ["--data-file", "-d"],
    Dict(
        :help => "file with data table",
        :arg_type => String,
    ),
]

args_output = [
    ["--output-file"],
    Dict(
	:help => "output file path",
        :arg_type => String
    ),
    ["--config-dump-file"],
    Dict(
        :help => "save the overall argument configuration to a TOML file",
        :arg_type => String,
    ),
]

add_arg_table!(s, args_overall..., args_output..., args_jessamine...)

function (@main)(args = ARGS)
    prespec_original = parse_args(args, s)

    # Get rid of any nothings, they just cause trouble.
    prespec = filter(p -> !isnothing(p.second), prespec_original)


    # Load config files
    if haskey(prespec, "config_file")
        config_files = prespec["config_file"]
        for config_file in config_files
            cf = TOML.parsefile(config_file)
            @info "Loaded $(config_file): $cf"
            # Merge so that args on the command line supersede
            # what's in a file.
            prespec = merge(cf, prespec)
            @info "Prespec is now $prespec"
        end
        @info "After loading config files, prespec is $prespec"
    end

    # Maybe store configuration
    dump_file = get(prespec, "config_dump_file", nothing)
    if !isnothing(dump_file)
        # It doesn't make sense to include the config_dump_file
        # key in the dump file, or the config_file array, so take them out.
        prespec_fixed = copy(prespec)
        delete!(prespec_fixed, "config_dump_file")
        delete!(prespec_fixed, "config_file")
        open(dump_file, "w") do io
            TOML.print(io, prespec_fixed)
        end
    end

    # Set time limit
    @cfield prespec max_time 30
    stop_deadline = now() + Dates.Second(max_time)
    prespec["stop_deadline"] = stop_deadline

    # Load the data file
    data_file = get(prespec, "data_file", nothing)
    if isnothing(data_file)
        error("No data file specified")
    end
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
