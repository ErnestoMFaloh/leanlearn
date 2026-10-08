-- Stuck? The solutions are in `Solutions/Programming.lean`.
-- Contributors: this file is generated from `Solutions/Programming.lean`;
-- edit that file and run `python3 scripts/generate.py`.

/-!
# Module 1 — Lean as a programming language

Goals:
* Evaluate expressions with `#eval` and inspect types with `#check`.
* Define functions with `def`.
* Recursion and pattern matching (`match`).
* Inductive types and structures.

Tip: open this file in VS Code with the "Lean 4" extension and watch
the *Lean Infoview* panel on the right as you move the cursor.
-/

namespace Programming

/-! ## 1. Expressions and types -/

#eval 2 + 3 * 4          -- 14
#eval "Hello, " ++ "Lean" -- "Hello, Lean"
#check 42                 -- 42 : Nat
#check "text"             -- "text" : String
#check (fun x => x + 1)   -- fun x => x + 1 : Nat → Nat

/-! ## 2. Functions -/

def double (n : Nat) : Nat := 2 * n

#eval double 21  -- 42

def greet (name : String) : String :=
  s!"Hello, {name}!"

#eval greet "Lean"

/-! ## 3. Recursion and `match` -/

def factorial : Nat → Nat
  | 0     => 1
  | n + 1 => (n + 1) * factorial n

#eval factorial 10  -- 3628800

def fib : Nat → Nat
  | 0     => 0
  | 1     => 1
  | n + 2 => fib n + fib (n + 1)

#eval (List.range 10).map fib

/-! ## 4. Lists -/

def sum : List Nat → Nat
  | []      => 0
  | x :: xs => x + sum xs

#eval sum [1, 2, 3, 4, 5]  -- 15

/-! ## 5. Inductive types and structures -/

inductive Color where
  | red | green | blue
  deriving Repr

def Color.next : Color → Color
  | .red   => .green
  | .green => .blue
  | .blue  => .red

#eval Color.red.next

structure Point where
  x : Int
  y : Int
  deriving Repr

def Point.add (p q : Point) : Point :=
  { x := p.x + q.x, y := p.y + q.y }

#eval (Point.mk 1 2).add ⟨3, 4⟩

/-! ## Exercises (replace every `sorry`)

Lean flags each `sorry` with a warning: the goal is for this file to
compile with none left.
-/

/-- Returns the length of a list. -/
def length {α : Type} : List α → Nat
  | _ => sorry

/-- Reverses a list. -/
def reverse {α : Type} : List α → List α
  | _ => sorry

/-- A binary tree of natural numbers. Implement `size`. -/
inductive Tree where
  | leaf
  | node (left : Tree) (value : Nat) (right : Tree)

def Tree.size : Tree → Nat
  | _ => sorry

end Programming
