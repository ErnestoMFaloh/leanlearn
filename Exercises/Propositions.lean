-- Stuck? The solutions are in `Solutions/Propositions.lean`.
-- Contributors: this file is generated from `Solutions/Propositions.lean`;
-- edit that file and run `python3 scripts/generate.py`.

/-!
# Module 3 — Propositions and proofs

Goals:
* Understand that propositions are types and proofs are terms.
* Use the basic tactics: `intro`, `exact`, `apply`, `constructor`,
  `cases`, `rfl`, `rw`, `simp`.
* Propositional logic: `→`, `∧`, `∨`, `¬`, `↔`.

Tip: in tactic mode (`by`), put the cursor after each line and watch
how the *goal* changes in the Infoview.
-/

namespace Propositions

/-! ## 1. Equalities by computation: `rfl` -/

example : 2 + 2 = 4 := rfl
example : "ab" ++ "c" = "abc" := rfl

/-! ## 2. Implication: `intro` and `exact` -/

theorem identity (p : Prop) : p → p := by
  intro hp
  exact hp

-- The same proof written as a term: a function.
theorem identity' (p : Prop) : p → p := fun hp => hp

theorem modus_ponens (p q : Prop) (hp : p) (hpq : p → q) : q := by
  apply hpq
  exact hp

/-! ## 3. Conjunction `∧` -/

theorem and_intro (p q : Prop) (hp : p) (hq : q) : p ∧ q := by
  constructor
  · exact hp
  · exact hq

theorem and_swap (p q : Prop) : p ∧ q → q ∧ p := by
  intro ⟨hp, hq⟩
  exact ⟨hq, hp⟩

/-! ## 4. Disjunction `∨` -/

theorem or_swap (p q : Prop) : p ∨ q → q ∨ p := by
  intro h
  cases h with
  | inl hp => exact Or.inr hp
  | inr hq => exact Or.inl hq

/-! ## 5. Negation: `¬p` means `p → False` -/

theorem no_contradiction (p : Prop) : ¬(p ∧ ¬p) := by
  intro ⟨hp, hnp⟩
  exact hnp hp

/-! ## 6. Rewriting with `rw` -/

theorem rw_example (a b c : Nat) (h₁ : a = b) (h₂ : b = c) : a = c := by
  rw [h₁, h₂]

/-! ## Exercises (replace every `sorry`) -/

theorem ex1 (p q r : Prop) : (p → q) → (q → r) → (p → r) := by
  sorry

theorem ex2 (p q : Prop) : p ∧ q → p ∨ q := by
  sorry

theorem ex3 (p q : Prop) : p ∨ q ↔ q ∨ p := by
  sorry

theorem ex4 (p q : Prop) : (p → q) → ¬q → ¬p := by
  sorry

theorem ex5 (a b : Nat) (h : a = b) : a + 0 = b := by
  sorry

end Propositions
