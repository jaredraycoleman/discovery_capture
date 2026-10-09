# Landing-only discovery and capture: model, results, and status

This note summarizes the two source drafts in `references/` and records what has been checked, where they disagree, and what remains open. Update it as claims get proved or refuted.

## Sources

- `references/landing_only_mobile_line_search.pdf` ("the draft"): an anonymous, complete write-up of four information regimes. Clean model, closed forms, and a conjecture. Its lower bounds are reduced to "critical recurrences" but never actually proved.
- `references/dis-cap-line.pdf` ("EK's notes", dated September 30, 2026): Evangelos' draft notes. Introduces the "forward blind" airplane metaphor, treats the stationary target carefully (upper bounds and partial lower bounds), and sketches the mobile target. EK's own footnote says the mobile capture formula "was found by an AI but I did not even try to verify it."

## Model (common to both)

- Searcher starts at the origin, unit speed, lands alternately at $x_i = (-1)^i a_i$, returning through the origin between landings.
- Target starts at $\sigma D$ with $D \ge 1$ and moves away from the origin at speed $v < 1$.
- Landing $i$ happens at time $t_i = 2S_{i-1} + a_i$ where $S_i = \sum_{j \le i} a_j$.
- Landing $i$ discovers a target on its side iff $D + v t_i \le a_i$, i.e. $D \le B_i(v) := a_i - v t_i = (1-v)a_i - 2vS_{i-1}$.
- Benchmark: $T^*(D, v) = D/(1-v)$ for both discovery and capture.
- Capture after discovery at landing $i$: searcher reverses, closes at speed $1+v$, total time $(2S_i - D)/(1+v)$.

EK's notes write the same model with $a_i = a^i$, $T_k = 2(a^k - 1)/(a-1)$ for the time at the origin at the start of round $k$, and the miss condition $a^k < (d + vT_k)/(1-v)$. These are equivalent.

## Results and verification status

| Regime | Claim | Source | Checked |
|---|---|---|---|
| $v=0$, discovery | geometric $r$ gives $r^2(r+1)/(r-1)$; optimum $r = \varphi$, CR $= (11+5\sqrt5)/2 \approx 11.09$ | both | simulator, Wolfram |
| $v=0$, capture | geometric $r$ gives $2r^3/(r-1) - 1$; optimum $r = 3/2$, CR $= 25/2$ | both | simulator, Wolfram |
| $v$ known, $D$ unknown, discovery | $\mathrm{CR}(r,v) = (1-v)\,r^2(r+1)/((1-v)r-(1+v))$; $r^* = (1+2v+\sqrt{5+4v})/(2(1-v))$; CR$^*$ = Eq. (7) of the draft | draft | simulator, Wolfram |
| $v$ known, $D$ unknown, capture | $\mathrm{CR}(r,v) = \frac{1-v}{1+v}\big(2r^3/((1-v)r-(1+v)) - 1\big)$; $r^* = 3(1+v)/(2(1-v))$; CR$^* = (2v+1)(v+5)^2/(2(1-v)^2(1+v))$ | draft | simulator, Wolfram |
| $D$ known, $v$ unknown, discovery and capture | $a_i = A^{b^i}$ gives $O((1-v)^{-\alpha(b)})$, $\alpha(b) = b^3/(b-1) - 1$, minimized at $b = 3/2$ with $\alpha = 23/4$ | draft | exponent algebra in Wolfram; asymptotics not yet checked numerically at the exponent level (convergence is slow, see below) |
| Lower bounds, $v$ known (incl. $v=0$), alternating strategies | matching lower bounds via Gal's theorem in the reach parametrization | this repo (main.tex Section 5) | Wolfram (`verify_lower_bound.wls`) |
| Lower bounds, $v$ known, arbitrary side patterns | only the weaker universal bounds $(3+v+2\sqrt{2(1+v)})/(1-v)$ and $8/(1-v) - (1-v)/(1+v)$ | this repo | Wolfram; tight version is a conjecture |
| $23/4$ universal lower exponent | Conjectures 8.1 and 8.2 of the draft | draft | open |

Scripts: `code/simulate.py` (exact brute force for any landing sequence), `code/explore_strategies.py` (full-supremum check of the geometric strategy, and optimization over non-alternating periodic side patterns), `code/verify_known_speed.wls`, `code/verify_lower_bound.wls`, `code/verify_unknown_speed_exponent.wls`.

### Model clarification: sorties must return to the origin

Neither draft says how often the searcher may land. If landings are free and unrestricted, the searcher can land at every point of its flight and the model collapses to classical linear search (CR 9 at $v=0$, $1+8(1+v)/(1-v)^2$ in general), which is *below* the drafts' "lower bounds". Both drafts in fact analyze sorties that fly out, land once, and return to the origin. Section 2 of main.tex now states this explicitly: a strategy is a sequence of sorties from the origin, one landing each. This needs sign-off from the coauthors.

### Lower bounds (Section 5 of main.tex): what is proved and how

- **Reach parametrization.** With $q=(1+v)/(1-v)$ and $z_i = B_i(v)$: $S_i = qS_{i-1} + z_i/(1-v)$, so $S_i$, $a_i$, $t_i$ are positive linear forms in the reaches. This makes the adversary ratios $(1-v)t_{i+2}/z_i$ (discovery) and $\frac{1-v}{1+v}(2S_{i+2}/z_i-1)$ (capture) functionals of exactly the type covered by Gal's theorem (continuous, homogeneous, quasi-convex by the mediant inequality, shift-monotone). Working with sortie lengths directly fails because the reach $B_i = (1-v)a_i - 2vS_{i-1}$ has mixed signs.
- **Gal's theorem** is cited in the form of Theorem 3 of Angelopoulos, Dürr, Jin (arXiv 1810.08109), which attributes it to Gal (1980) and Schuierer (2001). Their printed condition 5 reads $F_{i+1}(X) \ge F_i(X^{k+1})$, almost certainly a typo for $X^{+1}$. Check the original before submission.
- **Geometric reach sequences** $z_j=\alpha^j$ give $S_i = (\alpha^{i+1}-q^{i+1})/((1-v)(\alpha-q))$. For $\alpha>q$ the functionals converge (from below) to the geometric-strategy formulas of Section 4; for $\alpha\le q$ they diverge. So the lower bound equals the Section 4 optimum.
- **Class covered:** alternating strategies that are *eventually monotone* (from some index on, every reach is at least 1 and at least every earlier reach on the same side). Useless sorties cannot simply be deleted without breaking alternation, which is why the class is stated this way.
- **Arbitrary side patterns** are open. Deleting useless sorties is WLOG for general strategies, but then the pattern is arbitrary and the three-term functional has unbounded lookahead. Using the "next landing" instead of "next same-side landing" gives valid universal bounds (Theorem on universal lower bounds), which are weak. Numerics (`explore_strategies.py`, Q2) show every periodic non-alternating pattern optimizing back to the alternating optimum at $v\in\{0,0.5\}$, so we conjecture the tight bounds hold universally.
- **Exact tightness of the upper bounds** (full supremum over $D\ge 1$, not just asymptotic) holds for $a_i = c\,r^{*i}$: confirmed numerically for $v\in\{0,0.2,0.5,0.8\}$ (`explore_strategies.py`, Q1) and sketched in a remark in main.tex.

### Discrepancy: EK's mobile-target formulas

EK's Table 1 and Sections 2.3.2 and 2.3.3 give, for geometric ratio $a$,

- discovery: $a^2(a+1-2v)\,/\,((1-v)(a-1-2v))$, optimum at $a = (1+4v+2\sqrt{5+8v})/\ldots$ with CR $(\sqrt{5+8v}-1)(\sqrt{5+8v}+3)^3/(16(1-v))$;
- capture: $\frac{1}{1+v}\big(-1 + 2a^2(a - v - v^2)/((1-v)a-(1+v))\big)$.

Both agree with the draft at $v = 0$ but not for $v > 0$. The brute-force simulator agrees with the draft, not with EK's notes (for example $v = 1/2$, $r = 5$: simulator and draft give discovery 75 and capture 83; EK's formulas give 83.3 and 141). The source of the error in Section 2.3.2 appears to be the term $a^{k+2}/(1-v)$ in the numerator of $\mathrm{CR}_{dis}(v)$: the final flight of length $a^{k+2}$ takes time $a^{k+2}$, not $a^{k+2}/(1-v)$. Section 2.3.3 inherits a similar issue. The static-target sections of EK's notes are fine.

Also note that EK's static lower-bound arguments in Sections 2.2.2 (discovery) and 2.2.3 (capture) stop at the recurrence inequalities $s_{i+1} \ge 3(s_i+1)/(\alpha - s_i)$ and $s_{i+1} > (s_i+1)/(\alpha - s_i/2)$ and never finish the contradiction. The linear-search case (Section 2.2.1 and 2.4.1) is complete and is the template to follow.

### What the draft's lower bounds actually establish

The draft says the lower bound "can be phrased as a sequence lemma": the adversary places the target just beyond $B_{i-2}(v)$, giving $\mathrm{CR} \ge (1-v)\sup_i (S_i + S_{i-1})/((1-v)S_{i-2} - (1+v)S_{i-3})$, and then asserts that the sharp constant of this functional equals the geometric minimum because the "critical recurrence" has the same characteristic equation. That last step is the whole difficulty (it is the content of Gal's theorem on functionals of sequences, or of the monotone $s_i$ argument in EK's notes) and is not proved anywhere in either document. The lower bounds for all four of the known-$v$ and $v = 0$ cases should be considered open until written out.

### Unknown-speed asymptotics

`verify_unknown_speed_exponent.wls` confirms the exponent algebra: $\delta_i a_{i+2} = \Theta(\delta_i^{-\alpha(b)})$ with $\alpha(b) = b^3/(b-1) - 1$, and $b = 3/2$ is the unique minimizer. The concrete instance $A = 2$, $b = 3/2$ shows the local exponent $\log(\delta_i a_{i+2})/\log(1/\delta_i)$ is still far from $23/4$ for $i \le 6$ (the lower-order terms in $\delta_i$ matter because $A^{b^i}$ grows slowly at first), so any numerical illustration in the paper will need large $i$ or a cleverer normalization.

## Open problems (from both drafts)

1. Extend the known-speed lower bounds from alternating strategies to arbitrary side patterns (conjecture in Section 5.5 of main.tex). The $s_i$ monotone-sequence technique of EK's notes cannot close even the alternating case, since the functionals involve three consecutive sorties; Gal's theorem does.
2. Prove or refute the conjectured $23/4$ lower exponent for arbitrary strategies with unknown speed.
3. Nonstationary doubly-exponential schedules (varying $b_i$) to improve constants while keeping the exponent.
4. Randomized strategies (random initial side, phase, or threshold schedule).
5. Positive landing time or turn cost; connection to Demaine, Fekete, and Gal.
6. EK's Section 2.5 raises other knowledge models (for example $v$ known and $D$ known up to sign, or neither known) that the draft does not treat.
