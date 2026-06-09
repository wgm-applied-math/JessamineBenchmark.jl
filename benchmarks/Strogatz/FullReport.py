#import argparse
import json
from unittest import result
import pandas as pd
from pathlib import Path
import sympy
import tomllib

#parser = argparse.ArgumentParser()
#parser.add_argument("config_file")


def make_report(config_file):
    config_file = Path(config_file)
    # *shrug* tomllib requires a binary stream
    with open(config_file, "rb") as f:
        config = tomllib.load(f)

    data_file = Path(config["data_file"])
    output_file = Path(config["output_file"])
    dataset = output_file.parent.parent.name
    samplenum = int(output_file.parent.name)

    df = pd.read_csv(data_file)
    output_column = config.get("output_column", "label")
    input_columns = list(df.columns)
    input_columns.remove(output_column)
    y = df[output_column]
    X = df[input_columns]

    with open(output_file, "rt") as f:
        result = json.load(f)

    expr = sympy.parse_expr(result["y_num_str"])

    # Use original form, unless there are complications
    # input_syms = sympy.symbols(input_columns)
    # These show up in certain cases of division by zero:
    epsilon = sympy.symbols("ϵ")
    if epsilon in expr.free_symbols:
        expr_simp = sympy.simplify(expr)
        expr = sympy.limit(expr_simp, epsilon, 0, dir="+-")
        expr = sympy.simplify(expr)
        
    # These also show up sometimes
    Inf = sympy.symbols("Inf")
    if Inf in expr.free_symbols:
        expr_simp = sympy.simplify(expr)
        expr = sympy.limit(expr_simp, Inf, sympy.oo)
        expr = sympy.simplify(expr)

    expr = expr.evalf()
    farg_syms = sympy.symbols(f"x1:{1+len(input_columns)}")
    f = sympy.lambdify(farg_syms, expr)

    # Apply f to each row of X
    y_hat = X.apply(lambda row: f(*row[input_columns]), axis=1)

    mse = ((y - y_hat)**2).mean()

    return {
        "dataset": dataset,
        "samplenum": samplenum,
        "mse": mse,
        "expr": expr,
        # "input_columns": input_columns,
        # "output_column": output_column,
        # "f": f,
        # "X": X,
        # "y": y,
        # "y_hat": y_hat
        }


def make_all_reports():
    spec_dir = Path("Specs")
    reports = []
    for spec_file in spec_dir.glob("*.toml"):
        print(f"Making report for {spec_file}")        
        report = make_report(spec_file)
        print(f"Report: {report}")
        reports.append(report)
    return pd.DataFrame(reports)

def main():
    df = make_all_reports()
    df.to_csv("Generated/full-report.csv", index=False)

if __name__ == "__main__":
    main()
