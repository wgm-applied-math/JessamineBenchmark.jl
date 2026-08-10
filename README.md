# JessamineBenchmark

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://wgmitchener.github.io/JessamineBenchmark.jl/stable/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://wgmitchener.github.io/JessamineBenchmark.jl/dev/)
[![Build Status](https://github.com/wgmitchener/JessamineBenchmark.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/wgmitchener/JessamineBenchmark.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Aqua QA](https://juliatesting.github.io/Aqua.jl/dev/assets/badge.svg)](https://github.com/JuliaTesting/Aqua.jl)

## Set up a UNIX-like environment

These programs were developed and run on Fedora Linux, versions 43 and 44, and Rocky Linux.
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

## Running the benchmarks

Scripts to run the benchmarks are located in subdirectories of `benchmarks/`.
To run each benchmark, the general procedure is to
- ensure data files are available
- create a TOML spec file in `Specs/` for each micro-trial
- run the micro-trials using Slurm; results stored in `Generated/`
- assemble the results using Python scripts; results stored in `Generated/`
- analyze the results using Jupyter notebooks; pictures and other output stored in `Generated/`

A `Run-all-trials` script is included in each benchmark.
It includes commands necessary to make the spec files and run the micro-trials.
Since that takes a variable amount of time, the script includes comments with instructions on how to run the remaining steps once the trials have finished.

_You will probably need to edit the `sbatch` commands to match your Slurm system._
These scripts have generally been written with `--ntasks=512` because that enables the maximum number of simultaneous jobs on my system's default partition (queue).
Also, my system does not impose a time limit on jobs.
If yours does, you may need to submit the same `sbatch` command several times until all trials have run.

Since it is often difficult to run interactive programs like Jupyter notebooks on a Slurm cluster, you may need to repeat the entire setup process on a personal workstation, then copy the results to that for analysis.
The `Fetch-results` scripts show a way to use [rsync](https://rsync.samba.org/) to do this nicely.
They will have to be adapted to your Slurm cluster.

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
Since there are a lot of them, the scripts handle the F and C data sets separately.

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
  They can be run simultaneously across however many nodes were allocated.
  Since there can be hundreds of these small jobs, Slurm's job step system gets overwhelmed if all micro-trials are submitted via `srun` at once.
  So `parallel` is used to throttle the number of calls to `srun`.
  
  The primary function `maybe_run_spec` in this file checks to see whether the `result.json` script corresponding to a micro-trial spec exists.
  If it does, that micro-trial will not be re-run.
  This is so that if the batch job takes longer than the time allowed by Slurm for a single job, it can be run again and it will (eventually) pick up where it left off.

- `QuickReport.py`:
  Python script for viewing the SymPy form of a `results.json` file created by Jessamine.

- `SymPyReport.py`:
  Python script that reads a TOML spec file, reads the corresponding `result.json` file created by Jessamine, performs symbolic analysis on the output, including defuzzing, and writes the result to `full-report.json` file in the same directory.
  Since the symbolic operations can take a couple of minutes, this script can be run in parallel using `SJob-Run-SymPy-reports`.
  
- `SJob-Run-SymPy-reports`:
  Bash script usable as `sbatch SJob-Run-SymPy-reports ...` that runs `SymPyReport.py` on every TOML file in `Specs/`.
  It then runs `AssembleSymPyReports.py` to build `Generated/full-report.csv`.

- `AssembleSymPyReports.py`:
  Python script that goes through all TOML files in the `Specs/` directory, reads the corresponding SymPy reports, and puts everything together in `Generated/full-report.csv`

- `MakeSummaries.py`:
  Python script that reads `Generated/full-report.csv` and makes summary tables showing how many micro-trials were below various MSE and complexity thresholds.

- `AnalysisUtils.py`:
  Python module with definitions used in several other scripts and Jupyter notebooks.

- `Run-one-spec`:
  Bash script that runs a single TOML spec file.
  
- `Debug-one-spec`:
  Bash script that runs a single TOML spec file, with various settings to make Julia produce a lot of additional debugging output.

- `Fetch-data`:
  Bash script that uses `rsync` to copy all data files from the cluster.
  Unlikely to be useful elsewhere.
  
- `Fetch-results`:
  Bash script that uses `rsync` to copy just the most essential data files from the cluster.
  Unlikely to be useful elsewhere.


### `src/`

Julia source files for creating some of the datasets.
For examples of their use, see `benchmarks/sin/Make-sin-data` and `benchmarks/Friedman-1/Make-f1a` etc.

### `docs/`

Tools for processing the Julia documentation for the source files under `src/`.

### `benchmarks/`

- `Fetch-all-data`:
  Bash script that goes into each benchmark directory and runs `Fetch-data`.
  This is unlikely to be useful outside the College of Charleston.
- `Fetch-all-results`:
  Bash script that goes into each benchmark directory and runs `Fetch-results`.
  This is unlikely to be useful outside the College of Charleston.
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

