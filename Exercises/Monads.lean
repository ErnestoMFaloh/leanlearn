-- Stuck? The solutions are in `Solutions/Monads.lean`.
-- Contributors: this file is generated from `Solutions/Monads.lean`;
-- edit that file and run `python3 scripts/generate.py`.

/-!
# Module 5 — Monads

Module 2 used `do` blocks to put `IO` actions in sequence, and module 4 showed
that Lean's notation is built from type classes. This module brings the two
ideas together. Many kinds of computation that seem unrelated (computations
that may fail, that report errors, that keep a counter, that write a log) all
follow the same pattern, and a single type class, `Monad`, captures it. Once
a type has a `Monad` instance, `do` blocks work for it too.

Goals:
* Recognize the "do this, then that" pattern in `Option`, `Except`, state and
  logging.
* Declare `Monad` instances, and write functions that work in every monad.
* Use `do` notation outside `IO`.
* Understand `IO` as one monad among others, with errors you can catch.
* Use or-patterns, leading dots and shared argument types.

Read alongside: *Functional Programming in Lean*, chapter 4
(https://lean-lang.org/functional_programming_in_lean/Monads/).
Each section of this file covers a section of the chapter, with its own
explanation, so you can also work without the book.
-/

namespace Monads

/-- Fails, with a message, unless `actual` is `expected` (from module 2). -/
def expect [BEq α] [Repr α] (actual expected : α) : IO Unit :=
  unless actual == expected do
    throw <| IO.userError s!"expected {repr expected}, but got {repr actual}"

/-- Lean has no `==` for `Except` (section 1), so the tests use this instance. -/
instance instBEqExcept [BEq ε] [BEq α] : BEq (Except ε α) where
  beq
    | .ok x, .ok y => x == y
    | .error e, .error f => e == f
    | _, _ => false

/-! ## 1. One API, many applications

A shop keeps its prices in a list of pairs. `List.lookup` finds the price of
an item, but the item may not be there, so it returns an `Option`. -/

def prices : List (String × Nat) := [("apple", 30), ("bread", 250), ("milk", 120)]

#eval prices.lookup "bread"  -- some 250
#eval prices.lookup "jam"    -- none

/-! Now suppose we want the price of a sandwich: bread plus milk plus jam.
Each lookup can fail, and if one fails, the whole answer is `none`. With
`match`, the code drifts to the right with every step: -/

def sandwichPrice : Option Nat :=
  match prices.lookup "bread" with
  | none => none
  | some bread =>
    match prices.lookup "milk" with
    | none => none
    | some milk =>
      match prices.lookup "jam" with
      | none => none
      | some jam => some (bread + milk + jam)

/-! All the `none => none` lines say the same thing: "if this step failed,
stop". We can write that once, in a function that takes the result of a step
and the rest of the computation, as a function of that result: -/

def andThen (step : Option α) (next : α → Option β) : Option β :=
  match step with
  | none => none
  | some x => next x

def sandwichPrice' : Option Nat :=
  andThen (prices.lookup "bread") fun bread =>
  andThen (prices.lookup "milk") fun milk =>
  andThen (prices.lookup "jam") fun jam =>
  some (bread + milk + jam)

/-! (A `fun` can take the rest of the expression as its body, without
parentheses, even on the next lines.) The computation now reads from top to
bottom, like a `do` block, and the failure handling is hidden in `andThen`.

`none` says that something failed, but not what. When we want a reason, we
use `Except ε α` instead: a value is either `.ok x` with a result `x : α`, or
`.error e` with an error `e : ε`, often a `String`. -/

def priceOf (item : String) : Except String Nat :=
  match prices.lookup item with
  | none => .error s!"no price for {item}"
  | some p => .ok p

/-- The same pattern for `Except`: stop at the first error, or go on. -/
def andThenExcept (step : Except ε α) (next : α → Except ε β) : Except ε β :=
  sorry

-- Tests (`lake exe check` runs them for you):
-- #guard andThenExcept (priceOf "milk") (fun p => .ok (p * 2)) == .ok 240
-- #guard andThenExcept (priceOf "jam") (fun p => .ok (p * 2)) == .error "no price for jam"

/-- The price of `n` units of `item` plus `m` units of `other`. Use
`andThenExcept` with `priceOf`. -/
def orderPrice (item : String) (n : Nat) (other : String) (m : Nat) : Except String Nat :=
  sorry

-- Tests (`lake exe check` runs them for you):
-- #guard orderPrice "apple" 3 "milk" 1 == .ok 210
-- #guard orderPrice "apple" 3 "jam" 1 == .error "no price for jam"

/-! The pattern goes beyond failure. Suppose we want to give each item of a
list a numbered label: `apple-0`, `bread-1`, ... Each step needs the current
counter and produces a new one. Lean's names never change, so the counter
has to travel from step to step. A computation that does that is a function
from the current *state* to the new state and a result: -/

def State (σ α : Type) : Type := σ → σ × α

def State.get : State σ σ := fun s => (s, s)
def State.set (s : σ) : State σ Unit := fun _ => (s, ())

/-- "Run `step`, then `next` with its result": the new state of `step` is the
state `next` starts from. -/
def andThenState (step : State σ α) (next : α → State σ β) : State σ β :=
  fun s =>
    let (s', x) := step s
    next x s'

/-! `State.set` has nothing interesting to return, so its result is `()`, the
only value of type `Unit`. The step after it can take that value apart with
the pattern `fun () => ...`. -/

/-- A label: the name, a dash, and the current counter, which goes up by one.
Use `andThenState`, `State.get` and `State.set`. -/
def label (name : String) : State Nat String :=
  sorry

-- Tests (`lake exe check` runs them for you):
-- #guard label "apple" 0 = (1, "apple-0")
-- #guard andThenState (label "a") (fun x => andThenState (label "b") fun y => fun s => (s, [x, y])) 5
--   = (7, ["a-5", "b-6"])

/-! A last kind of computation produces a result together with a log of what
it did. Combining two such steps runs both and keeps both logs, in order. -/

structure Logged (α : Type) where
  log : List String
  value : α
  deriving BEq, Repr

def note (msg : String) : Logged Unit := { log := [msg], value := () }

/-- Runs `step` and then `next`, joining their logs. -/
def andThenLogged (step : Logged α) (next : α → Logged β) : Logged β :=
  sorry

-- Tests (`lake exe check` runs them for you):
-- #guard andThenLogged (note "one") (fun () => andThenLogged (note "two") fun () => ⟨[], 7⟩)
--   == { log := ["one", "two"], value := 7 }

/-! Four kinds of computation, one shape. Each has a way to sequence two
steps (`andThen`), and each has a trivial computation that just returns a
value: `some x`, `.ok x`, `fun s => (s, x)` and `⟨[], x⟩`.

Read more: https://lean-lang.org/functional_programming_in_lean/Monads/One-API___-Many-Applications/
-/

/-! ## 2. The `Monad` type class

When the same operations appear for many types, module 4 tells us what to
do: make a type class. The class is called `Monad`, and its two operations
are the ones we found:

* `pure x` is the computation that just returns `x`;
* `bind step next`, written `step >>= next`, runs `step` and then `next` with
  its result.

The class is for type constructors like `Option` or `State σ`, as `Functor`
was in module 4, because `pure` and `bind` work for results of every type.
Lean already has instances for `Option` and `Except ε`, and we can give
instances for our own: -/

instance instMonadState : Monad (State σ) where
  pure x := fun s => (s, x)
  bind := andThenState

/-- Our logged computations form a monad too. -/
instance instMonadLogged : Monad Logged where
  pure _ := sorry
  bind _ _ := sorry

-- Tests (`lake exe check` runs them for you):
-- #guard (pure 3 : Logged Nat) == ⟨[], 3⟩
-- #guard (note "hi" >>= fun () => pure 1) == ⟨["hi"], 1⟩

/-! The reward is that functions can be written once for *every* monad, with
a `[Monad m]` argument, just like `[Add α]` in module 4. This function applies
a computation to each entry of a list and collects the results. In `Option`
it fails if any step fails, in `State` it threads the state through all the
steps, and in `Logged` it collects all the logs: -/

def forEach [Monad m] (f : α → m β) : List α → m (List β)
  | [] => pure []
  | x :: xs =>
    f x >>= fun y =>
    forEach f xs >>= fun ys =>
    pure (y :: ys)

#eval forEach (fun item => prices.lookup item) ["apple", "milk"]  -- some [30, 120]
#eval forEach (fun item => prices.lookup item) ["apple", "jam"]   -- none
-- Once `label` is solved, this gives (3, ["apple-0", "bread-1", "milk-2"]):
-- #eval (forEach label ["apple", "bread", "milk"] : State Nat _) 0

/-- Keeps the entries for which `p` returns `true`, where `p` is a
computation in any monad. Read the code of `forEach` for inspiration. -/
def keepIf [Monad m] (p : α → m Bool) : List α → m (List α)
  | _ => sorry

-- Tests (`lake exe check` runs them for you):
-- #guard keepIf (fun n => some (n > 2)) [1, 5, 2, 7] = some [5, 7]
-- #guard keepIf (fun (n : Nat) => if n == 0 then none else some (n > 2)) [1, 0, 7] = none
-- #guard keepIf (fun n => note s!"saw {n}" >>= fun () => pure (n % 2 == 0)) [1, 2]
--   == { log := ["saw 1", "saw 2"], value := [2] }

/-! Most monads should obey a few rules, called the *monad laws*, which say
that `pure` really does nothing and that `bind` doesn't care how a sequence
of steps is grouped. The instances in this module all follow them.

Read more: https://lean-lang.org/functional_programming_in_lean/Monads/The-Monad-Type-Class/
-/

/-! ## 3. Example: a stack calculator

A calculator that works with a stack reads instructions one by one. A number
is pushed on top of the stack; an operation takes the two numbers on top and
pushes the result. For instance `2 3 add 4 mul` computes `(2 + 3) * 4`.

Read more: https://lean-lang.org/functional_programming_in_lean/Monads/Example___-Arithmetic-in-Monads/ -/

inductive Instr where
  | push (n : Int)
  | add
  | sub
  | mul
  | div
  deriving Repr

/-! Two things can go wrong: an operation may find fewer than two numbers on
the stack, and a division may divide by zero. How should the calculator
react? Sometimes we want a simple `none`, sometimes a message. Instead of
choosing, we write the calculator for every monad, and let the caller give
the two operations that can fail: how to `pop` a number off the stack, and
how to `divide`. -/

/-! For example, a calculator that gives up silently uses `Option`: -/

def popOption : List Int → Option (Int × List Int)
  | [] => none
  | x :: xs => some (x, xs)

def divideOption (x y : Int) : Option Int := if y == 0 then none else some (x / y)

/-- The stack after running one instruction, in any monad `m`. Numbers are
pushed on the front of the list; for an operation, pop the top number `y`,
then the next one `x`, and push `x op y` (so `sub` computes `x - y`). Use
`>>=` and `pure`. -/
def exec [Monad m] (pop : List Int → m (Int × List Int)) (divide : Int → Int → m Int) :
    Instr → List Int → m (List Int)
  | _, _ => sorry

-- Tests (`lake exe check` runs them for you):
-- #guard exec popOption divideOption (.push 4) [] = some [4]
-- #guard exec popOption divideOption .sub [2, 10] = some [8]
-- #guard exec popOption divideOption .div [3, 10] = some [3]
-- #guard exec popOption divideOption .div [0, 1] = none
-- #guard exec popOption divideOption .add [1] = none

/-- Runs the instructions in order, starting from `stack`. -/
def execAll [Monad m] (pop : List Int → m (Int × List Int)) (divide : Int → Int → m Int) :
    List Instr → List Int → m (List Int)
  | _, _ => sorry

-- Tests (`lake exe check` runs them for you):
-- #guard execAll popOption divideOption [.push 2, .push 3, .add, .push 4, .mul] [] = some [20]
-- #guard execAll popOption divideOption [.mul] [] = none

/-! With these two operations, we get the first calculator: -/

def calcOption (program : List Instr) : Option (List Int) :=
  execAll popOption divideOption program []

/-- Pops the top number, or fails with `"stack underflow"`. -/
def popExcept : List Int → Except String (Int × List Int)
  | _ => sorry

-- Tests (`lake exe check` runs them for you):
-- #guard popExcept [] == .error "stack underflow"
-- #guard popExcept [1, 2] == .ok (1, [2])

/-- Divides, or fails with `"division by zero"`. -/
def divideExcept (x y : Int) : Except String Int :=
  sorry

/-- The second calculator explains what went wrong. -/
def calcExcept (program : List Instr) : Except String (List Int) :=
  execAll popExcept divideExcept program []

-- Tests (`lake exe check` runs them for you):
-- #guard calcOption [.push 2, .push 3, .add, .push 4, .mul] = some [20]
-- #guard calcOption [.push 10, .push 4, .sub, .push 3, .div] = some [2]
-- #guard calcOption [.push 1, .add] = none
-- #guard calcExcept [.push 7, .push 2, .sub] == .ok [5]
-- #guard calcExcept [.push 1, .push 2, .push 3, .mul] == .ok [6, 1]
-- #guard calcExcept [.mul] == .error "stack underflow"
-- #guard calcExcept [.push 1, .push 0, .div] == .error "division by zero"

/-! ## 4. `do` notation for monads

Chains of `>>=` and `fun` work, but they are hard to read. We already know
something better: the `do` blocks of module 2. Now we can reveal what they
are. A `do` block is notation for `>>=`, and it works in *every* monad, not
only in `IO`. Each `let x ← step` line becomes `step >>= fun x => ...`, with
the rest of the block as the body, and a line without `←` becomes
`step >>= fun () => ...`. Everything else from module 2 also works in any
monad: `(← e)`, `return`, `if` without `else`, `for` and `let mut`.

Read more: https://lean-lang.org/functional_programming_in_lean/Monads/do--Notation-for-Monads/ -/

/-! Here is `sandwichPrice` once more. Each `←` stops the whole block with
`none` if its lookup fails: -/

def sandwichPrice'' : Option Nat := do
  let bread ← prices.lookup "bread"
  let milk ← prices.lookup "milk"
  let jam ← prices.lookup "jam"
  return bread + milk + jam

/-- Reads a version number such as `"4.34.1"`: three numbers separated by
dots. Anything else is `none`. Use a `do` block in `Option`.

Hint: `String.splitOn "."` cuts the text into pieces, and `String.toNat?` reads
a number. -/
def parseVersion? (s : String) : Option (Nat × Nat × Nat) := do
  sorry

-- Tests (`lake exe check` runs them for you):
-- #guard parseVersion? "4.34.1" = some (4, 34, 1)
-- #guard parseVersion? "4.34" = none
-- #guard parseVersion? "4.x.1" = none

/-- Labels every name with `label`, in order. Use a `do` block in `State Nat`,
with `for` and `let mut`. -/
def labelAll (names : List String) : State Nat (List String) := do
  sorry

-- Tests (`lake exe check` runs them for you):
-- #guard labelAll ["x", "y", "z"] 10 = (13, ["x-10", "y-11", "z-12"])
-- #guard labelAll [] 0 = (0, [])

/-- Adds the numbers of the list, logging `"skipped <n>"` for each odd
number, which is not added. Use a `do` block in `Logged`. -/
def sumEvens (xs : List Nat) : Logged Nat := do
  sorry

-- Tests (`lake exe check` runs them for you):
-- #guard sumEvens [2, 3, 4, 5] == { log := ["skipped 3", "skipped 5"], value := 6 }
-- #guard sumEvens [] == { log := [], value := 0 }

/-! ## 5. The `IO` monad

`IO` is a monad too, and that is why `do` blocks worked in module 2. Its
`pure` performs no action, and its `bind` performs the first action, then the
next one. Underneath, an `IO` action is a function that receives "the world"
and returns its result together with the new world, much like `State`, except
that the world can't be copied or inspected.

`IO` actions can also fail, like `Except`. An action may *throw* an error,
for example when a file doesn't exist, or when we call `throw` ourselves. The
error stops the rest of the block, unless it is caught: in
`try body catch e => handler`, an error thrown by `body` runs `handler`
instead, with the error as `e`.

Every function written for any monad also works in `IO`: -/

#eval forEach (fun n => do IO.println s!"got {n}"; pure (n * n)) [1, 2, 3]

/-! (`;` separates two steps on the same line.)

Read more: https://lean-lang.org/functional_programming_in_lean/Monads/The-IO-Monad/
-/

def failing : IO Nat := throw (IO.userError "out of luck")

#eval try failing catch e => do IO.println s!"caught: {e}"; pure 0

/-- Runs the actions in order and adds their results. Actions that throw an
error are left out of the sum, and the other actions still run. -/
def safeSum (actions : List (IO Nat)) : IO Nat := do
  sorry

-- Tests (`lake exe check` runs them for you):
-- #eval do expect (← safeSum [pure 1, failing, pure 10]) 11
-- #eval do expect (← safeSum []) 0

/-! ## 6. Additional conveniences

Three small pieces of notation make the code of this module shorter.

*Shared argument types.* When several arguments have the same type, they can
share it: `(x y : Int)` is `(x : Int) (y : Int)`. We have been doing this
since module 1, without saying so.

*Leading dot notation.* When Lean already knows the expected type, a
constructor or function in that type's namespace can be written with just a
dot: `.ok 3` instead of `Except.ok 3`, and `.push 2` instead of
`Instr.push 2`. The tests of section 3 use it.

*Or-patterns.* When several cases of a `match` have the same answer, they can
share one line, separated by `|`: `| .add | .sub => ...`. All the patterns of
the line must name the same variables.

Read more: https://lean-lang.org/functional_programming_in_lean/Monads/Additional-Conveniences/
-/

/-- How many numbers each instruction takes from the stack. Use one line for
all the operations, with an or-pattern. -/
def Instr.arity : Instr → Nat
  | _ => sorry

-- Tests (`lake exe check` runs them for you):
-- #guard Instr.arity (.push 3) = 0
-- #guard [Instr.add, .div].map Instr.arity = [2, 2]

/-! ## Final project of the module: a bank

A bank keeps a balance for every account, and its operations can fail: an
account may not exist, or may not have enough money. So a bank operation
needs *both* a state (the accounts) and errors: it receives the accounts,
and returns either an error or the new accounts with a result. Chapter 6
builds such combinations from smaller monads; here we write it by hand. -/

abbrev Accounts := List (String × Nat)

def Bank (α : Type) : Type := Accounts → Except String (Accounts × α)

/-- `pure` leaves the accounts as they are. `bind` runs the first operation
and, if it succeeded, the second one on the new accounts. -/
instance instMonadBank : Monad Bank where
  pure _ := sorry
  bind _ _ := sorry

-- Tests (`lake exe check` runs them for you):
-- #guard (pure 5 : Bank Nat) [("ana", 1)] == .ok ([("ana", 1)], 5)
-- #guard ((show Bank Nat from fun accounts => .ok (accounts, accounts.length)) >>= fun n => pure (n + 1)
--   : Bank Nat) [("ana", 1)] == .ok ([("ana", 1)], 2)
-- #guard ((show Bank Nat from fun _ => .error "closed") >>= fun n => pure (n + 1)
--   : Bank Nat) [] == .error "closed"

def Bank.fail (msg : String) : Bank α := fun _ => .error msg
def Bank.accounts : Bank Accounts := fun accounts => .ok (accounts, accounts)
def Bank.setAccounts (accounts : Accounts) : Bank Unit := fun _ => .ok (accounts, ())

/-- Sets the balance of an account, which must already exist. -/
def Bank.setBalance (name : String) (amount : Nat) : Bank Unit := do
  let accounts ← Bank.accounts
  Bank.setAccounts (accounts.map fun (n, b) => if n == name then (n, amount) else (n, b))

/-- The balance of an account, or the error `no account <name>`. -/
def Bank.balance (name : String) : Bank Nat := do
  sorry

-- Tests (`lake exe check` runs them for you):
-- #guard (Bank.balance "ana" [("ana", 5)]) == .ok ([("ana", 5)], 5)
-- #guard (Bank.balance "bo" [("ana", 5)]) == .error "no account bo"

/-- Takes `amount` out of an account. If the balance is smaller, fails with
`not enough money in <name>`. -/
def Bank.withdraw (name : String) (amount : Nat) : Bank Unit := do
  sorry

-- Tests (`lake exe check` runs them for you):
-- #guard (Bank.withdraw "ana" 2 [("ana", 5)]) == .ok ([("ana", 3)], ())
-- #guard (Bank.withdraw "ana" 9 [("ana", 5)]) == .error "not enough money in ana"

def Bank.deposit (name : String) (amount : Nat) : Bank Unit := do
  Bank.setBalance name ((← Bank.balance name) + amount)

/-- Moves `amount` from one account to another. Write it with `withdraw` and
`deposit`: if any step fails, the whole transfer fails, and no money is lost. -/
def Bank.transfer (source target : String) (amount : Nat) : Bank Unit := do
  sorry

-- Tests (`lake exe check` runs them for you):
-- #guard (Bank.transfer "ana" "bo" 4 [("ana", 5), ("bo", 1)]) == .ok ([("ana", 1), ("bo", 5)], ())
-- #guard (Bank.transfer "ana" "cy" 4 [("ana", 5), ("bo", 1)]) == .error "no account cy"

end Monads
