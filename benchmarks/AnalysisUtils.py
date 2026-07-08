import numpy as np
import pandas as pd
import seaborn as sns
import sympy
import sympy.abc


def parse_if_needed(expr_or_str) -> sympy.Expr:
    """Parse a string into a sympy expression, or return the expression if it is already a sympy expression."""
    if isinstance(expr_or_str, str):
        return sympy.sympify(expr_or_str)
    elif isinstance(expr_or_str, sympy.Expr):
        return expr_or_str
    else:
        raise ValueError("Input must be a string or a sympy expression")


def replace_near_integer(expr, tolerance=1e-5):
    """Replace numbers in a sympy expression that are within a given tolerance of an integer with that integer."""
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
    """Simplify a sympy expression generously.

    Generously meaning that numbers closer to an integer than the
    given tolerance are replaced with integers, and those within
    tolerance of a rational number are replaced with rationals."""
    expr = replace_near_integer(expr, tolerance=tolerance)
    expr = sympy.expand(expr, rational=False).evalf()
    expr = replace_near_integer(expr, tolerance=tolerance)
    expr = sympy.simplify(expr)
    expr = sympy.nsimplify(expr, tolerance=tolerance)
    return expr


def count_by_threshold(df, threshold):
    """Count rows in a dataframe where the 'mse' column is less than the threshold."""
    return sum(df["mse"] < threshold)


def apply_sym(expr, x, x_sym=sympy.abc.x):
    """Apply a sympy expression to a numeric value x, which can be an array."""
    expr = parse_if_needed(expr)
    return sympy.lambdify(x_sym, expr)(x)


def mse(y_true, y_pred):
    """Calculate the mean squared error between two arrays."""
    return np.mean(np.square(y_true - y_pred))


def complexity(expr):
    """Calculate the complexity of a sympy expression as in SRBench.

    Return the total number of nodes in the expression tree."""
    c = 0
    for arg in sympy.preorder_traversal(expr):
        c += 1
    return c
