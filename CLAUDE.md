# Discovery and Capture on the Line — Project Guide

## Project Overview

Academic research paper on **landing-only linear search for an escaping target**. A unit-speed flying searcher starts at the origin of the line. A target starts at unknown distance $D \ge 1$ on an unknown side and moves away from the origin at constant speed $v < 1$. The searcher is "forward blind": it only detects the target when it *lands*, and only if the target lies between the origin and the landing point. We study the competitive ratio (against the clairvoyant time $D/(1-v)$) of two objectives, **discovery** (stop at the first detecting landing) and **capture** (then go meet the target), across information regimes: $v$ known or unknown, $D$ known or unknown.

**Authors (working list)**: Jared Coleman, Evangelos Kranakis, Danny Krizanc, Oscar Morales-Ponce. Dmitry Ivanov was a coauthor on the related escaping-target papers; adjust the author list as needed.

## Repository Layout

```
discovery_capture/
├── CLAUDE.md
├── pyproject.toml, uv.lock, .python-version   # uv-managed Python env (.venv/ at root)
├── references/                                # input drafts; read, do not edit
│   ├── landing_only_mobile_line_search.pdf    # anonymous full draft: model, four regimes, conjecture
│   └── dis-cap-line.pdf                       # Evangelos' draft notes (Sept 30, 2026): static case, partial lower bounds
└── paper_discovery_capture/                   # ← OUR PAPER (active)
    ├── main.tex                               # LaTeX source (LLNCS class, apxproof)
    ├── refs.bib                               # Bibliography
    ├── llncs.cls, splncs04.bst                # Class and bib style
    ├── zip.py                                 # arXiv / camera-ready archive builder (from sar_plane)
    ├── code/                                  # Simulator, Wolfram verification scripts, figures
    └── notes/                                 # Tracked markdown notes (status, long derivations)
```

- `paper_discovery_capture/` is the paper. All new content goes there. It is a plain subdirectory for now; split it into its own GitHub repo and add it as a submodule (as in `../sar_plane`) once there is something to share with coauthors.
- `references/` holds the two source drafts. Treat them as input: they disagree in places (see below), and neither proves its lower bounds.
- `notes/` at the repo root is gitignored scratch space. Notes meant to persist go in `paper_discovery_capture/notes/`.
- The companion planar paper lives in `../sar_plane` and uses the same conventions; the related escaping-target papers are in `../paper_1D-MobileSR` and `../multi_speed_cow`.

## Current Status

Read `paper_discovery_capture/notes/model_and_results.md` first. In short:

- **Verified** (brute-force simulator plus Wolfram): the geometric-strategy competitive ratios and their optimizers for the stationary case and the known-speed case, for both discovery and capture. The formulas in the anonymous draft are correct.
- **Wrong**: Evangelos' mobile-target formulas for discovery and capture (Table 1, Sections 2.3.2 and 2.3.3 of `dis-cap-line.pdf`) do not match the model for $v > 0$; they agree only at $v = 0$. He flagged the capture formula himself as unverified.
- **Unproved**: every lower bound. The draft reduces them to "critical recurrences" and asserts the result. Evangelos' notes complete the lower bound only for classical linear search (static and mobile) and stop midway for discovery and capture.
- **Upper bound only**: the unknown-speed, known-distance regime, where $a_i = A^{b^i}$ with $b = 3/2$ gives $O((1-v)^{-23/4})$. The matching lower exponent is a conjecture.
- `main.tex` is a skeleton: model, results table, the known-speed theorems with their one-line calculus proofs, and TODO markers (as `\JC{}` comments) everywhere else.

## Writing the Paper

- LLNCS document class with `apxproof` (`\newtheoremrep` for theorem and lemma, so proofs can be deferred to the appendix). Build with:
  ```
  cd paper_discovery_capture && pdflatex main && bibtex main && pdflatex main && pdflatex main
  ```
- Author comment macros: `\JC{}` (Jared), `\EK{}` (Evangelos), `\DK{}` (Danny), `\OM{}` (Oscar).
- Notation macros: `\CR`, `\disc`, `\capt`, `\opt`.
- `llncs` already defines `conjecture` and `remark` environments; do not redefine them.
- Always recompile after edits and check `main.log` for undefined references or citations.

## Computational Tools

### Python (simulation, numerics, figures)
- Managed with **uv** at the repo root. Run scripts with `uv run python paper_discovery_capture/code/<script>.py`.
- `code/simulate.py` is an exact simulator for any landing sequence: it computes landing times, reaches $B_i(v)$, discovery and capture times, and the worst-case ratio by placing the target just beyond each reach. Use it to sanity-check every new closed form before writing it in the paper. `--sweep` numerically optimizes the geometric ratio.
- Figures: matplotlib, publication quality, saved as PDF in `code/`.

### Wolfram Language (symbolic verification)
- `wolframscript -file <absolute path>.wls` (relative paths have failed from some working directories; use absolute paths).
- `code/verify_known_speed.wls` checks the known-speed theorems and documents the discrepancy with Evangelos' formulas.
- `code/verify_unknown_speed_exponent.wls` checks the $\alpha(b) = b^3/(b-1) - 1$ exponent and $b = 3/2$.
- Name new scripts `verify_<claim>.wls`, one per lemma or theorem, and keep them self-contained.

## Key Mathematical Objects

- Landing sequence $a_i > 0$ at $x_i = (-1)^i a_i$; $S_i = \sum_{j \le i} a_j$; landing time $t_i = 2S_{i-1} + a_i$.
- Reach $B_i(v) = a_i - v t_i = (1-v)a_i - 2vS_{i-1}$: landing $i$ discovers a target on its side iff $D \le B_i(v)$.
- Feasibility for geometric $a_i = r^i$: $r > (1+v)/(1-v)$.
- Benchmark $T^* = D/(1-v)$. Capture time after discovery at $i$: $(2S_i - D)/(1+v)$.
- Known-speed optima: discovery $r^* = (1+2v+\sqrt{5+4v})/(2(1-v))$; capture $r^* = 3(1+v)/(2(1-v))$. Both ratios are $\sim 27/(1-v)^2$ as $v \to 1^-$.
- Unknown-speed thresholds: $v_i = (a_i - 1)/(a_i + 2S_{i-1})$, $\delta_i = 1 - v_i \sim 2a_{i-1}/a_i$; the transition index $i(v) = \max\{i : v_i < v\}$ and the adverse sign cost two extra rounds.

## Workflow Conventions

- When making a mathematical claim, verify it: numerically with `simulate.py` and symbolically with a `verify_*.wls` script when feasible.
- Keep scripts self-contained and commented so coauthors can reproduce results.
- Ancillary derivations that are verified but too long for the paper go in `paper_discovery_capture/notes/` as markdown, referenced from a footnote.
- Commit messages should reference the section or theorem affected.
- Proof-writing style (carried over from `../sar_plane`): no "Step N:" labels, no "clearly" or "obviously", align environments with marginal comments for multi-line derivations, tight but complete proofs, don't restate hypotheses already in the section preamble.
- Global writing style: no em-dashes, no hard-wrapped sentences, no symbol shorthand in prose.
