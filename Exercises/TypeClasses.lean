-- Stuck? The solutions are in `Solutions/TypeClasses.lean`.
-- Contributors: this file is generated from `Solutions/TypeClasses.lean`;
-- edit that file and run `python3 scripts/generate.py`.

/-!
# Module 4 — Overloading and type classes

The same symbol often means different things for different types: `+` adds
natural numbers, integers and floats, each with its own code, and `s!` turns
numbers, booleans and lists into text. This module shows how Lean decides
which code to use, and how to make your own types work with `+`, `s!`,
`xs[i]`, `==` and the rest of the familiar notation.

Goals:
* Declare type classes and give instances of them.
* Write polymorphic functions that require instances, and instances that
  depend on other instances.
* Overload arithmetic between different types with `HAdd`, `HMul` and
  friends.
* Work with arrays, and make your own types indexable with `xs[i]`.
* Use the standard classes: `BEq`, `Ord`, `Hashable`, `Functor` and more.
* Convert between types automatically with coercions.

Read alongside: *Functional Programming in Lean*, chapter 3
(https://lean-lang.org/functional_programming_in_lean/Overloading-and-Type-Classes/).
Each section of this file covers a section of the chapter, with its own
explanation, so you can also work without the book.
-/

namespace TypeClasses

/-! ## 1. Classes and instances

Suppose a shop keeps its prices as a number of cents, to avoid the rounding
errors of `Float`. A structure with one field keeps prices apart from other
numbers, so we can't add a price to a quantity by mistake: -/

structure Money where
  cents : Nat
  deriving BEq, Repr

/-! But now `{ cents := 250 } + { cents := 199 }` is an error, because Lean
doesn't know how to add two `Money` values. It knows how to add `Nat`s,
`Int`s and `Float`s, each in a different way. How does it pick?

The answer is a *type class*: a named collection of operations that types
can provide. A class is declared like a structure, with `class`; its fields
are the operations, and the type is an argument. An *instance* of the class
for a particular type gives the code of those operations for that type. Here
is a class of our own, for things that can describe themselves in words: -/

class Describe (α : Type) where
  describe : α → String

instance instDescribeBool : Describe Bool where
  describe b := if b then "yes" else "no"

instance instDescribeNat : Describe Nat where
  describe n := if n == 0 then "none" else if n == 1 then "one" else "many"

#eval Describe.describe true  -- "yes"
#eval Describe.describe 7     -- "many"

/-! When we write `Describe.describe 7`, Lean sees that the argument is a
`Nat` and goes looking for an instance of `Describe Nat`. This *instance
search* happens while the program is checked, not while it runs. If there is
no instance, the program is rejected: `Describe.describe "hi"` is an error.

Lean's own notation works the same way. `a + b` is an operation of the class
`Add`, `s!"{x}"` uses the class `ToString`, and even a number literal like
`5` is overloaded with the class `OfNat`: `OfNat α 5` says how to read `5` as
a value of type `α`. To give `Money` all three, we write instances.

Read more: https://lean-lang.org/functional_programming_in_lean/Overloading-and-Type-Classes/Positive-Numbers/
-/

/-- Adds two amounts of money. -/
instance instAddMoney : Add Money where
  add _ _ := sorry

-- Tests (`lake exe check` runs them for you):
-- #guard ({ cents := 250 } + { cents := 199 } : Money) == { cents := 449 }

/-- A literal `n` of type `Money` means `n` whole dollars. -/
instance instOfNatMoney (n : Nat) : OfNat Money n where
  ofNat := sorry

-- Tests (`lake exe check` runs them for you):
-- #guard (3 : Money) == { cents := 300 }
-- #guard (0 : Money) == { cents := 0 }

/-- Shows an amount with a dollar sign and exactly two digits of cents:
`$4.49`, `$3.05`, `$0.00`.

Hint: `/ 100` gives the dollars and `% 100` the cents left over. -/
instance instToStringMoney : ToString Money where
  toString _ := sorry

-- Tests (`lake exe check` runs them for you):
-- #guard toString ({ cents := 449 } : Money) = "$4.49"
-- #guard toString ({ cents := 305 } : Money) = "$3.05"
-- #guard s!"total: {(2 : Money)}" = "total: $2.00"

/-! ## 2. Type classes and polymorphism

With instances for `Money`, we can add prices. But a function that adds up a
list of prices would look exactly like one that adds up a list of numbers,
and we don't want to write it once per type. In module 1, polymorphic
functions solved this kind of problem with a type argument `α`. That alone
is not enough here: an arbitrary `α` might have no `+`.

So a function can also ask for an instance, with an argument in square
brackets. `[Add α]` means "any type `α`, *provided* it has an instance of
`Add`". The caller never writes this argument: instance search finds it at
every call. You can see these arguments in the types of many functions you
already use: -/

#check @IO.println  -- {α : Type u_1} → [ToString α] → α → IO Unit

def double [Add α] (x : α) : α := x + x

#eval double 21           -- 42
#eval double (1.5 : Float) -- 3.000000

/-! Instances can ask for instances too. If we can describe an `α`, we can
describe a list of them, by describing each entry. The instance below works
for lists of *any* describable type, and instance search assembles the right
code step by step: for a `List (List Bool)` it uses this instance twice, and
then the one for `Bool`.

Read more: https://lean-lang.org/functional_programming_in_lean/Overloading-and-Type-Classes/Type-Classes-and-Polymorphism/
-/

instance instDescribeList [Describe α] : Describe (List α) where
  describe xs := ", ".intercalate (xs.map Describe.describe)

#eval Describe.describe [[true], [false, true]]  -- "yes, no, yes"

/-! (In the type of `IO.println` above, `Type u_1` is the same as `Type` for
everything in this module; module 6 explains the difference.) -/

/-- `none` is described as `"nothing"`, and `some x` as `"just "` followed by
the description of `x`. -/
instance instDescribeOption [Describe α] : Describe (Option α) where
  describe _ := sorry

-- Tests (`lake exe check` runs them for you):
-- #guard Describe.describe (some true) = "just yes"
-- #guard Describe.describe (none : Option Nat) = "nothing"
-- #guard Describe.describe [some 1, none] = "just one, nothing"

/-- Adds all the entries of a list to `start`. -/
def addAll [Add α] (start : α) : List α → α
  | _ => sorry

-- Tests (`lake exe check` runs them for you):
-- #guard addAll 0 [1, 2, 3] = 6
-- #guard addAll (0 : Money) [{ cents := 150 }, 2] == { cents := 350 }
-- #guard addAll (10 : Int) [-3, -4] = 3

/-! A point in the plane can have coordinates of any type: `Nat`, `Int`,
`Float`, or even `Money`. -/

structure Vec2 (α : Type) where
  x : α
  y : α
  deriving BEq, Repr

/-- Two vectors are added coordinate by coordinate, for any type of
coordinates that can be added. -/
instance instAddVec2 [Add α] : Add (Vec2 α) where
  add _ _ := sorry

-- Tests (`lake exe check` runs them for you):
-- #guard ({ x := 1, y := 2 } + { x := 10, y := 20 } : Vec2 Nat) == { x := 11, y := 22 }
-- #guard double ({ x := -1, y := 3 } : Vec2 Int) == { x := -2, y := 6 }

/-! ## 3. Controlling instance search

`Add` only adds two values of the *same* type. But sometimes the types
differ: a shop multiplies a quantity, a `Nat`, by a price, a `Money`, and the
result is `Money`. For this, `+`, `*`, `-` and `/` are really defined with
*heterogeneous* classes: `a * b` means `HMul.hMul a b`, from the class
`HMul α β γ`, where `α` and `β` are the types of the arguments and `γ` is the
type of the result. Lean provides an instance of `HMul α α α` for every type
with `Mul`, which is why ordinary multiplication works.

There is a subtlety in how Lean searches. Normally, instance search starts
only once all the types in the class are known. But when we write `3 * p`,
nobody has told Lean the type of the result: that is exactly what the
instance should decide. So the last argument of `HMul` is marked as an
*output parameter*, `outParam`. Instance search starts as soon as the input
types are known, and the instance it finds fixes the output type.

Read more: https://lean-lang.org/functional_programming_in_lean/Overloading-and-Type-Classes/Controlling-Instance-Search/
-/

#check @HMul.hMul
-- {α : Type u_1} → {β : Type u_2} → {γ : outParam (Type u_3)} → [self : HMul α β γ] → α → β → γ

/-! Our own classes can use output parameters as well. In this class, the
type of a container decides the type of its entries: -/

class Container (c : Type) (elem : outParam Type) where
  firstEntry? : c → Option elem

instance instContainerString : Container String Char where
  firstEntry? s := s.toList.head?

#eval Container.firstEntry? "hello"  -- some 'h'

/-- A quantity times a price: `3 * price`. -/
instance instHMulNatMoney : HMul Nat Money Money where
  hMul _ _ := sorry

-- Tests (`lake exe check` runs them for you):
-- #guard (3 * ({ cents := 125 } : Money)) == { cents := 375 }
-- #guard toString (2 * (5 : Money) + { cents := 1 }) = "$10.01"

/-- Splits a bill between `n` people, `bill / n`. Each pays the amount rounded
down to the cent. -/
instance instHDivMoneyNat : HDiv Money Nat Money where
  hDiv _ _ := sorry

-- Tests (`lake exe check` runs them for you):
-- #guard ((10 : Money) / 4) == { cents := 250 }
-- #guard (({ cents := 100 } : Money) / 3) == { cents := 33 }

/-! ## 4. Arrays and indexing

Module 3 used `#[...]` arrays once. Lists are built from `::` cells, so
reaching the entry at position `i` means walking past `i` cells. An *array*
stores its entries next to each other in memory, so `xs[i]` is immediate,
and adding an entry at the end with `push` is fast too. Lean's arrays are
values, like everything else: `push` returns a new array. (When nobody else
uses the old one, Lean quietly reuses its memory, so this costs nothing.)

`xs[i]` is itself overloaded with a class, `GetElem`, which says, for a type
of collection and a type of index, what the entries are and when an index is
valid. Its instance for arrays says that the entries of `Array α` are `α`s
and that `i` is valid when `i < xs.size`. That validity condition is the
proposition that `xs[i]` asks evidence for, as in module 3.

Read more: https://lean-lang.org/functional_programming_in_lean/Overloading-and-Type-Classes/Arrays-and-Indexing/
-/

#eval #[1, 2, 3].push 4         -- #[1, 2, 3, 4]
#eval #[1, 2, 3].size           -- 3
#eval #["a", "b", "c"][2]       -- "c"
#eval #[1, 2, 3].map (· * 10)   -- #[10, 20, 30]

/-- The running totals of an array: the entry at position `i` is the sum of
the entries of `xs` from 0 up to `i`.

Hint: use `Id.run do`, a `for` loop and `let mut`, as in module 2, starting
from the empty array `#[]`. -/
def runningTotals (xs : Array Nat) : Array Nat := Id.run do
  sorry

-- Tests (`lake exe check` runs them for you):
-- #guard runningTotals #[1, 2, 3, 4] = #[1, 3, 6, 10]
-- #guard runningTotals #[] = #[]

/-! A structure with three entries of the same type: -/

structure Triple (α : Type) where
  a : α
  b : α
  c : α
  deriving BEq, Repr

/-- Makes `t[i]` work for a `Triple`, for `i < 3`: `t[0]` is `t.a`, `t[1]` is
`t.b` and `t[2]` is `t.c`. The third argument of `getElem` is the evidence
that `i < 3`, which you don't need. -/
instance instGetElemTriple : GetElem (Triple α) Nat α (fun _ i => i < 3) where
  getElem _ _ _ := sorry

-- Tests (`lake exe check` runs them for you):
-- #guard (({ a := "x", b := "y", c := "z" } : Triple String))[1] = "y"
-- #guard (({ a := 7, b := 8, c := 9 } : Triple Nat))[2] = 9
-- #guard (({ a := 7, b := 8, c := 9 } : Triple Nat))[0] = 7

/-! ## 5. Standard classes

Most of Lean's notation is a class you can provide for your own types. Some
of the most useful ones are:

| Notation or function | Class        | What the instance gives                    |
|----------------------|--------------|--------------------------------------------|
| `a == b`             | `BEq`        | equality as a `Bool`                       |
| `compare a b`, `<`   | `Ord`        | an `Ordering`: `.lt`, `.eq` or `.gt`       |
| `hash a`             | `Hashable`   | a `UInt64`, for hash maps                  |
| `a ++ b`             | `Append`     | joining two values                         |
| `#eval a`            | `Repr`       | how to show a value                        |
| `xs[i]!`, `default`  | `Inhabited`  | a default value                            |
| `f <$> x`            | `Functor`    | applying `f` to every entry inside `x`     |

Writing these instances by hand is usually mechanical, so Lean can write many
of them for us. That is what `deriving BEq, Repr` has been doing since
module 1. Derived instances follow the structure of the type: a derived `Ord`
on a structure compares the first field first, and only looks at the second
when the first fields are equal.

`Functor` is different from the rest: its instances are not for a type like
`Nat`, but for a type *constructor* like `List` or `Option`, which builds a
type from another one. `f <$> xs` applies `f` to everything inside `xs`, and
keeps the shape: for a list it is `List.map`, and for an `Option` it applies
`f` to the value, if there is one.

Read more: https://lean-lang.org/functional_programming_in_lean/Overloading-and-Type-Classes/Standard-Classes/
-/

#eval compare 3 5                     -- Ordering.lt
#eval (· + 1) <$> [1, 2, 3]           -- [2, 3, 4]
#eval (· + 1) <$> (some 41)           -- some 42
#eval (· + 1) <$> (none : Option Nat) -- none

/-! The version number of a program has three parts. -/

structure Version where
  major : Nat
  minor : Nat
  patch : Nat
  deriving BEq, Repr

/-- Compares two versions: first by `major`, then by `minor`, then by
`patch`.

Hint: `o₁.then o₂` is `o₁`, unless `o₁` is `.eq`, in which case it is `o₂`. -/
instance instOrdVersion : Ord Version where
  compare _ _ := sorry

-- Tests (`lake exe check` runs them for you):
-- #guard compare (Version.mk 1 2 3) (Version.mk 1 10 0) == .lt
-- #guard compare (Version.mk 2 0 0) (Version.mk 1 9 9) == .gt
-- #guard compare (Version.mk 1 2 3) (Version.mk 1 2 3) == .eq

/-- The newest version among `v` and the versions of the list. -/
def newest (v : Version) : List Version → Version
  | _ => sorry

-- Tests (`lake exe check` runs them for you):
-- #guard newest ⟨1, 0, 0⟩ [⟨1, 2, 0⟩, ⟨0, 9, 9⟩, ⟨1, 1, 5⟩] == ⟨1, 2, 0⟩
-- #guard newest ⟨3, 0, 0⟩ [] == ⟨3, 0, 0⟩

/-- Applies `f` to each of the three entries. -/
instance instFunctorTriple : Functor Triple where
  map _ _ := sorry

-- Tests (`lake exe check` runs them for you):
-- #guard ((· * 2) <$> ({ a := 1, b := 2, c := 3 } : Triple Nat)) == { a := 2, b := 4, c := 6 }
-- #guard (toString <$> ({ a := 1, b := 2, c := 3 } : Triple Nat)) == { a := "1", b := "2", c := "3" }

/-! ## 6. Coercions

Sometimes a value of one type is perfectly usable where another type is
expected. A `Triple` holds three entries, so a function that wants a list
could take a triple, and it's annoying to convert it by hand every time. A
*coercion* tells Lean how to convert automatically: when it finds a value of
type `α` where a `β` is expected, it looks for an instance of `Coe α β` and
inserts the conversion for you.

There are a few variations of the idea:

* `CoeFun` lets a value that isn't a function be *used* as one, as in `f x`.
  The instance says which function type to use, as a function of the value.
* `CoeSort` lets a value be used as a type, as in `(x : s)`.
* `CoeDep` is a coercion that only applies to some particular values.

Read more: https://lean-lang.org/functional_programming_in_lean/Overloading-and-Type-Classes/Coercions/
-/

instance instCoeVersionTriple : Coe Version (Triple Nat) where
  coe v := { a := v.major, b := v.minor, c := v.patch }

def largest (t : Triple Nat) : Nat := max t.a (max t.b t.c)

#eval largest (Version.mk 1 12 4)  -- 12: the version became a triple

/-- Turns a triple into a list of its three entries, automatically. -/
instance instCoeTripleList : Coe (Triple α) (List α) where
  coe _ := sorry

-- Tests (`lake exe check` runs them for you):
-- #guard List.length (({ a := 0, b := 0, c := 0 } : Triple Nat) : List Nat) = 3
-- #guard List.sum (({ a := 1, b := 2, c := 3 } : Triple Nat) : List Nat) = 6

/-- A straight line, `y = slope * x + intercept`. -/
structure Line where
  slope : Int
  intercept : Int

/-- Makes a line usable as a function: `l x` is the height of the line at `x`. -/
instance instCoeFunLine : CoeFun Line (fun _ => Int → Int) where
  coe _ := sorry

-- Tests (`lake exe check` runs them for you):
-- #guard (Line.mk 2 1) 3 = 7
-- #guard (Line.mk (-1) 0) 5 = -5
-- #guard [1, 2, 3].map (Line.mk 10 0) = [10, 20, 30]

/-! ## 7. Additional conveniences

We have been naming our instances, like `instAddMoney`. The name is
optional: `instance : Add Money where ...` works too, and Lean then invents a
name. Naming them makes error messages and documentation easier to read.

An instance is a structure, so the anonymous constructor `⟨...⟩` from
module 1 also builds instances, with the operations in the order of the
class's fields. It is handy for classes with one operation.

Finally, `example` (from module 3) also works for definitions, not only
proofs: `example : Money := 3` checks that the definition is accepted, and
then throws it away.

Read more: https://lean-lang.org/functional_programming_in_lean/Overloading-and-Type-Classes/Additional-Conveniences/
-/

instance instDescribeString : Describe String := ⟨fun s => s!"\"{s}\""⟩

example : Money := 3

/-- Shows a version as `major.minor.patch`. Use the anonymous constructor. -/
instance instToStringVersion : ToString Version :=
  sorry

-- Tests (`lake exe check` runs them for you):
-- #guard toString (Version.mk 4 34 1) = "4.34.1"

/-! ## Final project of the module: Fibonacci with matrices

Raising to a power only needs a multiplication and a `1`, so it can be
written once for every type that has them, with classes. The surprise is
that powers of the right 2×2 matrix give the Fibonacci numbers. -/

/-- A 2×2 matrix of natural numbers, written by rows:

    | a b |
    | c d | -/
structure Mat2 where
  a : Nat
  b : Nat
  c : Nat
  d : Nat
  deriving BEq, Repr

/-- The product of two matrices. Each entry of the result is a row of the
first matrix times a column of the second:

    | a b |   | e f |   | a*e + b*g   a*f + b*h |
    | c d | * | g h | = | c*e + d*g   c*f + d*h | -/
instance instMulMat2 : Mul Mat2 where
  mul _ _ := sorry

-- Tests (`lake exe check` runs them for you):
-- #guard Mat2.mk 1 2 3 4 * Mat2.mk 5 6 7 8 == Mat2.mk 19 22 43 50

/-- The literal `1` for matrices is the identity: `1` on the diagonal and `0`
elsewhere. -/
instance instOneMat2 : OfNat Mat2 1 where
  ofNat := sorry

-- Tests (`lake exe check` runs them for you):
-- #guard (1 : Mat2) * Mat2.mk 1 2 3 4 == Mat2.mk 1 2 3 4

/-- `x` multiplied by itself `n` times, for any type with `*` and `1`.
`power x 0` is `1`. -/
def power [Mul α] [OfNat α 1] (x : α) : Nat → α
  | _ => sorry

-- Tests (`lake exe check` runs them for you):
-- #guard power 2 10 = 1024
-- #guard power (3 : Int) 3 = 27
-- #guard power (Mat2.mk 1 1 1 0) 2 == Mat2.mk 2 1 1 1

/-- The `n`-th Fibonacci number is the top-right entry of the `n`-th power of
`| 1 1 |, | 1 0 |`. -/
def fib (n : Nat) : Nat := (power (Mat2.mk 1 1 1 0) n).b

-- Once `power` works: [0, 1, 1, 2, 3, 5, 8, 13, 21, 34]
-- #eval (List.range 10).map fib

end TypeClasses
