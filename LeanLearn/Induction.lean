/-!
# Module 3 — Induction: proving things about your programs

Goals:
* Proofs by induction on `Nat` and `List`.
* Combine `simp`, `rw` and the induction hypothesis.
* Verify properties of functions you wrote yourself.
-/

namespace Induction

/-! ## 1. Our own addition, to prove things from scratch -/

def add : Nat → Nat → Nat
  | n, 0     => n
  | n, m + 1 => add n m + 1

theorem add_zero (n : Nat) : add n 0 = n := rfl

-- This one does not follow by `rfl`: it needs induction on `n`.
theorem zero_add (n : Nat) : add 0 n = n := by
  induction n with
  | zero => rfl
  | succ k ih => simp [add, ih]

/-! ## 2. Induction on lists -/

def length {α : Type} : List α → Nat
  | []      => 0
  | _ :: xs => length xs + 1

def append {α : Type} : List α → List α → List α
  | [],      ys => ys
  | x :: xs, ys => x :: append xs ys

theorem length_append {α : Type} (xs ys : List α) :
    length (append xs ys) = length xs + length ys := by
  induction xs with
  | nil => simp [append, length]
  | cons x xs ih => simp [append, length, ih]; omega

/-! ## 3. A property of a program: the sum of the first n numbers -/

def sumUpTo : Nat → Nat
  | 0     => 0
  | n + 1 => (n + 1) + sumUpTo n

-- Gauss: 2 · (0 + 1 + ... + n) = n · (n + 1)
theorem gauss (n : Nat) : 2 * sumUpTo n = n * (n + 1) := by
  induction n with
  | zero => rfl
  | succ k ih =>
    simp only [sumUpTo, Nat.mul_add, ih]
    simp only [Nat.add_mul, Nat.mul_add, Nat.mul_one, Nat.one_mul]
    omega

/-! ## Exercises (replace every `sorry`) -/

theorem ex1 {α : Type} (xs : List α) : append xs [] = xs := by
  sorry

theorem ex2 {α : Type} (xs ys zs : List α) :
    append (append xs ys) zs = append xs (append ys zs) := by
  sorry

theorem ex3 (n m : Nat) : add (m + 1) n = add m n + 1 := by
  sorry

/-! ## Final project of the module

Define a function `reverse` on lists and prove that
`length (reverse xs) = length xs`.

Hint: you will probably need a lemma about `length (append xs ys)`.
It is already proved above as `length_append`.
-/

def reverse {α : Type} : List α → List α
  | _ => sorry

theorem length_reverse {α : Type} (xs : List α) :
    length (reverse xs) = length xs := by
  sorry

end Induction
