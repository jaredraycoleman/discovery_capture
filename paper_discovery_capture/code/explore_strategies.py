"""Numerical exploration for the lower-bound section.

Two questions, both in the excursion model (every sortie starts and ends at the
origin, one landing per sortie):

1. Does the geometric alternating strategy a_i = c r^i achieve its asymptotic
   ratio as a supremum over *all* targets D >= 1 (including the start-up
   transient), for a suitable scale c? This is needed for the upper bound to be
   exactly tight rather than "asymptotically" tight.

2. Can a non-alternating side pattern (e.g. + + - or + + - -) beat the best
   alternating strategy? We optimize periodic strategies: a side pattern of
   period p, free positive sortie lengths a_1..a_p, and a_{i+p} = r a_i.

    uv run python explore_strategies.py
"""

from __future__ import annotations

import itertools
import math

import numpy as np
from scipy.optimize import minimize

from simulate import (
    capture_time,
    cr_cap_opt,
    cr_disc_opt,
    discovery_time,
    landing_times,
    r_cap_opt,
    r_disc_opt,
)


def full_sup_ratio(a, sides, v, cost, eps=1e-9):
    """sup over all D >= 1 and both signs of cost / (D/(1-v)).

    cost(D)/D is decreasing in D between consecutive discovery thresholds, so
    the supremum is attained at D = 1 or just above a reach B_i(v) >= 1.
    """
    t = landing_times(a)
    B = [ai - v * ti for ai, ti in zip(a, t)]
    worst = 0.0
    candidates = [(1.0, +1), (1.0, -1)]
    for i, Bi in enumerate(B):
        if Bi >= 1:
            candidates.append((Bi + eps, sides[i]))
    for D, side in candidates:
        T = cost_general(a, sides, D, side, v, cost)
        if math.isinf(T):
            return math.inf
        worst = max(worst, T * (1 - v) / D)
    return worst


def penalized_sup_ratio(a, sides, v, cost):
    """Like full_sup_ratio but returns a finite penalty that grows with the
    number of adversary targets the strategy never finds, so the optimizer has
    a slope to follow out of infeasible regions."""
    t = landing_times(a)
    B = [ai - v * ti for ai, ti in zip(a, t)]
    candidates = [(1.0, +1), (1.0, -1)]
    for i, Bi in enumerate(B):
        if Bi >= 1:
            candidates.append((Bi + 1e-9, sides[i]))
    worst, unfound = 0.0, 0
    for D, side in candidates:
        T = cost_general(a, sides, D, side, v, cost)
        if math.isinf(T):
            unfound += 1
        else:
            worst = max(worst, T * (1 - v) / D)
    return worst + 1e4 * unfound


def cost_general(a, sides, D, side, v, which):
    """Discovery or capture time for a strategy with explicit side pattern."""
    t = landing_times(a)
    S = 0.0
    for i, ai in enumerate(a):
        S += ai
        if sides[i] == side and D + v * t[i] <= ai:
            if which is discovery_time:
                return t[i]
            return (2 * S - D) / (1 + v)
    return math.inf


def alternating_sides(n):
    return [(-1) ** i for i in range(n)]


def question_1(v_list=(0.0, 0.2, 0.5, 0.8), n=80):
    print("Q1: geometric alternating strategy, sup over ALL D >= 1 vs asymptotic formula")
    for v in v_list:
        for name, r, closed, cost in (
            ("discovery", r_disc_opt(v), cr_disc_opt(v), discovery_time),
            ("capture", r_cap_opt(v), cr_cap_opt(v), capture_time),
        ):
            best = math.inf
            best_c = None
            # Scale c so that some sortie's reach lands exactly on 1 (or a bit above).
            for c in np.geomspace(0.05, 5, 400):
                a = [c * r**i for i in range(n)]
                s = full_sup_ratio(a, alternating_sides(n), v, cost)
                if s < best:
                    best, best_c = s, c
            flag = "OK" if best <= closed * (1 + 1e-6) else "EXCEEDS"
            print(f"  v={v:.1f} {name:9s}: min over scale of full sup = {best:.6f} at c={best_c:.4f}; "
                  f"asymptotic = {closed:.6f}  [{flag}]")


def periodic_strategy(pattern, lengths, r, periods):
    a, sides = [], []
    for k in range(periods):
        for s, L in zip(pattern, lengths):
            a.append(L * r**k)
            sides.append(s)
    return a, sides


def optimize_pattern(pattern, v, cost, periods=25, restarts=12, seed=0):
    rng = np.random.default_rng(seed)
    p = len(pattern)
    lo_r = (1 + v) / (1 - v)

    def objective(x):
        lengths = np.exp(x[:p])
        r = lo_r + np.exp(x[p])
        a, sides = periodic_strategy(pattern, lengths, r, periods)
        return penalized_sup_ratio(a, sides, v, cost)

    # Initialize near the alternating geometric optimum embedded in the pattern:
    # lengths grow geometrically within the period and the period ratio is r0^p.
    r0 = r_disc_opt(v) if cost is discovery_time else r_cap_opt(v)
    best = (math.inf, None)
    for k in range(restarts):
        base = np.array([j * np.log(r0) for j in range(p)])
        noise = rng.normal(0, 0.3 + 0.1 * k, p)
        x0 = np.concatenate([base + noise, [np.log(max(r0**p - lo_r, 1e-3)) + rng.normal(0, 0.1)]])
        res = minimize(objective, x0, method="Nelder-Mead",
                       options={"xatol": 1e-8, "fatol": 1e-10, "maxiter": 20000})
        if res.fun < best[0]:
            best = (res.fun, res.x)
    x = best[1]
    return best[0], np.exp(x[:p]), lo_r + np.exp(x[p])


def question_2(v_list=(0.0, 0.5)):
    print("\nQ2: best periodic strategy per side pattern vs alternating optimum")
    patterns = {
        "+-": [1, -1],
        "++-": [1, 1, -1],
        "++--": [1, 1, -1, -1],
        "+++-": [1, 1, 1, -1],
        "++-+--": [1, 1, -1, 1, -1, -1],
    }
    for v in v_list:
        for name, closed, cost in (("discovery", cr_disc_opt(v), discovery_time),
                                   ("capture", cr_cap_opt(v), capture_time)):
            print(f"  v={v:.1f} {name}: alternating optimum {closed:.6f}")
            for label, pat in patterns.items():
                val, lengths, r = optimize_pattern(pat, v, cost)
                print(f"     pattern {label:7s}: best {val:.6f}   r_period={r:.4f}   "
                      f"lengths={np.array2string(lengths / lengths.max(), precision=4)}")


if __name__ == "__main__":
    question_1()
    question_2()
