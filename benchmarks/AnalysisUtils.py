import numpy as np
import pandas as pd
import seaborn as sns
import sympy


def parse_if_needed(expr_or_str) -> sympy.Expr:
    if isinstance(expr_or_str, str):
        return sympy.sympify(expr_or_str)
    elif isinstance(expr_or_str, sympy.Expr):
        return expr_or_str
    else:
        raise ValueError("Input must be a string or a sympy expression")


def replace_near_integer(expr, tolerance=1e-5):
    if expr.func == sympy.Float:
        x = expr.evalf()
        x_int = round(x)
        x_frac = x - x_int
        if abs(x_frac) < tolerance:
            return sympy.Integer(x_int)
        else:
            return expr
    elif len(expr.args) == 0:
        return expr
    else:
        new_args = map(
            lambda e: replace_near_integer(e, tolerance=tolerance), expr.args
        )
        return expr.func(*new_args)
    

def to_spiffy(expr):
    expr = sympy.expand(expr, rational=False)
    expr = replace_near_integer(expr, tolerance=1e-6)
    # Too time consuming:
    # expr = sympy.simplify(expr)
    return expr


def generous_simplify(expr, tolerance=5e-3):
    expr = replace_near_integer(expr, tolerance=tolerance)
    expr = sympy.expand(expr, rational=False).evalf()
    expr = replace_near_integer(expr, tolerance=tolerance)
    expr = sympy.simplify(expr)
    expr = sympy.nsimplify(expr, tolerance=tolerance)
    return expr


def count_by_threshold(df, threshold):
    return sum(df["mse"] < threshold)