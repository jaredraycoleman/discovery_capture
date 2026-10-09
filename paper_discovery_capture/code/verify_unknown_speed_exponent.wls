(* Verify the exponent calculation for the doubly-exponential strategy
   a_i = A^(b^i) with unknown speed (Theorems 5.1 and 6.1 of
   references/landing_only_mobile_line_search.pdf). *)

alpha[b_] := b^3/(b - 1) - 1;

Print["alpha'(b) = b^2 (2b - 3)/(b - 1)^2: ",
  FullSimplify[D[alpha[b], b] == b^2 (2 b - 3)/(b - 1)^2, b > 1]];
Print["Unique critical point for b > 1: ", Solve[D[alpha[b], b] == 0 && b > 1, b]];
Print["alpha(3/2) = 23/4: ", alpha[3/2] == 23/4];
Print["alpha''(3/2) > 0: ", D[alpha[b], {b, 2}] /. b -> 3/2];

(* Exponent bookkeeping: delta_i ~ 2 a_{i-1}/a_i and cost ~ delta_i a_{i+2}.
   Write everything as a power of A^(b^(i-1)). *)
ai[i_] := A^(b^i);
deltaExp = Log[A, ai[i - 1]/ai[i]] // PowerExpand;   (* exponent of delta_i, up to the constant 2 *)
costExp  = Log[A, ai[i - 1]/ai[i] ai[i + 2]] // PowerExpand;
ratio = FullSimplify[costExp/(-deltaExp)];           (* cost = delta^(-ratio) *)
Print["cost ~ delta^(-", ratio, "), i.e. alpha(b): ", FullSimplify[ratio == alpha[b]]];

(* Exact thresholds for a concrete instance, to sanity check the asymptotics. *)
Aval = 2; bval = 3/2; n = 8;
aList = Table[N[Aval^(bval^i), 30], {i, 0, n}];
SList = Accumulate[aList];
tList = Table[2 If[i == 1, 0, SList[[i - 1]]] + aList[[i]], {i, 1, n + 1}];
deltaList = Table[(1 + 2 If[i == 1, 0, SList[[i - 1]]])/(aList[[i]] + 2 If[i == 1, 0, SList[[i - 1]]]), {i, 1, n + 1}];
Print["\nA = 2, b = 3/2: delta_i (exact) vs 2 a_{i-1}/a_i:"];
Do[Print["  i = ", i - 1, ": ", N[deltaList[[i]], 6], "  vs  ", N[2 aList[[i - 1]]/aList[[i]], 6]], {i, 2, n + 1}];
Print["Local exponent log(delta_i a_{i+2}) / log(1/delta_i) -> 23/4 = 5.75:"];
Do[Print["  i = ", i - 1, ": ", N[Log[deltaList[[i]] aList[[i + 2]]]/Log[1/deltaList[[i]]], 6]], {i, 3, n - 1}];
