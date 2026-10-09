(* Verification for the lower-bound section (known speed, alternating strategies).

   An alternating strategy with sortie lengths a_i is re-parametrized by its
   reaches z_i = B_i(v) = (1-v) a_i - 2 v S_{i-1}. With q = (1+v)/(1-v):
     S_i = (q S_{i-1} + z_i)/(1-v),  so  S_i = (1/(1-v)) Sum_{j<=i} q^(i-j) z_j,
     a_i = S_i - S_{i-1},  t_i = S_i + S_{i-1}.
   The adversary places the target just beyond z_i; it is found no earlier than
   landing i+2. The lower-bound functionals are
     Fdisc_i(Z) = (1-v) t_{i+2} / z_i,
     Fcap_i(Z)  = (1-v)/(1+v) (2 S_{i+2}/z_i - 1).
   Gal's theorem reduces sup_i F_i(Z) to the geometric sequence z_j = alpha^j. *)

assum = {0 <= v < 1};
q = (1 + v)/(1 - v);

(* ---- 1. Reach parametrization identities (symbolic, generic i) ---------- *)
(* Take a generic strategy a_0..a_4 and check z -> S -> a round trip. *)
aa = {a0, a1, a2, a3, a4};
SS = Accumulate[aa];
Sprev[i_] := If[i == 0, 0, SS[[i]]];
tt = Table[2 Sprev[i] + aa[[i + 1]], {i, 0, 4}];
zz = Table[aa[[i + 1]] - v tt[[i + 1]], {i, 0, 4}];
SfromZ = Table[(1/(1 - v)) Sum[q^(i - j) zz[[j + 1]], {j, 0, i}], {i, 0, 4}];
Print["S_i recovered from reaches: ", FullSimplify[SfromZ == SS]];
Print["t_i = S_i + S_{i-1}: ", FullSimplify[tt == Table[SS[[i + 1]] + Sprev[i], {i, 0, 4}]]];
Print["z_i = (1-v) a_i - 2 v S_{i-1}: ", FullSimplify[zz == Table[(1 - v) aa[[i + 1]] - 2 v Sprev[i], {i, 0, 4}]]];

(* ---- 2. Functionals on the geometric reach sequence z_j = alpha^j -------- *)
Sgeo[i_] := (1/(1 - v)) Sum[q^(i - j) alpha^j, {j, 0, i}];
Sclosed[i_] := (alpha^(i + 1) - q^(i + 1))/((1 - v) (alpha - q));
Print["Closed form of S_i(G_alpha): ", FullSimplify[Sgeo[3] == Sclosed[3]]];

Fdisc[i_] := (1 - v) (Sclosed[i + 2] + Sclosed[i + 1])/alpha^i;
Fcap[i_]  := (1 - v)/(1 + v) (2 Sclosed[i + 2]/alpha^i - 1);

fdisc = (1 - v) alpha^2 (alpha + 1)/((1 - v) alpha - (1 + v));       (* Eq. (5) with r = alpha *)
fcap  = (1 - v)/(1 + v) (2 alpha^3/((1 - v) alpha - (1 + v)) - 1);  (* Eq. (12) *)

assumGeo = Join[assum, {alpha > q}];
Print["lim_i Fdisc_i(G_alpha) = Eq. (5) for alpha > q: ",
  FullSimplify[Limit[Fdisc[i], i -> Infinity, Assumptions -> assumGeo] == fdisc, assumGeo]];
Print["lim_i Fcap_i(G_alpha) = Eq. (12) for alpha > q: ",
  FullSimplify[Limit[Fcap[i], i -> Infinity, Assumptions -> assumGeo] == fcap, assumGeo]];

(* For 1 < alpha <= q the functionals diverge (q^i terms dominate). *)
assumSlow = Join[assum, {1 < alpha < q}];
Print["lim_i Fdisc_i(G_alpha) = Infinity for 1 < alpha < q: ",
  Limit[Fdisc[i], i -> Infinity, Assumptions -> assumSlow]];
Print["lim_i Fcap_i(G_alpha) = Infinity for 1 < alpha < q: ",
  Limit[Fcap[i], i -> Infinity, Assumptions -> assumSlow]];
(* At alpha = q the closed form degenerates; use the sum directly: S_i = (i+1) q^i/(1-v). *)
SatQ[i_] := (i + 1) q^i/(1 - v);
Print["S_i(G_q) = (i+1) q^i/(1-v): ", FullSimplify[(Sgeo[4] /. alpha -> q) == SatQ[4]]];
FdiscAtQ[i_] := (1 - v) (SatQ[i + 2] + SatQ[i + 1])/q^i;
Print["Fdisc_i(G_q) -> Infinity (grows linearly in i): ",
  Limit[FdiscAtQ[i], i -> Infinity, Assumptions -> assum]];

(* ---- 3. Finite i stays below the limit, so sup_i = lim_i -------------- *)
Print["Fdisc_i(G_alpha) - fdisc < 0 for alpha > q (i = 3, 10): ",
  FullSimplify[(Fdisc[3] - fdisc < 0) && (Fdisc[10] - fdisc < 0), assumGeo]];
Print["Fcap_i(G_alpha) - fcap < 0 for alpha > q (i = 3, 10): ",
  FullSimplify[(Fcap[3] - fcap < 0) && (Fcap[10] - fcap < 0), assumGeo]];
Print["Fdisc_i(G_alpha) increasing in i (i=3 -> 4), alpha > q: ",
  FullSimplify[Fdisc[4] - Fdisc[3] > 0, assumGeo]];

(* ---- 4. inf over alpha > q equals the known-speed optima --------------- *)
rDisc = (1 + 2 v + Sqrt[5 + 4 v])/(2 (1 - v));
rCap = 3 (1 + v)/(2 (1 - v));
crDiscOpt = (Sqrt[5 + 4 v] + 3) (2 v + Sqrt[5 + 4 v] + 1)^2/(4 (1 - v)^2 (Sqrt[5 + 4 v] - 1));
crCapOpt = (2 v + 1) (v + 5)^2/(2 (1 - v)^2 (1 + v));
(* f -> Infinity at both ends of (q, Infinity) and has a unique critical point there,
   so that critical point is the global minimizer. *)
Print["Discovery: f(alpha) -> Infinity as alpha -> q+: ",
  Limit[fdisc, alpha -> q, Direction -> "FromAbove", Assumptions -> assum]];
Print["Discovery: f(alpha) -> Infinity as alpha -> Infinity: ", Limit[fdisc, alpha -> Infinity, Assumptions -> assum]];
Print["Discovery: critical points of f on alpha > q: ",
  Reduce[D[fdisc, alpha] == 0 && alpha > q && 0 <= v < 1, alpha, Reals]];
Print["Capture: f(alpha) -> Infinity as alpha -> q+: ",
  Limit[fcap, alpha -> q, Direction -> "FromAbove", Assumptions -> assum]];
Print["Capture: f(alpha) -> Infinity as alpha -> Infinity: ", Limit[fcap, alpha -> Infinity, Assumptions -> assum]];
Print["Capture: critical points of f on alpha > q: ",
  Reduce[D[fcap, alpha] == 0 && alpha > q && 0 <= v < 1, alpha, Reals]];
Print["Numeric grid check, min over alpha in (q, 50 q] of f - CR* >= 0 for v in {0, .3, .7} (discovery, capture): ",
  Table[With[{qq = q /. v -> vv},
    {N[Min[Table[fdisc /. {v -> vv, alpha -> qq (1 + x)}, {x, 1/1000, 49, 1/1000}]] - (crDiscOpt /. v -> vv), 6],
     N[Min[Table[fcap /. {v -> vv, alpha -> qq (1 + x)}, {x, 1/1000, 49, 1/1000}]] - (crCapOpt /. v -> vv), 6]}],
    {vv, {0, 3/10, 7/10}}]];

(* ---- 6. Universal (any side pattern) lower bounds ----------------------- *)
(* For an arbitrary useful strategy the target just beyond z_i is found no
   earlier than the NEXT landing, i+1, so the valid functionals are
     Udisc_i(Z) = (1-v) t_{i+1}/z_i = (1-v)(S_{i+1}+S_i)/z_i,
     Ucap_i(Z)  = (1-v)/(1+v) (2 S_{i+1}/z_i - 1).
   These satisfy Gal's conditions for any side pattern. *)
udisc = (1 - v) alpha (alpha + 1)/((1 - v) alpha - (1 + v));
ucap  = (1 - v)/(1 + v) (2 alpha^2/((1 - v) alpha - (1 + v)) - 1);
Print["
Universal discovery: lim_i Udisc_i(G_alpha): ",
  FullSimplify[Limit[(1 - v) (Sclosed[i + 1] + Sclosed[i])/alpha^i, i -> Infinity, Assumptions -> assumGeo] == udisc, assumGeo]];
Print["Universal capture: lim_i Ucap_i(G_alpha): ",
  FullSimplify[Limit[(1 - v)/(1 + v) (2 Sclosed[i + 1]/alpha^i - 1), i -> Infinity, Assumptions -> assumGeo] == ucap, assumGeo]];
alphaUdisc = (1 + v + Sqrt[2 (1 + v)])/(1 - v);
Print["Universal discovery minimizer alpha = (1+v+Sqrt[2(1+v)])/(1-v): ",
  Reduce[D[udisc, alpha] == 0 && alpha > q && 0 <= v < 1, alpha, Reals]];
uDiscOpt = FullSimplify[udisc /. alpha -> alphaUdisc, assum];
Print["Universal discovery bound: ", uDiscOpt, " = (3 + v + 2 Sqrt[2(1+v)])/(1-v): ",
  FullSimplify[uDiscOpt == (3 + v + 2 Sqrt[2 (1 + v)])/(1 - v), assum],
  ";  at v = 0: ", FullSimplify[uDiscOpt /. v -> 0], " = ", N[uDiscOpt /. v -> 0]];
Print["Universal capture minimizer alpha = 2(1+v)/(1-v): ",
  Reduce[D[ucap, alpha] == 0 && alpha > q && 0 <= v < 1, alpha, Reals]];
uCapOpt = FullSimplify[ucap /. alpha -> 2 q, assum];
Print["Universal capture bound: ", uCapOpt, " = 8/(1-v) - (1-v)/(1+v): ",
  FullSimplify[uCapOpt == 8/(1 - v) - (1 - v)/(1 + v), assum], ";  at v = 0: ", uCapOpt /. v -> 0];
Print["Universal bounds are below the alternating optima for 0 <= v < 1: ",
  FullSimplify[uDiscOpt < crDiscOpt && uCapOpt < crCapOpt, assum]];
Print["Discovery: equality at alpha = r*_disc: ", FullSimplify[(fdisc /. alpha -> rDisc) == crDiscOpt, assum]];
Print["Capture: equality at alpha = r*_cap: ", FullSimplify[(fcap /. alpha -> rCap) == crCapOpt, assum]];

(* ---- 5. Numeric spot check of the functional on the z-geometric sequence  *)
Print["\nNumeric: v = 1/2, alpha = r*_disc; Fdisc_i for i = 2..12:"];
Print[N[Table[Fdisc[i] /. {v -> 1/2, alpha -> rDisc /. v -> 1/2}, {i, 2, 12}], 8]];
Print["Target CR*_disc(1/2) = ", N[crDiscOpt /. v -> 1/2, 8]];
