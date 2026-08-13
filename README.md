# JessamineBenchmark

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://wgmitchener.github.io/JessamineBenchmark.jl/stable/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://wgmitchener.github.io/JessamineBenchmark.jl/dev/)
[![Build Status](https://github.com/wgmitchener/JessamineBenchmark.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/wgmitchener/JessamineBenchmark.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Aqua QA](https://juliatesting.github.io/Aqua.jl/dev/assets/badge.svg)](https://github.com/JuliaTesting/Aqua.jl)

## Set up a UNIX-like environment

These programs were developed and run on Fedora Linux, versions 43 and 44, and Rocky Linux 9.
To run all of this, you will need
[bash](https://www.gnu.org/software/bash/),
[Python](http://www.python.org),
[git](https://git-scm.com/),
and
[GNU Parallel](https://www.gnu.org/software/parallel/).
Most distributions have packages available for these, and they are generally already installed on any scientific computing machine.

Some utility scripts use [rsync](https://rsync.samba.org/) but they will have to be adapted to work on other systems.
Rsync is usually installed automatically on most Linux distributions.

Some convenience scripts are written for the [nu shell](http://www.nushell.sh) but these are not necessary for running the benchmarks.
Not all Linux distributions include packages of nu; see its web site for installation instructions.

The benchmark trials are run using [Slurm](http://www.schedmd.com/).
The included scripts assume `sbatch` and `srun` are available.

## Clone this repository

Using whatever interface to GitHub you like, clone this repository.
For example,
```
git clone --recurse-submodules --depth=1 https://github.com/wgm-applied-math/JessamineBenchmark.jl.git
```

The `--depth=1` option makes a shallow clone, so that only the most recent file states are downloaded, rather than the entire history.

Some of the data files come from other repositories, which are referenced within this repository as [git submodules](https://git-scm.com/book/en/v2/Git-Tools-Submodules).
The `--recurse-submodules` option should make git fetch all of that when you clone the repository.
To fetch those files separately, run these shell commands:
```
git submodule init
git submodule update
```

## Set up Python

These benchmarks were run using Python 3.14.6.

The scripts and Jupyter notebooks under [`behcnmarks/`](benchmarks/) use several Python packages and may need more recent versions that what's installed on your system.
To set up a virtual environment with working versions of these Python packages, open a command line in this directory and run

```
python -m venv venv
source venv/bin/activate.{your shell}
pip install -r requirements.txt
```

When running the Jupyter notebooks, use the Jupyter kernel in the `venv` directory created by the above.

## Set up Julia

Install [Julia](http://www.julialang.org).
The benchmarks were run under Julia version 1.12.6.
Any later 1.12.x version should work, but 1.13 and after may include breaking changes.

Note that the `juliaup` script is the preferred way to install Julia.
Packages from Linux distributions, Conda-forge, and other sources are often outdated or have weird linkage issues.

Once Julia is installed, run the `Julia-update` script in this directory.
That will download various Jessamine packages and their dependencies and precompile everything.
Expect this to take a while.

## Run the benchmarks

Scripts to run the benchmarks are located in subdirectories of `benchmarks/`.
To run each benchmark, the general procedure is to
- ensure data files are available
- create a TOML spec file in `Specs/` for each micro-trial
- run the micro-trials using Slurm; results stored in `Generated/`
- assemble the results using Python scripts; results stored in `Generated/`
- analyze the results using Jupyter notebooks; pictures and other output stored in `Generated/`

## The `Run-all-trials` files

A `Run-all-trials` script is included in each benchmark.
It includes commands necessary to make the spec files and run the micro-trials.
Since that takes a variable amount of time and may require running the batch job multiple times, subsequent steps can't be easily automated.
The script includes comments with instructions on how to run the remaining steps once the micro-trials are finished.

_You will probably need to edit the `sbatch` commands in these files to work on your Slurm system._
The `Run-all-trials` scripts have been written with `--ntasks=512` because that's the maximum number of simultaneous single-threaded tasks allowed per job on my system's default partition (queue).
Also, my system does not impose a time limit on batch jobs.
If yours does, Slurm may terminate one these job before it can finish.
If so, re-submit the job with the same `sbatch` command until all trials have run.

Since it is often difficult to run interactive programs like Jupyter notebooks on a Slurm cluster, you may need to repeat the entire setup process on a personal workstation, then copy the results to that for analysis.
The `Fetch-results` scripts show a convenient way to use [rsync](https://rsync.samba.org/) to do this.
They will have to be adapted to your Slurm cluster.

The executable script for running Jessamine is in the module [JessamineCLI.AppSimple](https://github.com/wgm-applied-math/JessamineCLI.jl).
Its output is stored in the location specified by the TOML file, under `Generated/`.

The convention is that each collection of Jessamine hyper-parameters is a _run set_, which generally are named `SRB` or `CHT` followed by a date and time.
Each _data set_ corresponds to a CSV file in a subdirectory, and these have slightly different naming conventions in each benchmark corpus.
The file name stem is the name of the data set.
Each micro-trial has a _sample number_, and when used as part of a file name, they have leading zeros to make them easier to see on the file system.

A spec file is named according to the pattern
`Specs/{run_set}/{data_set}/{data_set}-{sample_num}.toml`
and produces output files in
`Generated/{run_set}/{data_set}/{sample_num}/`.

For example, in `benchmarks/sin/`, the spec file
`Specs/SRB-2026-06-25-1715/sin-noise-0/sin-noise-0-001.toml`
yields files in
`Generated/SRB-2026-06-25-1715/sin-noise-0/001/`.

The files of most interest are `progress.json` and `result.json`.

### `progress.json`

As a micro-trial runs, the program writes to `progress.json` when a population finds an agent with a new best rating.
The format of the file is
```typescript
{
    "agent": {
        "rating": number,
        "genome": string, // a very short representation of the geneome
        "parameter": Array<number>,
        "extra": {
             "coefficients": Array<number>, // b_1 through b_K
             "intercept": number // b_0
         }
     },
     "current_time": string,
     "start_time": string
}
```
The file `Module-Assemble-results.nu` is for the [nu shell](http://www.nushell.sh) and defines functions useful for checking in on the progress of a batch job.
It reads files of this form and displays them as a table.
For example, if the current directory is `benchmarks/sin/`, these commands will show an interactive table of all progress files under `Generated/`.
```nushell
source Module-Assemble-results.nu
assemble-progress | nice-nums | explore
```

### `progress.jld2`

This holds the same content as `progress.json` but in [JLD2 format](https://github.com/juliaio/jld2.jl), for use in Julia:
```julia
using FileIO
using Jessamine: Agent
file_path = "..." # path to progress.json
p = load(file_path)
```
Now `p` has this structure:
```julia
p::Dict{String}
r::Dict{String} = p["report"]
r["agent"]::Agent
r["start_time"]::DateTime
r["current_time"]::DateTime
```

### `result.json` and `result.jld2`

Once the JessamineCLI program has finished, it writes `result.json` and `result.jld2`.
The structure of `result.json` is as follows:
```typescript
{
    "genome_spec:" GenomeSpec
    "discoveries": Array<Discovery>
}
```
The `GenomeSpec` object is a record of hyper-parameters describing genomes:
```typescript
// GenomeSpec:
{
    "output_size": number,
    "scratch_size": number,
    "parameter_size": number,
    "input_size": number,
    "num_time_steps": number,
    "index_map": ...
}
```
Each discovery is one of the agents found by evolution, with some extra information.
```typescript
// Discovery:
{
    "agent": Agent,
    "y_num_str": string
}
```
The `y_num_str` field is a string that can be parsed by SymPy to yield an expression for the prediction function $\hat{y}$ that the agent represents.
The name of that field comes from the expression for $\hat{y}$, evaluated with _numeric_ values for the $b_k$'s and $p_l$'s substituted in, and converted from a Symbolics.jl object to a _string_ in Python notation.
Each agent has the form
```typescript
// Agent:
{
    "rating": number,
    "genome": Genome,
    "parameter": Array<number>,
    "extra": {
         "coefficients": Array<number>, // b_1 through b_K
         "intercept": number // b_0
     }
}
```
Here, the genome is given in more detail compared to `progress.json`.
```typescript
// Genome:
{
    "instruction_blocks": Array<Array<Instruction>>
}
// Instruction:
{
    "op": { "unary: UnaryOp, "multi", MultiaryOp },
    "operand_ixs": Array<number>
}
```

The discoveries are stored in order from best rating (item 0) to worst rating.
The reason for listing multiple discoveries is that sometimes a genome relies on some quirk of Julia's floating-point arithmetic that does not translate to SymPy, particularly division by 0, which in Julia yields an `Inf` object but in Python results in an exception.
Steps have been taken to minimize such problems, but they sometimes don't work.
The script `SymPyReport.py` reads `result.json` files and goes through the discoveries until one is found that SymPy can handle.

The `result.jld2` file is the same information, but in [JLD2 format](https://github.com/juliaio/jld2.jl), for use in Julia.
```julia
using FileIO
using Jessamine: Agent, GenomeSpec
file_path = "..." # path to result.json
p = load(file_path)
```
Now `p` has this structure:
```julia
p::Dict{String}
r::NamedTuple = p["result"]
r.genome_spec::GenomeSpec
r.discoveries::Vector{NamedTuple}
d = r.discoveries[1]
d.y_num_str::String
d.agent::Agent
```

The file `Module-Assemble-results.nu` includes functions for quickly summarizing `result.json` files.
For example, to see an interactive table of all result files,
```nushell
source Module-Assemble-results
assemble-results | nice-nums | explore
```

## Collecting results

The script `SymPyReport.py` reads `result.json` files and goes through the discoveries until one is found that SymPy can handle.
The best way to run it is as a batch job,
```bash
sbatch SJob-Run-SymPy-reports
```
since processing each `result.json` file may take anywhere from a couple of seconds to several minutes.
This batch script goes through all the TOML files under `Specs/` and runs `SymPyReport.py` on its `result.json` file.
This produces a file `full-report.json` next to the `result.json` file.
The structure of the `full-report.json` file is:
```typescript
{
    "rating": number,
    "mse": number,
    "complexity": number,
    "complexity_defuzz": number,
    "expr": string,
    "expr_defuzz": string,
    "expr_original_syms": string,
    "expr_original_syms_defuzz": string,
    "run_set": string,
    "data_set": string,
    "sample_num": number
}
```

- `rating`:
  The rating of the agent, including mean-squared-error plus all penalties (regularity terms).
- `mse`:
  The mean-squared-error when applying the expression `expr` to the entire data set.
  Note that some data sets are large and a different random subset is used to rate genomes in each population.
- `complexity`:
  The number of nodes in the SymPy expression `expr`.
- `complexity_defuzz`:
  The number of notes in the SymPy expression `expr_defuzz`.
- `expr`:
  String representation of the SymPy expression derived from Jessamine output.
- `expr_defuzz`:
  String representation of the result of defuzzing `expr` at tolerance $10^{-5}$.
  See `AnalysisUtils.py`, and the `replace_near_integer` function for how defuzzing works.
- `expr_original_syms` and `expr_original_syms_defuzz`:
  The `expr` and `expr_defuzz` expressions are all in terms of $x_1$, $x_2$, etc.
  These `original_syms` expressions have the column names from the data file substituted.
  For example, the Strogatz data files all have columns `x` and `y`, so $x_1$ is replaced by $x$ and $x_2$ is replaced by $y$.
  Thus these are the same expressions but using the original symbols of the data file.
- `run_set`, `data_set`, `sample_num`:
  The run set, data set, and sample number of the micro-trial that generated this file.

The `SJob-Run-SymPy-reports` batch script also runs the `AssembleSymPyReports.py` script, which collects all of those `full-report.json` files into `Generated/full-report.csv`.

## Analysis notebooks

Each benchmark has a `For-analysis/` directory that contains the `full-report.csv` file used in the Jessamine benchmark article, and these are under git control.
The various `Analysis*.ipynb` Jupyter notebooks read these files.

## About reproducibility

The benchmark output files are not perfectly reproducible.
Timing effects and differences between CPUs are enough to generate tiny variations in population trajectories.
Timing differences can include variations in external Julia packages used by Jessamine that speed up or slow down a calculation, and file-system lag.

As an example, if two 15-minute runs of a particular spec file are running mostly identically, and a good genome is found at the last minute in one, the other run might lag just enough that it doesn't discover that same good genome until after the deadline.
Then the two runs produce different output at the end.

There does not seem to be a way to make the benchmark samples perfectly reproducible at this time.
The best approach for now is to run lots of samples and try for statistical consistency.
This is why the `full-report.csv` files used in the article were placed under git control.

## The benchmarks

### The sin benchmark

This corpus is straightforward.
All the data files are managed by git, so there should be no need to make them.

### The Strogatz benchmark

This corpus requires the submodule [ode-strogatz](http://github.com/lacava/ode-strogatz) for the data files.
Otherwise it's straightforward.

### The Friedman-1 benchmark

This corpus is straightforward.
All the data files are managed by git, so there should be no need to make them.

### The cosmology benchmark

This directory requires the submodule [Things-to-bench](https://github.com/CP3-Origins/Things-to-bench) for the data files.
Since there are a lot of them, some scripts handle the F and C data sets separately.

A few additional files:
- `CheckCData.py`:
  The [cp3-bench](https://arxiv.org/abs/2406.15531) article is a little unclear about how some of the data sets were generated.
  This script does computations to confirm whether various interpretations are correct.
  It is not necessary to run this script to run the benchmarks.
- `TableView.tex`:
  This LaTeX file produces a printable document of some of the tables created by `MakeSummaries.py`.

## About other files

### `benchmarks/*/*.toml`

The main executable from [JessamineCLI](https://github.com/wgm-applied-math/JessamineCLI.jl) can set configuration options via the command line, and it can read options from TOML files.
These small TOML files are assembled into per-micro-trial TOML files with all the necessary options by the `Make-specs` scripts.
Each micro-trial gets its own spec file because (1) all non-built-in default values are clearly spelled out; (2) this was the cleanest way to specify the random seed used to generate each trial.
(Although there are other complications that make it impossible to guarantee perfect reproducibility...)

### `benchmarks/Utils/`

The files here are scripts and modules common to all benchmarks.
Each benchmark directory has links to them.
This was done so that (1) any improvements to one of these files is immediately available to all benchmarks; (2) if it becomes necessary to customize one of these files for a particular benchmark, it's possible to do so by replacing the link with a separate file.
The links are created by `benchmarks/Setup-subdir`, but then they are added to git and do not need to be created again.

These scripts assume they are being run from within a subdirectory of `benchmarks/`.

- `Module-Make-specs`:
  Bash module that uses JessamineCLI to make individual TOML files for each micro-trial.
  Within each benchmark directory, there are `Make-specs` scripts that set certain shell variables, then load this module to actually make all those files.
  
- `SModule-Run-specs-scattered`:
  Bash module that goes through TOML files and runs JessamineCLI if necessary to make the corresponding micro-trial.
  Within each benchmark directory, there are `SJob-Run-specs` scripts that set certain shell variables, then load this file to actually run the micro-trials.
  The "scattered" aspect is that this module should allow you to run such job scripts with Slurm options like 
  ```
  sbatch --ntasks=512 SJob-Run-specs
  ```
  and the module will pick up on how many tasks have been allocated (`--ntasks=...`) and run that many micro-trials at a time in parallel within the same batch job.
  They can be run simultaneously across any number of nodes.
  There can be hundreds of these small jobs.
  Slurm's job- step system gets overwhelmed if all micro-trials are submitted via `srun` at once, so `parallel` is used to throttle the calls to `srun`.
  
  The primary function `maybe_run_spec` in this file checks to see whether the `result.json` script corresponding to a micro-trial spec exists.
  If it does, that micro-trial will not be re-run.
  This is so that if the batch job gets canceled (which happens if it takes longer than the time allowed by Slurm for a single job), it can be run again and it will (eventually) pick up where it left off.

- `QuickReport.py`:
  Python script for viewing the SymPy form of a `result.json` file created by Jessamine:
  ```
  python QuickReport.py Generated/.../result.json | less
  ```

- `SymPyReport.py`:
  Python script that reads a TOML spec file, reads the corresponding `result.json` file created by Jessamine, performs symbolic analysis on the output, including defuzzing, and writes the result to `full-report.json` file in the same directory.
  Since the symbolic operations can take a couple of minutes, this script should be run in parallel using `SJob-Run-SymPy-reports`.
  
- `SJob-Run-SymPy-reports`:
  Bash script usable as `sbatch SJob-Run-SymPy-reports` that runs `SymPyReport.py` on every TOML file in `Specs/`.
  It then runs `AssembleSymPyReports.py` to build `Generated/full-report.csv`.

- `AssembleSymPyReports.py`:
  Python script that goes through all TOML files in the `Specs/` directory, reads the corresponding SymPy reports from `full-report.json`, and puts everything together in `Generated/full-report.csv`

- `MakeSummaries.py`:
  Python script that reads `Generated/full-report.csv` and makes summary tables showing how many micro-trials were below various MSE and complexity thresholds.

- `AnalysisUtils.py`:
  Python module with definitions used in several other scripts and Jupyter notebooks.
  The function `replace_near_integer` defuzzes expressions.

- `Run-one-spec`:
  Bash script that runs a single TOML spec file.
  
- `Debug-one-spec`:
  Bash script that runs a single TOML spec file, with various settings to make Julia produce a lot of additional debugging output.

- `Fetch-data`:
  Bash script that uses `rsync` to copy all data files from the cluster.
  Unlikely to be useful on other clusters without modification.
  
- `Fetch-results`:
  Bash script that uses `rsync` to copy just the most essential data files from the cluster.
  Unlikely to be useful on other clusters without modification.


### `src/`

Julia source files for creating some of the datasets.
For examples of their use, see `benchmarks/sin/Make-sin-data` and `benchmarks/Friedman-1/Make-f1a` etc.

### `docs/`

Tools for processing the Julia documentation for the source files under `src/`.

### `benchmarks/`

- `Fetch-all-data`:
  Bash script that goes into each benchmark directory and runs `Fetch-data`.
  This is unlikely to be useful on other clusters without modification.
  
- `Fetch-all-results`:
  Bash script that goes into each benchmark directory and runs `Fetch-results`.
  This is unlikely to be useful on other clusters without modification.  

- `Setup-subdir`: 
  Bash script that creates links in a benchmark directory for useful files stored in `benchmarks/Utils`.
  Once these links are created, they are checked into git, so this script is only useful if another benchmark is added, or if the files in `benchmarks/Utils/` have to be restructured.
  
- `Setup-all`:
  Bash script that runs `Setup-subdir` for each benchmark directory.

### `benchmarks/Theory/`

The file `Reliability estimates.nb` is a Mathematica notebook for calculating the reliability tables in the article.
It is not necessary to run this file.
The results are stored as CSV files in `benchmarks/Theory/Results`, which are managed by git.

### `Tools/`

A few files that were used to initialize this Julia project, but are unlikely to be useful later.
