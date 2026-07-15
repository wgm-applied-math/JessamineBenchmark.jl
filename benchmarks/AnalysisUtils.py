from pathlib import Path

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
    expr = sympy.cancel(expr)
    expr = replace_near_integer(expr, tolerance=tolerance)
    return expr

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

def count_by_threshold(df, threshold=1.0e-19):
    """Count the number of rows in a dataframe where the 'mse' column is less than the given threshold."""
    return (df["mse"] < threshold).groupby(level="data_set").sum()

def complexity_mse_displot(data, spiffy_titles=None, complexity_col="complexity", mse_col="mse",
                     complexity_binwidth=20, mse_binwidth=0.8, complexity_lims=(0, 449), mse_lims=(1.0e-12, 0.99e2),
                     picture_dir=Path("Generated/Pictures"),
                     file_stem=None,
                     **kwargs):
    """Create a displot of complexity vs mse for each data set in the given dataframe."""
    mse_lims_log = (np.log10(mse_lims[0]), np.log10(mse_lims[1]))
    fig = sns.displot(data=data,
                      x=complexity_col,
                      y=mse_col,
                      col="data_set",
                      col_wrap=2,
                      log_scale=[False, True],
                      binwidth=(complexity_binwidth, mse_binwidth),
                      binrange=(complexity_lims, mse_lims_log),
                      )
    fig.set(xlim=complexity_lims, ylim=mse_lims)
    if spiffy_titles is not None:
        for ax, title in zip(fig.axes.flat, spiffy_titles):
            ax.set_title(title)
    fig.set(**kwargs)
    if file_stem is not None:
        picture_dir = Path(picture_dir)
        picture_dir.mkdir(parents=True, exist_ok=True)
        fig.savefig((picture_dir / file_stem).with_suffix(".png"), dpi=600)
        fig.savefig((picture_dir / file_stem).with_suffix(".svg"))
        fig.savefig((picture_dir / file_stem).with_suffix(".pdf"))
    return fig