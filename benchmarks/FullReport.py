import json
import math
import signal
from contextlib import contextmanager
import pandas as pd
from pathlib import Path
import sympy
import sys
import tomllib
import traceback
import warnings

class TimeoutError(Exception):
    pass


@contextmanager
def time_limit(seconds=60):
    def _handler(signum, frame):
        raise TimeoutError(f"Calculation exceeded {seconds}s time limit")
    old_handler = signal.signal(signal.SIGALRM, _handler)
    signal.alarm(seconds)
    try:
        yield
    finally:
        signal.alarm(0)
        signal.signal(signal.SIGALRM, old_handler)


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

    farg_syms = sympy.symbols(f"x1:{1+len(input_columns)}", real=True)
    orignal_syms = sympy.symbols(input_columns)
    epsilon = sympy.symbols("ε", real=True)
    Inf = sympy.symbols("Inf", real=True)
    vd = ({ str(x): x for x in farg_syms } |
          {"epsilon": epsilon, "ε": epsilon, "ϵ": epsilon, "Inf": Inf})

    f = None
    expr = None
    expr_original_syms = None
    rating = math.inf
    mse = math.inf
    n_disc = len(result["discoveries"])
    sys.stdout.write(f"{config_file.name}: {n_disc} ")
    for r in result["discoveries"]:
        sys.stdout.write(".")
        rating = r["agent"]["rating"]
        raw_reg_str = r["y_num_str"]
        try:
            # Elevate all warnings to errors so any trouble
            # sympy has triggers moving on to the next discovery.
            # These are generally numerical overflows and such.
            with warnings.catch_warnings(action="error"):
                with time_limit():
                    expr = sympy.parsing.sympy_parser.parse_expr(raw_reg_str, vd)
                    expr = sympy.simplify(expr, rational=False)

                    # These show up in certain cases of division by zero.
                    # In Julia, 1.0 / 0.0 is Inf.
                    if epsilon in expr.free_symbols:
                        expr = sympy.limit(expr, epsilon, 0, dir="+").evalf()
                        expr = sympy.simplify(expr, rational=False)

                    # These also show up sometimes
                    if Inf in expr.free_symbols:
                        expr = sympy.limit(expr, Inf, sympy.oo).evalf()
                        expr = sympy.simplify(expr, rational=False)

                    f = sympy.lambdify(farg_syms, expr)

                    # Apply f to each row of X
                    y_hat = X.apply(lambda row: f(*row[input_columns]), axis=1)
                    mse = ((y - y_hat)**2).mean()
                    if not math.isnan(mse) and math.isfinite(mse):
                        sys.stdout.write(f" {mse}\n")
                        expr_original_syms = expr.subs(farg_syms, orignal_syms)
                        # If all of that works, we've found a good one, exit the loop
                        break
        except:
            pass

    return {
        "dataset": dataset,
        "samplenum": samplenum,
        "rating": rating,
        "mse": mse,
        "expr_original_syms": expr_original_syms,
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
    for spec_file in sorted(spec_dir.glob("*.toml")):
        try:
            report = make_report(spec_file)
            reports.append(report)
        except:
            print("Exception during report generation:")
            traceback.print_exc()
    return pd.DataFrame(reports)

def main():
    df = make_all_reports()
    df.to_csv("Generated/full-report.csv", index=False)

if __name__ == "__main__":
    main()
