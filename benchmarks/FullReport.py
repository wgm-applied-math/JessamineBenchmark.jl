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
            print("Exception during report generation:")
            traceback.print_exc()
            raise
    return pd.DataFrame(reports)

def main():
    df = make_all_reports()
    df.to_csv("Generated/full-report.csv", index=False)

if __name__ == "__main__":
    main()
