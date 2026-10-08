# Contributing

Thanks for helping improve leanlearn! Fixes, clearer explanations and new
exercises are all welcome.

## How the project is organized

```
Solutions/        ← the source of truth: examples + solved exercises
Exercises/        ← generated from Solutions/; this is where learners work
scripts/generate.py
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

To keep something out of the exercises entirely (such as a helper lemma that
would give the answer away), use `-- SOLUTION ONLY` and
`-- END SOLUTION ONLY`.

## Before opening a pull request

1. `python3 scripts/generate.py` and commit the regenerated files.
2. `lake build` succeeds.
3. `Solutions/` has no `sorry` left: `lake build Solutions` prints no
   `declaration uses 'sorry'` warning.
4. `python3 scripts/generate.py --check` reports the exercises are up to date.

## Style

- Explanations and identifiers in English.
- Start each module with a `/-! ... -/` block listing its goals.
- Prefer the tactics the module has already introduced, so a learner can solve
  every exercise with what they have seen so far.
- Keep solutions readable: they are also learning material.
