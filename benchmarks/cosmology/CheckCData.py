#!/usr/bin/python

# The article Thing and Koksbang 2025, has several statements
# that are inconsistent, hard to interpret correctly, misleading,
# etc.  This module defines functions for checking that I have
# the correct interpretations.

import numpy as np
import pandas as pd


# This is labeled consistently as rho_NFW
def fn_C5a(r):
    return 1.0 / (r * (1.0 + r) ** 2)


# This is also labeled as rho_NFW.
# I think the intention is to generalize C5a
# as in C5d(r, R0) = C5a(r/R0), eq (2.17)
def fn_C5d(r, R0):
    return 1.0 / ((r / R0) * (1.0 + r / R0) ** 2)


# This is labeled as rho_core eq (2.18)
def fn_C5e(r, R0):
    return R0**3 / ((r + R0) * (r**2 + R0**2))


# The text above (2.19) seems to indicate that C5f is the
# following
def txt219_C5f(r, R0, x):
    return 0.5 * (fn_C5d(r, R0) + fn_C5e(r, R0)) + x * 0.5 * (
        fn_C5d(r, R0) - fn_C5e(r, R0)
    )


def check1():
    print("Checking C5f")
    print("C5f: Checking txt219_C5f")
    C5f = pd.read_csv("Things-to-bench/cosmo_data/C5f.csv")
    r = C5f.r
    R0 = C5f.R0
    x = C5f.x
    target = C5f.target
    y = txt219_C5f(r, R0, x)
    err = np.sum(np.square(y - target))
    print(f"C5f: Sum square error = {err}")


def fn_C1a(z):
    return 0.0716 * np.sqrt(0.3 * (1 + z) ** 3 + 0.7)


# Apparently the C2a data set is target = linear function of H
# and z, and H is some function of z.  But it's not C1a(z).  It
# might be something like the nonlinear term in C2b, and based on
# the text after equation (2.3), I think that's what they've done
# but with several different values of omega.
def check2():
    print("Checking C2a")
    C2a = pd.read_csv("Things-to-bench/cosmo_data/C2a.csv")
    z = C2a.z
    H = C2a.H
    H_check = fn_C1a(z)
    err = np.sum(np.square(H - H_check))
    print(f"C2a: Sum square error = {err}")


def main():
    # check1()
    check2()


if __name__ == "__main__":
    main()
