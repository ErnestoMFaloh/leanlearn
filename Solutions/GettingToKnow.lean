/-!
# Module 1 — Getting to know Lean

Goals:
* Evaluate expressions with `#eval` and inspect types with `#check`.
* Define functions and types with `def`.
* Group data in structures and update them.
* Define inductive types and use them with pattern matching and recursion.
* Write polymorphic functions with `List`, `Option`, `Prod` and `Sum`.
* Work with characters and strings.

Read alongside: *Functional Programming in Lean*, chapter 1. Each section of
this file follows a section of the chapter.

Tip: open this file in VS Code with the "Lean 4" extension and watch
the *Lean Infoview* panel on the right as you move the cursor.
-/

namespace GettingToKnow

/-! ## 1. Evaluating expressions

`#eval` computes the value of an expression. Function application is written
with spaces, not parentheses: `String.append "Hello, " "Lean"`.
-/

#eval 1 + 2 * 5                          -- 11
#eval String.append "Hello, " "Lean"     -- "Hello, Lean"
#eval if 3 == 3 then 5 else 7            -- 5

-- Try it: work out these values by hand, then check them with `#eval`.
--   42 + 19
--   String.append "A" (String.append "B" "C")
--   if 3 == 4 then "equal" else "not equal"

/-! ## 2. Types

Every expression has a type. `#check` shows it, and `(e : T)` asks Lean to
read `e` with type `T`.
-/

#check 42                 -- 42 : Nat
#check "text"             -- "text" : String
#check (1 - 2 : Int)      -- 1 - 2 : Int
#eval (1 - 2 : Nat)       -- 0: natural numbers never go below zero
#eval (1 - 2 : Int)       -- -1

/-! ## 3. Functions and definitions -/

def hello := "Hello"

def add1 (n : Nat) : Nat := n + 1

def maximum (n : Nat) (k : Nat) : Nat :=
  if n < k then k else n

#eval maximum (5 + 8) (2 * 7)  -- 14

-- A function with several arguments takes them one at a time:
#check maximum      -- maximum (n k : Nat) : Nat
#check maximum 3    -- maximum 3 : Nat → Nat

-- Types are values too, so they can be given names.
def Str : Type := String
def aStr : Str := "This is a string."

/-! ## 4. Structures

A structure groups several values, each in a named *field*.
-/

structure Point where
  x : Float
  y : Float
  deriving Repr

def origin : Point := { x := 0.0, y := 0.0 }

#eval origin.x  -- 0.000000

def addPoints (p1 p2 : Point) : Point :=
  { x := p1.x + p2.x, y := p1.y + p2.y }

def distance (p1 p2 : Point) : Float :=
  Float.sqrt (((p2.x - p1.x) ^ 2.0) + ((p2.y - p1.y) ^ 2.0))

#eval distance { x := 1.0, y := 2.0 } { x := 5.0, y := -1.0 }  -- 5.000000

-- Structures are never modified: `with` builds a copy with some fields changed.
def zeroX (p : Point) : Point := { p with x := 0 }

-- Every structure has a constructor (`Point.mk`) and an accessor per field
-- (`Point.x`, `Point.y`). Functions in the `Point` namespace can be called with
-- dot notation: `p.modifyBoth f` means `Point.modifyBoth f p`.
def Point.modifyBoth (f : Float → Float) (p : Point) : Point :=
  { x := f p.x, y := f p.y }

#eval (Point.mk 1.2 2.6).modifyBoth Float.floor

-- Try it: which names does this declaration introduce? Use `#check` on them.
structure Hamster where
  name : String
  fluffy : Bool

/-! ## 5. Datatypes and patterns

`inductive` defines a type by listing its constructors. Pattern matching takes
a value apart by asking which constructor built it.
-/

inductive Color where
  | red | green | blue
  deriving Repr

def Color.next : Color → Color
  | .red   => .green
  | .green => .blue
  | .blue  => .red

#eval Color.red.next  -- GettingToKnow.Color.green

-- `Nat` is an inductive type too: a number is either `zero` or `succ n`
-- (written `n + 1` in patterns).
def isZero : Nat → Bool
  | 0     => true
  | _ + 1 => false

-- Recursion: Lean checks that it terminates, and it can when every recursive
-- call is on a smaller argument (`n` instead of `n + 1`).
def factorial : Nat → Nat
  | 0     => 1
  | n + 1 => (n + 1) * factorial n

#eval factorial 10  -- 3628800

def fib : Nat → Nat
  | 0     => 0
  | 1     => 1
  | n + 2 => fib n + fib (n + 1)

#eval (List.range 10).map fib

/-! ## 6. Polymorphism

Functions and types can take other types as arguments. Arguments in curly
braces, like `{α : Type}`, are *implicit*: Lean works them out by itself.
-/

def sum : List Nat → Nat
  | []      => 0
  | x :: xs => x + sum xs

#eval sum [1, 2, 3, 4, 5]  -- 15

-- `Option α` is a value of type `α` that may be missing: `some x` or `none`.
def firstEntry? {α : Type} : List α → Option α
  | []     => none
  | x :: _ => some x

#eval firstEntry? [3, 4]             -- some 3
#eval firstEntry? ([] : List Nat)    -- none

-- `α × β` (a `Prod`) holds a value of each type: `(3, "three")`.
def fives : String × Int := ("five", 5)

#eval fives.fst  -- "five"

-- `α ⊕ β` (a `Sum`) holds a value of one type or the other.
def PetName : Type := String ⊕ String  -- `inl` for dogs, `inr` for cats

def animals : List PetName :=
  [Sum.inl "Spot", Sum.inr "Tiger", Sum.inl "Fifi", Sum.inl "Rex", Sum.inr "Floof"]

/-! ## 7. Characters and strings

Strings are written in double quotes and characters (`Char`) in single quotes.
-/

#eval "Hello".push '!'                   -- "Hello!"
#eval "lean".toUpper                     -- "LEAN"
#eval "a,b,c".splitOn ","                -- ["a", "b", "c"]
#eval "hello".toList                     -- ['h', 'e', 'l', 'l', 'o']
#eval 'a'.isAlpha                        -- true

-- Operations such as `drop` return a *slice*: a view into the original string,
-- without copying it. `copy` turns a slice back into a string.
#eval (("small tortoiseshell".drop 6).dropEnd 5).copy  -- "tortoise"

/-! ## 8. Additional conveniences -/

-- `let` names an intermediate value.
def hypotenuse (a b : Float) : Float :=
  let squares := a * a + b * b
  Float.sqrt squares

#eval hypotenuse 3 4  -- 5.000000

-- `fun` writes a function without naming it; `(· + 1)` is a shorter form.
#eval [1, 2, 3].map (fun x => x * 10)  -- [10, 20, 30]
#eval [1, 2, 3].map (· + 1)            -- [2, 3, 4]

-- String interpolation with `s!`.
def greet (name : String) : String := s!"Hello, {name}!"

#eval greet "Lean"

-- `if let` checks a single pattern.
def describe (n : Option Nat) : String :=
  if let some k := n then s!"got {k}" else "nothing"

#eval describe (some 3)

/-! ## Exercises (replace every `sorry`)

Lean flags each `sorry` with a warning: the goal is for this file to
compile with none left. Run `lake exe check GettingToKnow` to see which
exercises are solved.
-/

/-! ### Functions -/

/-- Places `sep` between `a` and `b`:
`joinStringsWith ", " "one" "and another" = "one, and another"`. -/
def joinStringsWith (sep a b : String) : String :=
  -- SOLUTION
  a ++ sep ++ b
  -- END SOLUTION

-- TESTS
#guard joinStringsWith ", " "one" "and another" = "one, and another"
#guard joinStringsWith "" "a" "b" = "ab"
-- END TESTS

-- Try it: what is the type of `joinStringsWith ": "`? Check it with `#check`.

/-- The volume of a rectangular prism with the given height, width and depth. -/
def volume (height width depth : Nat) : Nat :=
  -- SOLUTION
  height * width * depth
  -- END SOLUTION

-- TESTS
#guard volume 2 3 4 = 24
#guard volume 5 0 7 = 0
-- END TESTS

/-! ### Structures -/

structure RectangularPrism where
  height : Float
  width : Float
  depth : Float
  deriving Repr

/-- The volume of a rectangular prism. -/
def RectangularPrism.volume (prism : RectangularPrism) : Float :=
  -- SOLUTION
  prism.height * prism.width * prism.depth
  -- END SOLUTION

-- TESTS
#guard (RectangularPrism.mk 2.0 3.0 4.0).volume == 24.0
#guard ({ height := 1.5, width := 2.0, depth := 1.0 } : RectangularPrism).volume == 3.0
-- END TESTS

/-- A line segment, given by its two endpoints. -/
structure Segment where
  start : Point
  stop : Point
  deriving Repr

/-- The length of a segment. Hint: there is a function above that helps. -/
def Segment.length (s : Segment) : Float :=
  -- SOLUTION
  distance s.start s.stop
  -- END SOLUTION

-- TESTS
#guard (Segment.mk ⟨0.0, 0.0⟩ ⟨3.0, 4.0⟩).length == 5.0
#guard (Segment.mk ⟨1.0, 1.0⟩ ⟨1.0, 1.0⟩).length == 0.0
-- END TESTS

/-! ### Datatypes and patterns -/

/-- A binary tree of natural numbers. -/
inductive Tree where
  | leaf
  | node (left : Tree) (value : Nat) (right : Tree)
  deriving Repr, DecidableEq

/-- The number of values stored in the tree. -/
def Tree.size : Tree → Nat
  -- SOLUTION: | _ => sorry
  | .leaf              => 0
  | .node left _ right => left.size + 1 + right.size
  -- END SOLUTION

-- TESTS
#guard Tree.leaf.size = 0
#guard (Tree.node .leaf 5 .leaf).size = 1
#guard (Tree.node (.node .leaf 1 .leaf) 2 (.node .leaf 3 (.node .leaf 4 .leaf))).size = 4
-- END TESTS

/-- A pet, with its name. This is `PetName` from section 6, with informative
constructor names instead of `Sum.inl` and `Sum.inr`. -/
inductive Pet where
  | dog (name : String)
  | cat (name : String)

/-- How many dogs there are in a list of pets. Compare it with writing the
same function for `List PetName`: which one is easier to read? -/
def howManyDogs : List Pet → Nat
  -- SOLUTION: | _ => sorry
  | []             => 0
  | .dog _ :: pets => howManyDogs pets + 1
  | .cat _ :: pets => howManyDogs pets
  -- END SOLUTION

-- TESTS
#guard howManyDogs [] = 0
#guard howManyDogs [.dog "Spot", .cat "Tiger", .dog "Fifi", .dog "Rex", .cat "Floof"] = 3
-- END TESTS

/-! ### Polymorphism -/

/-- The length of a list. -/
def length {α : Type} : List α → Nat
  -- SOLUTION: | _ => sorry
  | []      => 0
  | _ :: xs => 1 + length xs
  -- END SOLUTION

-- TESTS
#guard length ([] : List Nat) = 0
#guard length [7] = 1
#guard length ["a", "b", "c"] = 3
-- END TESTS

/-- Reverses a list. Hint: `++` appends two lists. -/
def reverse {α : Type} : List α → List α
  -- SOLUTION: | _ => sorry
  | []      => []
  | x :: xs => reverse xs ++ [x]
  -- END SOLUTION

-- TESTS
#guard reverse ([] : List Nat) = []
#guard reverse [1] = [1]
#guard reverse [1, 2, 3] = [3, 2, 1]
#guard reverse ["a", "b"] = ["b", "a"]
-- END TESTS

/-- The last entry of a list, or `none` if the list is empty. -/
def last? {α : Type} : List α → Option α
  -- SOLUTION: | _ => sorry
  | []      => none
  | [x]     => some x
  | _ :: xs => last? xs
  -- END SOLUTION

-- TESTS
#guard last? ([] : List Nat) = none
#guard last? [1, 2, 3] = some 3
#guard last? ["only"] = some "only"
-- END TESTS

/-- The first entry of `xs` that satisfies `predicate`, if there is one. -/
def List.findFirst? {α : Type} (xs : List α) (predicate : α → Bool) : Option α :=
  -- SOLUTION
  match xs with
  | []      => none
  | x :: xs => if predicate x then some x else List.findFirst? xs predicate
  -- END SOLUTION

-- TESTS
#guard List.findFirst? [1, 4, 6, 7] (· % 2 == 0) = some 4
#guard List.findFirst? [1, 3, 5] (· % 2 == 0) = none
-- END TESTS

/-- Switches the two fields of a pair. -/
def Prod.switch {α β : Type} (pair : α × β) : β × α :=
  -- SOLUTION
  (pair.snd, pair.fst)
  -- END SOLUTION

-- TESTS
#guard Prod.switch (1, "one") = ("one", 1)
-- END TESTS

/-- Combines two lists into a list of pairs, as long as the shorter list. -/
def zip {α β : Type} (xs : List α) (ys : List β) : List (α × β) :=
  -- SOLUTION
  match xs, ys with
  | x :: xs, y :: ys => (x, y) :: zip xs ys
  | _, _             => []
  -- END SOLUTION

-- TESTS
#guard zip [1, 2, 3] ["a", "b"] = [(1, "a"), (2, "b")]
#guard zip ([] : List Nat) [true] = []
-- END TESTS

/-- The first `n` entries of a list, or the whole list if it is shorter. -/
def take {α : Type} (n : Nat) (xs : List α) : List α :=
  -- SOLUTION
  match n, xs with
  | n + 1, x :: xs => x :: take n xs
  | _, _           => []
  -- END SOLUTION

-- TESTS
#guard take 3 ["bolete", "oyster"] = ["bolete", "oyster"]
#guard take 1 ["bolete", "oyster"] = ["bolete"]
#guard take 0 [1, 2] = []
-- END TESTS

/-! Types behave like arithmetic: `α × β` is like a product and `α ⊕ β` like a
sum. The next two exercises turn arithmetic laws into programs. -/

/-- `a * (b + c) = a * b + a * c`, as a program. -/
def distribute {α β γ : Type} (pair : α × (β ⊕ γ)) : (α × β) ⊕ (α × γ) :=
  -- SOLUTION
  match pair with
  | (a, .inl b) => .inl (a, b)
  | (a, .inr c) => .inr (a, c)
  -- END SOLUTION

-- TESTS
#guard distribute (1, (.inl "b" : String ⊕ Bool)) = .inl (1, "b")
#guard distribute (1, (.inr true : String ⊕ Bool)) = .inr (1, true)
-- END TESTS

/-- `2 * a = a + a`, as a program: `true` picks the left side. -/
def doubleToSum {α : Type} (pair : Bool × α) : α ⊕ α :=
  -- SOLUTION
  match pair with
  | (true, a)  => .inl a
  | (false, a) => .inr a
  -- END SOLUTION

-- TESTS
#guard doubleToSum (true, 5) = .inl 5
#guard doubleToSum (false, 5) = .inr 5
-- END TESTS

/-! ### Strings -/

/-- How many times the character `c` appears in `s`. Hint: `s.toList`. -/
def countChar (c : Char) (s : String) : Nat :=
  -- SOLUTION
  (s.toList.filter (· == c)).length
  -- END SOLUTION

-- TESTS
#guard countChar 'l' "hello world" = 3
#guard countChar 'z' "lean" = 0
-- END TESTS

/-! ## Final project of the module: a binary search tree

In a *binary search tree*, every value in a node's left subtree is smaller than
the node's value, and every value in its right subtree is larger. -/

/-- Inserts `n` in a binary search tree, keeping it ordered. If `n` is already
there, the tree doesn't change. -/
def Tree.insert (n : Nat) : Tree → Tree
  -- SOLUTION: | _ => sorry
  | .leaf => .node .leaf n .leaf
  | .node left v right =>
    if n < v then .node (left.insert n) v right
    else if v < n then .node left v (right.insert n)
    else .node left v right
  -- END SOLUTION

-- TESTS
#guard Tree.leaf.insert 3 = .node .leaf 3 .leaf
#guard (Tree.node .leaf 5 .leaf).insert 2 = .node (.node .leaf 2 .leaf) 5 .leaf
#guard (Tree.node .leaf 5 .leaf).insert 7 = .node .leaf 5 (.node .leaf 7 .leaf)
#guard (Tree.node .leaf 5 .leaf).insert 5 = .node .leaf 5 .leaf
-- END TESTS

/-- The values of the tree from left to right. For a binary search tree, they
come out sorted. -/
def Tree.toList : Tree → List Nat
  -- SOLUTION: | _ => sorry
  | .leaf              => []
  | .node left v right => left.toList ++ [v] ++ right.toList
  -- END SOLUTION

-- TESTS
#guard Tree.leaf.toList = []
#guard (Tree.node (.node .leaf 1 .leaf) 2 .leaf).toList = [1, 2]
#guard (Tree.node (.node .leaf 1 .leaf) 3 (.node .leaf 4 (.node .leaf 8 .leaf))).toList = [1, 3, 4, 8]
-- END TESTS

-- Try it, once both are solved: build a tree by inserting a list of numbers.
-- #eval ([5, 3, 8, 1, 4, 3].foldl (fun t n => t.insert n) Tree.leaf).toList

end GettingToKnow
