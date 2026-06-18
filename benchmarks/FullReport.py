import json
import math
from contextlib import contextmanager
import multiprocessing
import pandas as pd
from pathlib import Path
import sympy
import sys
import tomllib
import traceback
import warnings

class TimeoutError(Exception):
    pass

class NoSolutionError(Exception):
    pass

# This has to be at module scope rather than be a closure because
# of some limitation of pickling.
def worker(queue, f, f_args, f_kwargs):
    try:
        report = f(*f_args, **f_kwargs)
        queue.put({"value": report})
    except Exception as e:
        queue.put({"exception": e})

def run_with_time_limit(seconds, f, *f_args, **f_kwargs):
    queue = multiprocessing.Queue()

    process = multiprocessing.Process(target=worker, args=(queue, f, f_args, f_kwargs))
    process.start()
    process.join(seconds)

    if process.is_alive():
        # We waited in join() and ran out of time.
        process.terminate()
        process.join()
        raise TimeoutError()

    # If we get to here, the subprocess finished in time.
    report = queue.get()
    if report.haskey("exception"):
        raise report["exception"]

    # If we get to here, the subprocesses completed the report.
    return report["value"]


# This also has to be at module level because of pickling.
def do_work(r, X, y, input_columns):
    f_arg_syms = sympy.symbols(f"x1:{1+len(input_columns)}", real=True)
    orignal_syms = sympy.symbols(input_columns)
    epsilon = sympy.symbols("ε", real=True)
    Inf = sympy.symbols("Inf", real=True)
    vd = ({ str(x): x for x in f_arg_syms } |
          {"epsilon": epsilon, "ε": epsilon, "ϵ": epsilon, "Inf": Inf})

    rating = r["agent"]["rating"]
    raw_reg_str = r["y_num_str"]

    print("About to parse")
    expr = sympy.parsing.sympy_parser.parse_expr(raw_reg_str, vd)
    print("About to simplify")
    expr = sympy.simplify(expr, rational=False)

    # These show up in certain cases of division by zero.
    # In Julia, 1.0 / 0.0 is Inf.
    if epsilon in expr.free_symbols:
        print("About to do limit epslion -> 0")
        expr = sympy.limit(expr, epsilon, 0, dir="+").evalf()
        print("About to simplify")
        expr = sympy.simplify(expr, rational=False)

    # These also show up sometimes
    if Inf in expr.free_symbols:
        print("About to do limit Inf -> infinity")
        expr = sympy.limit(expr, Inf, sympy.oo).evalf()
        print("About to simplify")
        expr = sympy.simplify(expr, rational=False)

    print("About to lambdify")
    f = sympy.lambdify(f_arg_syms, expr)

    # Apply f to each row of X
    print("About to do X.apply")
    y_hat = X.apply(lambda row: f(*row[input_columns]), axis=1)
    mse = ((y - y_hat)**2).mean()

    if not math.isnan(mse) and math.isfinite(mse):
        expr_original_syms = expr.subs(zip(f_arg_syms, orignal_syms))
        sys.stdout.write(f" {mse}\n")

        return {
            "rating": rating,
            "mse": mse,
            "expr_original_syms": str(expr_original_syms),
            "expr": str(expr),
        }
    else:
        raise NoSolutionError()

def make_report(config):
    data_file = Path(config["data_file"])
    output_file = Path(config["output_file"])
    data_set = output_file.parent.parent.name
    run_set = output_file.parent.parent.parent.name
    sample_num = int(output_file.parent.name)

    df = pd.read_csv(data_file)
    output_column = config.get("output_column", "label")
    input_columns = list(df.columns)
    input_columns.remove(output_column)
    y = df[output_column]
    X = df[input_columns]

    with output_file.open("rt") as f:
        result = json.load(f)

    n_disc = len(result["discoveries"])
    sys.stdout.write(f"{data_file.name}/{sample_num}: {n_disc} ")


    report = None
    for r in result["discoveries"]:
        sys.stdout.write(".")
        try:
            # Elevate all warnings to errors so any trouble
            # sympy has triggers moving on to the next discovery.
            # These are generally numerical overflows and such.
            with warnings.catch_warnings(action="error"):
                report = run_with_time_limit(60, do_work, r, X, y, input_columns)
                break
        except Exception as e:
            print("Caught exception, skipping:")
            print(e)
            pass

    if report is None:
        raise NoSolutionError()

    return report | {
            "run_set": run_set,
            "data_set": data_set,
            "sample_num": sample_num
            }

def make_or_load_report(config_file):
    config_file = Path(config_file)
    # *shrug* tomllib requires a binary stream
    with open(config_file, "rb") as f:
        config = tomllib.load(f)
    output_file = Path(config["output_file"])
    report_file = output_file.with_name("full-report.json")
    report = None
    if report_file.is_file():
        try:
            with report_file.open("rt") as f:
                report = json.load(f)
            print("Loaded", report_file)
        except Exception:
            report = None

    if report is None:
        report = make_report(config)
        with report_file.open("wt") as f:
            json.dump(report, f)
        # For debugging purposes
        assert False
        return report_file


def make_all_reports():
    spec_dir = Path("Specs")
    reports = []
    for spec_file in sorted(spec_dir.glob("**/*.toml")):
        try:
            report = make_or_load_report(spec_file)
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
