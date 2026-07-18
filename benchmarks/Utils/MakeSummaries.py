#!/bin/python

# Script to summarize complexity and MSE information.
#
# Run this after using AssembleSymPyReports.py to make
# Generated/full-report.csv.

import pandas as pd
import AnalysisUtils as au

def main():
    data = pd.read_csv("Generated/full-report.csv")
    data.sort_values(["run_set", "data_set", "mse"], inplace=True)
    data.set_index(["run_set", "data_set", "sample_num"], inplace=True)
    mse_tt = au.mse_threshold_table(data)
    mse_tt.to_csv("Generated/mse-summary.csv")
    mse_tt.to_latex("Generated/mse-summary.tex")
    c_tt = au.complexity_threshold_table(data)
    c_tt.to_csv("Generated/complexity-summary.csv")
    c_tt.to_latex("Generated/complexity-summary.tex")


if __name__ == "__main__":
    main()
