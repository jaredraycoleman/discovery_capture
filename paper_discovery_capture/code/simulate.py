"""Exact simulator for landing-only search of an escaping target on the line.

The searcher lands alternately at x_i = (-1)^i a_i (a_i > 0), returning through
the origin between landings. The target starts at distance D >= 1 on one side and
moves away from the origin at speed v < 1. At landing i (time t_i) the target is
discovered iff it is on that side and D + v t_i <= a_i, i.e. D <= B_i(v).

This module computes the exact worst-case competitive ratio of a given landing
sequence by placing the target just beyond every reach B_i(v) (the adversary's
only useful choices) and taking the supremum. It is used to check the closed
forms in the paper against brute force:

    uv run python simulate.py            # compare formulas at a few speeds
    uv run python simulate.py --sweep    # numeric optimum over r vs. closed form
"""

from __future__ import annotations

import argparse
import math
from typing import Callable, Sequence

import numpy as np
from scipy.optimize import minimize_scalar


# --------------------------------------------------------------------------
# Core model
# --------------------------------------------------------------------------

def landing_times(a: Sequence[float]) -> list[float]:
    """t_i = 2 S_{i-1} + a_i."""
    t, S = [], 0.0
    for ai in a:
        t.append(2 * S + ai)
        S += ai
    return t


def reaches(a: Sequence[float], v: float) -> list[float]:
    """B_i(v) = a_i - v t_i: largest D on side i discovered at landing i."""
    return [ai - v * ti for ai, ti in zip(a, landing_times(a))]


def first_discovery_index(a: Sequence[float], D: float, side: int, v: float) -> int | None:
    """Index of the first landing that discovers a target starting at sigma*D."""
    for i, (ai, ti) in enumerate(zip(a, landing_times(a))):
        if (-1) ** i != side:
            continue
        if D + v * ti <= ai:
            return i
    return None


def discovery_time(a: Sequence[float], D: float, side: int, v: float) -> float:
    i = first_discovery_index(a, D, side, v)
    if i is None:
        return math.inf
    return landing_times(a)[i]


def capture_time(a: Sequence[float], D: float, side: int, v: float) -> float:
    """t_i + (a_i - D - v t_i)/(1+v) = (2 S_i - D)/(1+v) for discovery at i."""
    i = first_discovery_index(a, D, side, v)
    if i is None:
        return math.inf
    S_i = sum(a[: i + 1])
    return (2 * S_i - D) / (1 + v)


def worst_case_ratio(a: Sequence[float], v: float, cost: Callable, eps: float = 1e-9,
                     skip_first: int = 4) -> float:
    """sup over D, sigma of cost / (D / (1 - v)).

    The ratio cost(D)/D is piecewise decreasing in D between consecutive
    reaches, so the supremum is approached by D just above some B_i(v). We
    skip the first few indices so that the start-up transient (D >= 1 and
    S_{-1} = 0) does not dominate; the asymptotic ratio is what the paper's
    closed forms describe.
    """
    B = reaches(a, v)
    worst = 0.0
    for i in range(skip_first, len(a) - 3):
        if B[i] <= 0:
            continue
        D = B[i] + eps
        side = (-1) ** i
        T = cost(a, D, side, v)
        if math.isinf(T):
            continue
        worst = max(worst, T * (1 - v) / D)
    return worst


# --------------------------------------------------------------------------
# Closed forms from the drafts
# --------------------------------------------------------------------------

def cr_disc_geometric(r: float, v: float) -> float:
    """Eq. (5) of landing_only_mobile_line_search.pdf."""
    return (1 - v) * r**2 * (r + 1) / ((1 - v) * r - (1 + v))


def cr_cap_geometric(r: float, v: float) -> float:
    """Eq. (12) of landing_only_mobile_line_search.pdf."""
    return (1 - v) / (1 + v) * (2 * r**3 / ((1 - v) * r - (1 + v)) - 1)


def r_disc_opt(v: float) -> float:
    return (1 + 2 * v + math.sqrt(5 + 4 * v)) / (2 * (1 - v))


def cr_disc_opt(v: float) -> float:
    s = math.sqrt(5 + 4 * v)
    return (s + 3) * (2 * v + s + 1) ** 2 / (4 * (1 - v) ** 2 * (s - 1))


def r_cap_opt(v: float) -> float:
    return 3 * (1 + v) / (2 * (1 - v))


def cr_cap_opt(v: float) -> float:
    return (2 * v + 1) * (v + 5) ** 2 / (2 * (1 - v) ** 2 * (1 + v))


def cr_disc_ek(a: float, v: float) -> float:
    """Discovery upper bound as written in dis-cap-line.pdf, Section 2.3.2."""
    return a**2 * (a + 1 - 2 * v) / ((1 - v) * (a - 1 - 2 * v))


def cr_cap_ek(a: float, v: float) -> float:
    """Capture upper bound as written in dis-cap-line.pdf, Section 2.3.3."""
    return (-1 + 2 * a**2 * (a - v - v**2) / ((1 - v) * a - (1 + v))) / (1 + v)


# --------------------------------------------------------------------------
# Checks
# --------------------------------------------------------------------------

def geometric(r: float, n: int = 60) -> list[float]:
    return [r**i for i in range(n)]


def compare_formulas(v: float, r: float, n: int = 60) -> None:
    a = geometric(r, n)
    sim_disc = worst_case_ratio(a, v, discovery_time)
    sim_cap = worst_case_ratio(a, v, capture_time)
    print(f"v = {v:.3f}, r = {r:.4f}")
    print(f"  discovery: simulated {sim_disc:12.6f}   draft (5) {cr_disc_geometric(r, v):12.6f}"
          f"   EK 2.3.2 {cr_disc_ek(r, v):12.6f}")
    print(f"  capture:   simulated {sim_cap:12.6f}   draft (12) {cr_cap_geometric(r, v):12.6f}"
          f"   EK 2.3.3 {cr_cap_ek(r, v):12.6f}")


def sweep(v: float) -> None:
    lo = (1 + v) / (1 - v) * (1 + 1e-6)
    hi = lo + 50
    res_d = minimize_scalar(lambda r: cr_disc_geometric(r, v), bounds=(lo, hi), method="bounded")
    res_c = minimize_scalar(lambda r: cr_cap_geometric(r, v), bounds=(lo, hi), method="bounded")
    print(f"v = {v:.3f}")
    print(f"  discovery: numeric r* {res_d.x:.6f} CR {res_d.fun:.6f} | closed form r* {r_disc_opt(v):.6f} CR {cr_disc_opt(v):.6f}")
    print(f"  capture:   numeric r* {res_c.x:.6f} CR {res_c.fun:.6f} | closed form r* {r_cap_opt(v):.6f} CR {cr_cap_opt(v):.6f}")


def main() -> None:
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--sweep", action="store_true", help="numerically optimize r and compare to closed forms")
    args = p.parse_args()

    speeds = [0.0, 0.2, 0.5]
    if args.sweep:
        for v in speeds + [0.8]:
            sweep(v)
        return

    print("Geometric landing sequences a_i = r^i: brute-force worst case vs. closed forms\n")
    for v in speeds:
        # Use a radius comfortably inside the feasible region (4), e.g. 1.5x the threshold.
        r = max(1.5 * (1 + v) / (1 - v), 2.0)
        compare_formulas(v, r)
    print("\nAt the claimed optimizers:")
    for v in speeds:
        compare_formulas(v, r_disc_opt(v))
        compare_formulas(v, r_cap_opt(v))


if __name__ == "__main__":
    main()
