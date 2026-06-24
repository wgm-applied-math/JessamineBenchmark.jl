import pandas as pd
from pathlib import Path
import traceback

from SymPyReport import make_or_load_report

def make_all_reports():
    spec_dir = Path("Specs")
    reports = []
    for spec_file in sorted(spec_dir.glob("**/*.toml")):
        try:
            report = make_or_load_report(spec_file)
            # print(report)
            reports.append(report)
        except Exception:
            print("Exception during report generation; skipping")
            traceback.print_exc()
            # raise
    df = pd.DataFrame(reports)
    return df[["run_set", "data_set", "sample_num", "rating", "mse", "expr_original_syms", "expr"]]

def main():
    df = make_all_reports()
    df.to_csv("Generated/full-report.csv", index=False)

if __name__ == "__main__":
    main()
