/-!
# Module 3 — Propositions, proofs and indexing

Until now, Lean has checked that our programs fit together: that we never
append a number to a string, or forget a case of a `match`. This module shows
that Lean can check much more. It can check *statements* about our programs,
such as "this list has at least three entries", and it can refuse to run code
whose safety depends on a statement nobody has proved.

Goals:
* Understand that a proposition is a type, and a proof is a value of that type.
* Prove simple facts with `rfl`, `decide` and `simp`.
* Combine propositions with `∧`, `∨`, `→`, `¬` and `↔`, and prove them with
  the basic tactics `intro`, `exact`, `apply`, `constructor`, `cases`,
  `left`, `right` and `rw`.
* Index lists and arrays safely, by passing evidence that the index is in
  bounds, or by asking for an `Option` instead.

Read alongside: *Functional Programming in Lean*, the interlude "Propositions,
Proofs, and Indexing"
(https://lean-lang.org/functional_programming_in_lean/Interlude___-Propositions___-Proofs___-and-Indexing/).
Sections 3 and 4 go further into logic than the book, using
*Theorem Proving in Lean 4* (https://lean-lang.org/theorem_proving_in_lean4/).

Tip: in a proof written with `by`, put the cursor at the end of each line and
watch the *goal* change in the Infoview.
-/

namespace Propositions

/-! ## 1. Propositions and proofs

In module 1 we tested functions with `#guard`, which evaluates a `Bool` and
complains if it is `false`. A test checks one example; often we would like to
know more, for instance that `everyOther` never makes a list longer, whatever
the list. To say things like that, Lean has *propositions*: statements that
may be true or false, like `1 + 1 = 2`, `3 < 2` or "every list is shorter
than its doubled version".

A proposition is not a `Bool`, which Lean could simply compute. It is a
*type*, and the values of that type are its *proofs*: pieces of evidence that
the statement is true. A true proposition has proofs; a false one has none,
so nobody can write a value of that type. This idea, "propositions are types
and proofs are values", is the heart of Lean as a proof assistant, and it
means that everything you know about types carries over to proofs.

The type of propositions is `Prop`, just like `Type` is the type of types
such as `Nat`. A proof is given a name with `theorem`, which works like `def`:
the name, then the proposition (the type), then `:=` and the proof (the value).
When the proof doesn't need a name, `example` checks it without naming it.

The simplest evidence is `rfl`, short for *reflexivity*: it proves `a = b`
when Lean can compute both sides and finds the same value. It is the proof
version of `#guard`.

Read more: https://lean-lang.org/functional_programming_in_lean/Interlude___-Propositions___-Proofs___-and-Indexing/#propositions-and-proofs
-/

#check (2 + 2 = 4 : Prop)

theorem twoPlusTwo : 2 + 2 = 4 := rfl

example : "Lean" ++ "4" = "Lean4" := rfl

/-! A proposition can be false and still be a perfectly good type. It simply
has no values, so a "proof" by `rfl` is rejected. Uncomment the line below to
see the error: Lean computes both sides, and they are different.

    example : 2 + 2 = 5 := rfl
-/

/-- Prove that reversing `[3, 1, 2]` gives `[2, 1, 3]`. -/
theorem reverseFact : [3, 1, 2].reverse = [2, 1, 3] :=
  -- SOLUTION
  rfl
  -- END SOLUTION

/-- Prove that taking the first two characters of `"proof"` gives `"pr"`. -/
theorem takeFact : String.ofList ("proof".toList.take 2) = "pr" :=
  -- SOLUTION
  rfl
  -- END SOLUTION

/-! ## 2. Tactics

`rfl` is fine for equalities, but other propositions need other evidence, and
writing evidence by hand quickly becomes tedious. So Lean lets us *ask for* a
proof instead. After `by`, we write *tactics*: commands that build the proof
for us, step by step. The Infoview shows what is left to prove, the *goal*,
after each step.

Two tactics are enough for many facts about concrete values:

* `decide` works out whether the proposition is true, by computation, and
  produces the evidence. It only works when the question can be computed: it
  can check `17 * 3 < 52`, but it can't check a statement about *every*
  number.
* `simp` *simplifies* the goal with a large collection of known facts, such as
  `xs ++ [] = xs` or `n + 0 = n`, until it becomes obviously true. Unlike
  `decide`, it works with variables, so it can prove statements about every
  list or every number.

A third tactic, `grind`, is even more powerful, and the book mentions it.
This module sticks to tactics whose steps you can follow.

When a tactic fails, the error tells you why. If `decide` says the
proposition is false, it is false: check your statement. If `simp` "made no
progress", none of the facts it knows apply.

Read more: https://lean-lang.org/functional_programming_in_lean/Interlude___-Propositions___-Proofs___-and-Indexing/#tactics
-/

example : 17 * 3 < 52 := by decide

/-! A theorem can take arguments, like a function. This one holds for every
list `xs`, so `decide` can't test all the cases, but `simp` knows the fact. -/

theorem appendNil (xs : List Nat) : xs ++ [] = xs := by simp

/-- Prove it with `decide`. -/
theorem bigPower : 2 ^ 10 > 1000 := by
  -- SOLUTION
  decide
  -- END SOLUTION

/-- This one is about every number `n`, so `decide` can't do it. -/
theorem zeroTimes (n : Nat) : 0 * n + n = n := by
  -- SOLUTION
  simp
  -- END SOLUTION

/-! ## 3. Connectives

Facts rarely come alone. We want to say "this *and* that", "this *or* that",
"*if* this *then* that", or "this is *not* true". These *connectives* build
bigger propositions from smaller ones, and because propositions are types,
each connective is a way of building types:

* `p ∧ q` ("and", typed `\and`) is a structure with two fields: a proof of `p`
  and a proof of `q`. Its constructor is `And.intro`, and `⟨hp, hq⟩` works too.
* `p ∨ q` ("or", `\or`) is an inductive type with two constructors, like
  `Sum`: `Or.inl` takes a proof of `p` and `Or.inr` a proof of `q`.
* `p → q` ("implies") is a function type: a proof turns evidence for `p`
  into evidence for `q`.
* `True` has exactly one proof, `True.intro`, and `False` has none at all.
* `¬p` ("not", `\not`) is defined as `p → False`: if you had a proof of `p`,
  you could build something that can't exist.
* `p ↔ q` ("if and only if", `\iff`) is a pair of implications, one in each
  direction.

When the propositions involve concrete values, `decide` handles connectives
as well: -/

example : 3 < 5 ∧ (2 = 3 ∨ 4 ≠ 5) := by decide

/-! Proofs written as values look just like the programs of module 1: -/

theorem andSwap (p q : Prop) : p ∧ q → q ∧ p :=
  fun ⟨hp, hq⟩ => ⟨hq, hp⟩

/-! With variables instead of values, `decide` can't help, and we need tactics
that follow the shape of the connectives. Each one does one small step:

| If the goal or a hypothesis is...      | Use                                      |
|----------------------------------------|------------------------------------------|
| goal `p → q` (or `¬p`)                 | `intro hp` names the evidence for `p`    |
| you already have exactly the goal      | `exact h`                                |
| goal `q`, and `h : p → q`              | `apply h` leaves the goal `p`            |
| goal `p ∧ q` or `p ↔ q`                | `constructor` gives two goals            |
| hypothesis `h : p ∧ q`                 | `obtain ⟨hp, hq⟩ := h`                   |
| goal `p ∨ q`                           | `left` or `right`                        |
| hypothesis `h : p ∨ q`                 | `cases h with` one case for each side    |

When a tactic leaves several goals, `·` starts the proof of each one. And
`intro` can take a value apart while naming it, just like `fun`: `intro ⟨hp, hq⟩`
does the work of `intro h` followed by `obtain ⟨hp, hq⟩ := h`.

Here is the proof of `andSwap` again, with tactics. Move the cursor line by
line and watch the goal.

Read more: https://lean-lang.org/functional_programming_in_lean/Interlude___-Propositions___-Proofs___-and-Indexing/#connectives
and https://lean-lang.org/theorem_proving_in_lean4/Tactics/
-/

theorem andSwap' (p q : Prop) : p ∧ q → q ∧ p := by
  intro h
  obtain ⟨hp, hq⟩ := h
  constructor
  · exact hq
  · exact hp

theorem orSwap (p q : Prop) : p ∨ q → q ∨ p := by
  intro h
  cases h with
  | inl hp =>
    right
    exact hp
  | inr hq =>
    left
    exact hq

theorem noContradiction (p : Prop) : ¬(p ∧ ¬p) := by
  intro ⟨hp, hnp⟩
  exact hnp hp

/-- If `p` gives `q` and `q` gives `r`, then `p` gives `r`. -/
theorem chain (p q r : Prop) : (p → q) → (q → r) → p → r := by
  -- SOLUTION
  intro hpq hqr hp
  apply hqr
  apply hpq
  exact hp
  -- END SOLUTION

/-- Pull a proposition out of an "and", and put it into an "or". -/
theorem andToOr (p q : Prop) : p ∧ q → q ∨ p := by
  -- SOLUTION
  intro ⟨_, hq⟩
  left
  exact hq
  -- END SOLUTION

/-- If `p` gives `q` and `q` is false, then `p` is false. -/
theorem contrapositive (p q : Prop) : (p → q) → ¬q → ¬p := by
  -- SOLUTION
  intro hpq hnq hp
  exact hnq (hpq hp)
  -- END SOLUTION

/-- Both directions of `orSwap`. You may use `orSwap` itself. -/
theorem orComm (p q : Prop) : p ∨ q ↔ q ∨ p := by
  -- SOLUTION
  constructor
  · exact orSwap p q
  · exact orSwap q p
  -- END SOLUTION

/-- "And" distributes over "or". You will need `cases` on the `∨`. -/
theorem andOrDistrib (p q r : Prop) : p ∧ (q ∨ r) → (p ∧ q) ∨ (p ∧ r) := by
  -- SOLUTION
  intro ⟨hp, hqr⟩
  cases hqr with
  | inl hq => exact Or.inl ⟨hp, hq⟩
  | inr hr => exact Or.inr ⟨hp, hr⟩
  -- END SOLUTION

/-! ## 4. Rewriting with equalities

The connectives describe how propositions are built, but most interesting
statements about programs are equalities: `length (xs ++ ys) = ...`,
`hint s s = "Correct!"`. When we *have* an equality, we want to use it, by
replacing one side with the other. That is what `rw [h]` does: if
`h : a = b`, it replaces `a` by `b` everywhere in the goal. Afterwards it
tries `rfl`, so a goal that has become `x = x` disappears.

`rw` also accepts theorems that take arguments. `Nat.add_comm` says
`a + b = b + a` for all `a` and `b`; `rw [Nat.add_comm]` uses it on the first
sum it finds, and `rw [Nat.add_comm x]` on the first one that starts with `x`.
To rewrite from right to left, write `rw [← h]`.

Read more: https://lean-lang.org/theorem_proving_in_lean4/Tactics/#rewriting
-/

theorem rwExample (a b c : Nat) (h₁ : a = b) (h₂ : b = c) : a = c := by
  rw [h₁, h₂]

/-- Rewrite with `h`: what is left is true by `rfl`. -/
theorem rewriteSum (a b : Nat) (h : a = b) : a + b = b + a := by
  -- SOLUTION
  rw [h]
  -- END SOLUTION

/-- The sum in `h` is in the wrong order: first swap the goal's sum with
`Nat.add_comm`, then use `h`. -/
theorem rewriteSwap (a b c : Nat) (h : b + a = c) : a + b = c := by
  -- SOLUTION
  rw [Nat.add_comm, h]
  -- END SOLUTION

/-- `h` says what `f 3` is. Rewrite with it. -/
theorem rewriteCall (f : Nat → Nat) (h : f 3 = 10) : f 3 + f 3 = 20 := by
  -- SOLUTION
  rw [h]
  -- END SOLUTION

/-! ## 5. Evidence as arguments

So far proofs have been the goal. Now they become tools, because they solve a
problem every programmer knows: looking up the entry at a position that
doesn't exist. Most languages detect it while the program runs, and crash.
Lean detects it *before* running, by asking for evidence.

The notation `xs[i]` gives the entry at position `i` of a list or an array
(counting from 0), but only if Lean can find a proof of `i < xs.length`. For
concrete lists it finds one on its own, using tactics such as `decide`. When
the list is a variable, the evidence must come from somewhere, and the natural
place is an argument: a function can ask its caller for a proof, just like it
asks for a number. Inside the function, Lean finds that proof among the
arguments, and also proves simple consequences, such as `1 < xs.length` from
`xs.length > 3`.

The caller then has to provide the proof, usually with `by decide`. If the
list is too short, the proof can't be built, and the program never runs.

Read more: https://lean-lang.org/functional_programming_in_lean/Interlude___-Propositions___-Proofs___-and-Indexing/#evidence-passing
-/

#eval ["red", "green", "blue"][1]  -- "green"

/-! Uncomment this line to see what happens when the evidence doesn't exist:

    #eval ["red", "green", "blue"][5]
-/

def second (xs : List α) (ok : xs.length > 1) : α := xs[1]

#eval second [10, 20, 30] (by decide)  -- 20

/-- The first and the last entries of a list with at least one entry. -/
def ends (xs : List α) (ok : xs.length > 0) : α × α :=
  -- SOLUTION
  (xs[0], xs[xs.length - 1])
  -- END SOLUTION

-- TESTS
#guard ends [4, 5, 6, 7] (by decide) = (4, 7)
#guard ends ["solo"] (by decide) = ("solo", "solo")
-- END TESTS

/-- The middle entry of an array of three entries. Arrays are written `#[...]`;
they are indexed like lists, and their length is `xs.size`. -/
def middle (xs : Array String) (ok : xs.size = 3) : String :=
  -- SOLUTION
  xs[1]
  -- END SOLUTION

-- TESTS
#guard middle #["low", "mid", "high"] (by decide) = "mid"
-- END TESTS

/-! ## 6. Indexing without evidence

Evidence is the safest way to index, but it isn't always convenient. The
index may come from user input, and then nobody can promise in advance that
it is in bounds. For those cases there are two other ways to index:

* `xs[i]?` returns an `Option`: `some` entry if `i` is in bounds, and `none`
  otherwise. Then a `match` decides what to do in each case.
* `xs[i]!` returns the entry and stops the program with a message (a *panic*)
  if `i` is out of bounds. Lean still needs some value to return in that case,
  so the type of the entries must have a default value (an `Inhabited`
  instance; more about instances in module 4). Use it only when you are sure,
  and prefer the other two ways.

Read more: https://lean-lang.org/functional_programming_in_lean/Interlude___-Propositions___-Proofs___-and-Indexing/#indexing-without-evidence
-/

#eval [10, 20, 30][1]?  -- some 20
#eval [10, 20, 30][7]?  -- none
#eval [10, 20, 30][1]!  -- 20

/-- The sum of the entries at positions `i` and `j`, or `none` if either is
out of bounds. -/
def sumAt? (xs : List Nat) (i j : Nat) : Option Nat :=
  -- SOLUTION
  match xs[i]?, xs[j]? with
  | some a, some b => some (a + b)
  | _, _ => none
  -- END SOLUTION

-- TESTS
#guard sumAt? [1, 2, 3] 0 2 = some 4
#guard sumAt? [1, 2, 3] 1 1 = some 4
#guard sumAt? [1, 2, 3] 0 3 = none
#guard sumAt? [] 0 0 = none
-- END TESTS

/-- The entries at the given positions, skipping the positions that are out of
bounds. -/
def pick (xs : List String) (positions : List Nat) : List String :=
  -- SOLUTION
  positions.filterMap (fun i => xs[i]?)
  -- END SOLUTION

-- TESTS
#guard pick ["a", "b", "c"] [2, 0, 9, 2] = ["c", "a", "c"]
#guard pick [] [0, 1] = []
-- END TESTS

/-! ## Final project of the module: a minefield

A minefield is a grid of characters: `'*'` is a mine and `'.'` is safe. We
write it as a list of rows, each row a list of characters. In the game, each
safe square shows how many mines touch it, and this project computes that
number. -/

def field : List (List Char) :=
  [ ['*', '.', '.'],
    ['.', '.', '*'],
    ['.', '*', '*'] ]

/-- The square at row `r` and column `c`, or `none` outside the grid.

Hint: first look up the row with `?`, then the column. -/
def squareAt? (g : List (List Char)) (r c : Nat) : Option Char :=
  -- SOLUTION
  match g[r]? with
  | some row => row[c]?
  | none => none
  -- END SOLUTION

-- TESTS
#guard squareAt? field 0 0 = some '*'
#guard squareAt? field 1 2 = some '*'
#guard squareAt? field 2 0 = some '.'
#guard squareAt? field 3 0 = none
#guard squareAt? field 0 3 = none
-- END TESTS

/-- The square at row `r` and column `c`, when the caller proves that both are
in bounds. -/
def square (g : List (List Char)) (r c : Nat) (hr : r < g.length)
    (hc : c < g[r].length) : Char :=
  -- SOLUTION
  g[r][c]
  -- END SOLUTION

-- TESTS
#guard square field 2 1 (by decide) (by decide) = '*'
-- END TESTS

/-- The positions around row `r` and column `c`, without leaving the grid
through the top or the left edge. (Positions past the bottom or the right
edge are harmless: `squareAt?` gives `none` there.) -/
def around (r c : Nat) : List (Nat × Nat) :=
  let rows := (if r > 0 then [r - 1] else []) ++ [r, r + 1]
  let cols := (if c > 0 then [c - 1] else []) ++ [c, c + 1]
  let all := rows.flatMap (fun i => cols.map (fun j => (i, j)))
  all.filter (· != (r, c))

#eval around 0 0  -- [(0, 1), (1, 0), (1, 1)]

/-- How many of the squares around row `r` and column `c` are mines. -/
def minesAround (g : List (List Char)) (r c : Nat) : Nat :=
  -- SOLUTION
  ((around r c).filter (fun (i, j) => squareAt? g i j == some '*')).length
  -- END SOLUTION

-- TESTS
#guard minesAround field 1 1 = 4
#guard minesAround field 0 1 = 2
#guard minesAround field 2 0 = 1
#guard minesAround field 0 0 = 0
-- END TESTS

/-- Once `minesAround` works, prove this fact about `field` by computation. -/
theorem cornerIsSafe : minesAround field 0 2 = 1 ∧ squareAt? field 0 2 = some '.' := by
  -- SOLUTION
  decide
  -- END SOLUTION

end Propositions
