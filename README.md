# JessamineBenchmark

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://wgmitchener.github.io/JessamineBenchmark.jl/stable/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://wgmitchener.github.io/JessamineBenchmark.jl/dev/)
[![Build Status](https://github.com/wgmitchener/JessamineBenchmark.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/wgmitchener/JessamineBenchmark.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Aqua QA](https://juliatesting.github.io/Aqua.jl/dev/assets/badge.svg)](https://github.com/JuliaTesting/Aqua.jl)

## Set up Python

The Jupyter notebooks under [`behcnmarks/`](benchmarks/) use several Python packages and may need more recent versions that what's installed on your system.
To set up a virtual environment with working versions of these Python packages, open a command line in this directory and run

```
python -m venv
source venv/bin/activate.{your shell}
pip install -r requirements.txt
```
