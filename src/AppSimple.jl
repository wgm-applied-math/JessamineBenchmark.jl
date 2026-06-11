# To run this CLI app manually:
# julia --project=@. -m JessamineBenchmark.AppSimple

module AppSimple

using Core: DebugInfo
using ArgParse: command_actions
using ArgParse
using CSV
using DataFrames
using Dates
using JSON
using Jessamine
using JessamineSciKitLearn
using JessamineSciKitLearn: @cfield
using Logging
using Pkg
using Printf
using TOML
using Random123

include("ArgsJessamine.jl")

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

args_log_file = [
    ["--log-file"],
    Dict(
        :help => "write log messages to this file",
        :arg_type => String
    )]

sr_args_input = [
    ["--data-file", "-d"],
    Dict(
        :help => "file with data table",
        :arg_type => String
    ),
    ["--output-column"],
    Dict(
        :help => "column in data file containing model target output values",
        :arg_type => Symbol
    ),
    ["--random-subset-count"],
    Dict(
        :help => "take a random subset of this many rows of the training data",
        :arg_type => Int64
    ),
]

sr_args_output = [
    ["--output-file"],
    Dict(
        :help => "output file path",
        :arg_type => String
    ),
    ["--config-dump-file"],
    Dict(
        :help => "save the overall argument configuration to a TOML file",
        :arg_type => String
    ),
    ["--progress-file"],
    Dict(
        :help => "store each highest-rated agent in this file as it is discovered",
        :arg_type => String
    )
]

setup_args = [
    ["--config-path-template"],
    Dict(
        :help => "template for config file paths; include %d for sample number and end with .toml",
        :arg_type => String,
        :required => true
    ),
    ["--num-samples"],
    Dict(
        :help => "number of samples to run",
        :arg_type => Int,
    ),
    ["--sr-output-dir"],
    Dict(
        :help => "base directory for symbolic regression output files",
        :arg_type => String,
    )
]

add_arg_table!(
    s,
    ["sr", "symbolic_regression"],
    Dict(
        :help => "run symbolic regression on a dataset",
        :action => :command
    ),
)

add_arg_table!(
    s["sr"], args_config_file..., args_log_file..., sr_args_input..., sr_args_output..., args_rng..., args_jessamine...)


add_arg_table!(
    s,
    ["setup_samples"],
    Dict(
        :help => "set up config files for many samples",
        :action => :command
    )
)
add_arg_table!(
    s["setup_samples"], args_config_file..., args_log_file..., setup_args..., sr_args_input..., args_rng..., args_jessamine...)


function cmd_sr end
function cmd_setup_samples end

command_table = Dict(
    "sr" => cmd_sr,
    "setup_samples" => cmd_setup_samples,
)

function (@main)(args = ARGS)
    args_result = parse_args(args, s)
    command = args_result["%COMMAND%"]
    prespec_original = args_result[command]

    # Get rid of any nothings, they just cause trouble.
    prespec = filter(p -> !isnothing(p.second), prespec_original)
    verbosity = get(prespec, "verbosity", 0)

    @debug_or_info verbosity "main:" prespec=prespec

    # Load config files
    if haskey(prespec, "config_file")
        config_files = prespec["config_file"]
        for config_file in config_files
            cf = TOML.parsefile(config_file)
            @debug_or_info verbosity "Loaded $(config_file): $cf"
            # Merge so that args on the command line supersede
            # what's in a file.
            prespec = merge(cf, prespec)
            @debug_or_info verbosity "Prespec is now $prespec"
        end
        @debug_or_info verbosity "After loading config files, prespec is $prespec"
    end

    @debug_or_info verbosity "main: After loading config files:" prespec=prespec

    # Maybe set up a log file
    @cfield prespec log_file nothing Union{Nothing,String}
    if !isnothing(log_file)
        min_level = if !isnothing(verbosity) && verbosity >= 2
            Debug
        else
            Info
        end
        io = mkpath_and_open(log_file, "w+")
        logger = SimpleLogger(io, min_level)
        #original_logger = global_logger()
        global_logger(logger)
    end

    # Run main command
    command_table[command](prespec)
end

"""
    cmd_sr(prespec)

Run symbolic regression.
"""
function cmd_sr(prespec)
    verbosity = get(prespec, "verbosity", 0)

    @debug_or_info verbosity "Running symbolic regression"

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
    @cfield prespec output_column "label"
    y = df[!, output_column]
    X = df[!, Not(output_column)]

    # Feed it to JessamineSciKitLearn

    result = regression_main_detailed(X, y, prespec; verbosity)

    output_file = get(prespec, "output_file", nothing)
    if !isnothing(output_file)
        @debug "Writing to $output_file"
        mkpath(dirname(output_file))
        JSON.json(output_file, result)
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



function cmd_setup_samples(prespec)
    verbosity = get(prespec, "verbosity", 0)
    @debug_or_info verbosity "Setting up config files for many samples"

    delete!(prespec, "config_file")

    @cfield prespec random_state nothing Union{Nothing,UInt64}
    master_rng = if isnothing(random_state)
        Random123.Philox2x()
    else
        random_state_str = @sprintf "0x%x" random_state
        @debug "regression_main: Random state seeded with $random_state_str"
        Random123.Philox2x(random_state)
    end

    @cfield prespec config_path_template "config-%03d.toml"
    delete!(prespec, "config_path_template")
    config_path_format = Printf.Format(config_path_template)

    @cfield prespec num_samples 4
    delete!(prespec, "num_samples")

    data_file = get(prespec, "data_file", nothing)
    if isnothing(data_file)
        error("No data file specified")
    end
    dataset_file = basename(data_file)
    dataset, _ext = splitext(dataset_file)

    @cfield prespec sr_output_dir "Generated"
    mkpath(joinpath(sr_output_dir, dataset))
    delete!(prespec, "sr_output_dir")

    subseeds = rand(master_rng, UInt64, num_samples)

    n_digits = 1 + max(2, ceil(Int64, log10(num_samples)))

    for j in 1:num_samples
        subseed = subseeds[j]
        config_path = Printf.format(config_path_format, j)
        output_dir = joinpath(sr_output_dir, dataset, @sprintf("%0*d", n_digits, j))
        prespec_sr_j = Dict(
            "random_state" => subseed,
            "output_file" => joinpath(output_dir, "result.json"),
            "progress_file" => joinpath(output_dir, "progress.json"),
            "log_file" => joinpath(output_dir, "log.txt"),
        )
        prespec_j = merge(prespec, prespec_sr_j)
        mkpath_and_open(config_path, "w") do io
            TOML.print(io, prespec_j, sorted=true)
        end
    end

    return 0
end

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


end
