"""
Script to read a JSON output file with a y_num_str field, do various simplifications, and print the results.
"""

import argparse
import sympy
import json

parser = argparse.ArgumentParser()
parser.add_argument("file")


def round_near_integer(expr, epsilon=1e-5):
    if expr.func == sympy.Float:
        x = expr.evalf()
        x_int = round(x)
        x_frac = x - x_int
        if abs(x_frac) < epsilon:
            return sympy.Integer(x_int)
        else:
            return expr
    elif len(expr.args) == 0:
        return expr
    else:
        new_args = map(lambda e: round_near_integer(e, epsilon=epsilon), expr.args)
        return expr.func(*new_args)


def main():
    args = parser.parse_args()
    with open(args.file, "rt") as f:
        data = json.load(f)
    rating = data["best_agent"]["rating"]
    print(f"Rating: {rating}")
    expr = sympy.parse_expr(data["y_num_str"])
    # expr = sympy.simplify(expr)
    # sympy.pprint(expr_simp, use_unicode=True)
    # expr = round_near_integer(expr.evalf())
    # expr = sympy.simplify(expr)
    sympy.pprint(expr, wrap_line=False, use_unicode=True)


if __name__ == "__main__":
    main()
