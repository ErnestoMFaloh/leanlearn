# Contributing

Thanks for helping improve leanlearn! Fixes, clearer explanations and new
exercises are all welcome.

## How the project is organized

```
Solutions/              ← the source of truth: examples + solved exercises
Exercises/              ← generated from Solutions/; this is where learners work
scripts/generate.py     ← writes Exercises/ from Solutions/
Checker.lean            ← `lake exe check`: tells learners what they have solved
scripts/test_checker.py ← makes sure the checker catches wrong answers
```

**Never edit `Exercises/` by hand.** Edit the file in `Solutions/` and
regenerate:

```bash
python3 scripts/generate.py
```

## Writing an exercise

Write the exercise fully solved in `Solutions/`, and wrap the part the learner
must write between markers:

```lean
theorem ex1 (p q r : Prop) : (p → q) → (q → r) → (p → r) := by
  -- SOLUTION
  intro hpq hqr hp
  exact hqr (hpq hp)
  -- END SOLUTION
```

In `Exercises/`, the block becomes `sorry`, keeping the marker's indentation.

When `sorry` alone is not valid Lean at that spot, give a stub after a colon.
For example, for a definition by pattern matching:

```lean
def length {α : Type} : List α → Nat
  -- SOLUTION: | _ => sorry
  | []      => 0
  | _ :: xs => 1 + length xs
  -- END SOLUTION
```

For a program, add tests right after it. They run when `Solutions/` is built,
and in `Exercises/` they appear commented out so learners can see what is
expected; `lake exe check` runs them against the learner's code:

```lean
-- TESTS
#guard length [7] = 1
#guard length ["a", "b", "c"] = 3
-- END TESTS
```

`lake exe check` treats every declaration containing a `-- SOLUTION` marker
as an exercise.

To keep something out of the exercises entirely (such as a helper lemma that
would give the answer away), use `-- SOLUTION ONLY` and
`-- END SOLUTION ONLY`.

## Before opening a pull request

1. `python3 scripts/generate.py` and commit the regenerated files.
2. `lake build` succeeds.
3. `lake exe check --dir Solutions --strict` reports every exercise as solved.
   This also confirms `Solutions/` has no `sorry` left and that the tests in
   `-- TESTS` blocks pass.
4. `python3 scripts/generate.py --check` reports the exercises are up to date.
5. If you changed `Checker.lean`: `python3 scripts/test_checker.py` passes.

CI runs all of these on every push.

## Style

- Explanations and identifiers in English.
- Start each module with a `/-! ... -/` block listing its goals.
- Prefer the tactics the module has already introduced, so a learner can solve
  every exercise with what they have seen so far.
- Keep solutions readable: they are also learning material.
