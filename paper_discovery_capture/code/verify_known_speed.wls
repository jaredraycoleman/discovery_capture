(* Verify the known-speed, unknown-distance results (Theorems on discovery and
   capture with geometric excursions a_i = r^i) from
   references/landing_only_mobile_line_search.pdf, and compare with the
   formulas written in references/dis-cap-line.pdf (EK's draft notes). *)

assum = {0 <= v < 1, r > (1 + v)/(1 - v)};

(* ---- Asymptotic competitive ratios of the geometric strategy ---------- *)
(* Derived directly from the model: worst target D just beyond B_{i-2}(v). *)
Si[i_] := (r^(i + 1) - 1)/(r - 1);
ti[i_] := 2 Si[i - 1] + r^i;
Bi[i_] := r^i - v ti[i];

crDiscExact[i_] := (1 - v) ti[i]/Bi[i - 2];
crCapExact[i_]  := (1 - v)/(1 + v) (2 Si[i]/Bi[i - 2] - 1);

crDisc = (1 - v) r^2 (r + 1)/((1 - v) r - (1 + v));           (* Eq. (5) *)
crCap  = (1 - v)/(1 + v) (2 r^3/((1 - v) r - (1 + v)) - 1);   (* Eq. (12) *)

Print["Limit of exact discovery ratio equals Eq. (5): ",
  FullSimplify[Limit[crDiscExact[i], i -> Infinity, Assumptions -> assum] == crDisc, assum]];
Print["Limit of exact capture ratio equals Eq. (12): ",
  FullSimplify[Limit[crCapExact[i], i -> Infinity, Assumptions -> assum] == crCap, assum]];

(* ---- Discovery optimum (Theorem 3.1) --------------------------------- *)
rDisc = (1 + 2 v + Sqrt[5 + 4 v])/(2 (1 - v));                 (* Eq. (6) *)
crDiscOpt = (Sqrt[5 + 4 v] + 3) (2 v + Sqrt[5 + 4 v] + 1)^2/(4 (1 - v)^2 (Sqrt[5 + 4 v] - 1)); (* Eq. (7) *)

Print["Discovery: numerator of d/dr CR factors as ", Factor[Numerator[Together[D[crDisc, r]]]],
  "; stationarity <=> (1-v) r^2 - (1+2v) r - (1+v) = 0: ",
  FullSimplify[Numerator[Together[D[crDisc, r]]] == 2 r (1 - v) ((1 - v) r^2 - (1 + 2 v) r - (1 + v))]];
Print["Discovery: r* satisfies it: ", FullSimplify[((1 - v) rDisc^2 - (1 + 2 v) rDisc - (1 + v)) == 0, assum]];
Print["Discovery: r* is feasible (r* > (1+v)/(1-v)): ", FullSimplify[rDisc > (1 + v)/(1 - v), assum]];
Print["Discovery: CR at r* equals Eq. (7): ", FullSimplify[(crDisc /. r -> rDisc) == crDiscOpt, assum]];
Print["Discovery: second derivative positive at r*: ", FullSimplify[(D[crDisc, {r, 2}] /. r -> rDisc) > 0, assum]];
Print["Discovery: CR*(0) = (11 + 5 Sqrt[5])/2: ", FullSimplify[(crDiscOpt /. v -> 0) == (11 + 5 Sqrt[5])/2]];
Print["Discovery: (1-v)^2 CR*(v) -> 27 as v -> 1: ", Limit[(1 - v)^2 crDiscOpt, v -> 1]];

(* ---- Capture optimum (Theorem 4.1) ----------------------------------- *)
rCap = 3 (1 + v)/(2 (1 - v));                                   (* Eq. (13) *)
crCapOpt = (2 v + 1) (v + 5)^2/(2 (1 - v)^2 (1 + v));          (* Eq. (14) *)

Print["Capture: derivative vanishes at r*: ", FullSimplify[(D[crCap, r] /. r -> rCap) == 0, assum]];
Print["Capture: r* is feasible: ", FullSimplify[rCap > (1 + v)/(1 - v), assum]];
Print["Capture: CR at r* equals Eq. (14): ", FullSimplify[(crCap /. r -> rCap) == crCapOpt, assum]];
Print["Capture: alternative form 27(1+v)/(2(1-v)^2) - (1-v)/(1+v): ",
  FullSimplify[27 (1 + v)/(2 (1 - v)^2) - (1 - v)/(1 + v) == crCapOpt, assum]];
Print["Capture: second derivative positive at r*: ", FullSimplify[(D[crCap, {r, 2}] /. r -> rCap) > 0, assum]];
Print["Capture: CR*(0) = 25/2: ", FullSimplify[(crCapOpt /. v -> 0) == 25/2]];
Print["Capture: (1-v)^2 CR*(v) -> 27 as v -> 1: ", Limit[(1 - v)^2 crCapOpt, v -> 1]];

(* ---- Comparison with EK's draft notes (dis-cap-line.pdf) --------------- *)
crDiscEK = a^2 (a + 1 - 2 v)/((1 - v) (a - 1 - 2 v));                           (* Sec. 2.3.2 *)
crCapEK  = (-1 + 2 a^2 (a - v - v^2)/((1 - v) a - (1 + v)))/(1 + v);            (* Sec. 2.3.3 *)

Print["\nEK discovery formula equals Eq. (5) at v = 0: ", FullSimplify[(crDiscEK /. {v -> 0, a -> r}) == (crDisc /. v -> 0)]];
Print["EK capture formula equals Eq. (12) at v = 0: ", FullSimplify[(crCapEK /. {v -> 0, a -> r}) == (crCap /. v -> 0)]];
Print["EK discovery formula equals Eq. (5) for general v: ", FullSimplify[(crDiscEK /. a -> r) == crDisc, assum]];
Print["EK capture formula equals Eq. (12) for general v: ", FullSimplify[(crCapEK /. a -> r) == crCap, assum]];
Print["Numeric example, v = 1/2, r = 5: draft (5) = ", N[crDisc /. {v -> 1/2, r -> 5}],
  ", EK = ", N[crDiscEK /. {v -> 1/2, a -> 5}]];
Print["Numeric example, v = 1/2, r = 5: draft (12) = ", N[crCap /. {v -> 1/2, r -> 5}],
  ", EK = ", N[crCapEK /. {v -> 1/2, a -> 5}]];
