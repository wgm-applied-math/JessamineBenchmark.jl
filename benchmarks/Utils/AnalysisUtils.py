from pathlib import Path

import numpy as np
import os
import pandas as pd
import seaborn as sns
import sympy
import sympy.abc
import typing
from typing import Optional

Pathish = typing.Union[str, os.PathLike[str], Path]

sns.set_theme("notebook", style="darkgrid")


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


def count_by_threshold(df: pd.DataFrame, threshold=1.0e-19, groupby="data_set"):
    """Count the number of rows in a dataframe where the 'mse' column is less than the given threshold."""
    comparisons = df["mse"] < threshold
    if groupby:
        return comparisons.groupby(level=groupby).sum()
    return comparisons.sum()


def savefig(fig, file_stem=None, picture_dir=Path("Generated/Pictures")):
    """Save a figure to the given directory with the given file stem."""
    if file_stem is not None:
        picture_dir = Path(picture_dir)
        picture_dir.mkdir(parents=True, exist_ok=True)
        fig.savefig((picture_dir / file_stem).with_suffix(".png"), dpi=600)
        fig.savefig((picture_dir / file_stem).with_suffix(".svg"))
        fig.savefig((picture_dir / file_stem).with_suffix(".pdf"))


def complexity_mse_displot(
    data: pd.DataFrame,
    spiffy_titles=None,
    complexity_col="complexity",
    mse_col="mse",
    complexity_binwidth=20,
    mse_binwidth=0.8,
    complexity_lims=(0, 449),
    mse_lims=(1.0e-12, 0.99e2),
    picture_dir=Path("Generated/Pictures"),
    file_stem=None,
    **kwargs,
):
    """Create a displot of complexity vs mse for each data set in the given dataframe."""
    assert mse_lims[0] < mse_lims[1], "mse_lims must be in increasing order"
    assert (
        complexity_lims[0] < complexity_lims[1]
    ), "complexity_lims must be in increasing order"
    assert complexity_binwidth > 0, "complexity_binwidth must be positive"
    assert mse_binwidth > 0, "mse_binwidth must be positive"
    assert complexity_col in data.columns, f"{complexity_col} not in dataframe columns"
    assert mse_col in data.columns, f"{mse_col} not in dataframe columns"

    mse_lims_log = (np.log10(mse_lims[0]), np.log10(mse_lims[1]))
    fig = sns.displot(
        data=data,
        x=complexity_col,
        y=mse_col,
        col="data_set",
        col_wrap=2,
        log_scale=(False, True),
        binwidth=(complexity_binwidth, mse_binwidth),
        binrange=(complexity_lims, mse_lims_log),
    )
    fig.set(xlim=complexity_lims, ylim=mse_lims)
    if spiffy_titles is not None:
        for ax, title in zip(fig.axes.flat, spiffy_titles):
            ax.set_title(title)
    fig.set(**kwargs)
    savefig(fig, file_stem=file_stem, picture_dir=picture_dir)
    return fig


def mse_threshold_table(data: pd.DataFrame):
    """Make a DataFrame with counts of how many samples are <= various MSE thresholds."""
    red = data[["mse"]].copy()
    agg_items = {}
    for j in range(0, 33, 4):
        key = f"mse{j:02d}"
        red[key] = red.mse <= 10.0 ** (-j)
        agg_items[key] = pd.NamedAgg(column=key, aggfunc="sum")
    to_group_by = list(data.index.names)
    to_group_by.remove("sample_num")
    return red.groupby(to_group_by).agg(
        mse_min=pd.NamedAgg(column="mse", aggfunc="min"),
        mse_med=pd.NamedAgg(column="mse", aggfunc="median"),
        mse_max=pd.NamedAgg(column="mse", aggfunc="max"),
        **agg_items,
    )


def complexity_threshold_table(data: pd.DataFrame):
    """Make a DataFrame with counts of how many samples are <= various complexity thresholds."""
    red = data[["complexity_defuzz"]].copy()
    agg_items = {}
    for j in range(400, 0, -50):
        key = f"cplx{j:03d}"
        red[key] = red.complexity_defuzz <= j
        agg_items[key] = pd.NamedAgg(column=key, aggfunc="sum")
    for j in range(50, 0, -10):
        key = f"cplx{j:03d}"
        red[key] = red.complexity_defuzz <= j
        agg_items[key] = pd.NamedAgg(column=key, aggfunc="sum")
    return red.groupby(["run_set", "data_set"]).agg(
        cplx_min=pd.NamedAgg(column="complexity_defuzz", aggfunc="min"),
        cplx_med=pd.NamedAgg(column="complexity_defuzz", aggfunc="median"),
        cplx_max=pd.NamedAgg(column="complexity_defuzz", aggfunc="max"),
        **agg_items,
    )


def to_latex(
    df: pd.DataFrame,
    file: Optional[Pathish] = None,
    strip_colname_prefix: Optional[str] = None,
    strip_rowname_prefix: Optional[str] = None,
):
    """Convert a DataFrame to a LaTeX string with sane styling."""
    styler = df.style
    float_columns = df.select_dtypes(include=[np.floating]).columns
    float_formatters = {col: "{:.1e}".format for col in float_columns}
    styler = (
        styler.format_index(escape="latex", axis="index")
        .format_index(escape="latex", axis="columns")
        .format_index_names(escape="latex")  # requires pandas v3.0 or later
        .format(formatter=float_formatters)
    )
    if strip_colname_prefix is not None:
        new_columns = [col.removeprefix(strip_colname_prefix) for col in df.columns]
        new_columns = [col.removeprefix("_") for col in new_columns]
        styler = styler.relabel_index(new_columns, axis="columns")

    if strip_rowname_prefix is not None:
        new_index = [idx.removeprefix(strip_rowname_prefix) for idx in df.index]
        new_index = [idx.removeprefix("_") for idx in new_index]
        styler = styler.relabel_index(new_index, axis="index")

    return styler.to_latex(file)
