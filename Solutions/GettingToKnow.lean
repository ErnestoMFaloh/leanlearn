/-!
# Module 1 — Getting to know Lean

This first module is a tour of Lean as a programming language. We start with
the smallest possible programs, single expressions, and add one idea at a time
until we can define our own types and write recursive functions on them. By the
end you will have built a binary search tree from scratch.

Goals:
* Evaluate expressions with `#eval` and inspect their types with `#check`.
* Define functions and give names to types with `def`.
* Group data in structures, and build updated copies of them.
* Define your own types with `inductive`, and take values apart with pattern
  matching and recursion.
* Write polymorphic functions with `List`, `Option`, `Prod` and `Sum`.
* Work with characters, strings and slices.
* Use the conveniences that make definitions shorter: `fun`, `·` and string
  interpolation.

Read alongside: *Functional Programming in Lean*, chapter 1
(https://lean-lang.org/functional_programming_in_lean/Getting-to-Know-Lean/).
Each section of this file covers a section of the chapter and explains what
you need for its exercises, so you can also work without the book.

Tip: open this file in VS Code with the "Lean 4" extension and watch the
*Lean Infoview* panel on the right as you move the cursor.
-/

namespace GettingToKnow

/-! ## 1. Evaluating expressions

In most programming languages, a program is a list of instructions that the
computer follows one after the other, changing things in memory as it goes.
Lean works differently. A program in Lean is an *expression*, like `1 + 2`,
and running it means working out its value, just as you would simplify an
expression in a maths textbook. Nothing changes along the way: `1 + 2` simply
*is* `3`.

To see this in action, we need a way to ask Lean for the value of an
expression. That is what the command `#eval` does: it evaluates what follows
and shows the result in the Infoview. Move the cursor over the line below.

Read more: https://lean-lang.org/functional_programming_in_lean/Getting-to-Know-Lean/Evaluating-Expressions/
-/

#eval 7 * (3 + 2)                       -- 35

/-! Arithmetic is only the beginning. Most of the expressions you will write
call functions, and here Lean looks different from most languages. Instead of
`String.append("Good ", "morning")`, you write the function followed by its
arguments, separated by spaces. Parentheses are only needed to group things,
for example when an argument is itself a function call: -/

#eval String.append "Good " "morning"                       -- "Good morning"
#eval String.append "Good " (String.append "after" "noon")  -- "Good afternoon"

/-! Joining strings is so common that it also has an operator, `++`, which
reads more naturally when several pieces are involved: -/

#eval "Good " ++ "after" ++ "noon"  -- "Good afternoon"

/-! Since everything is an expression, even a decision is one. An `if` has a
value, which is the value of whichever branch is chosen, and for that reason
the `else` branch can never be left out: without it, the expression would have
no value when the condition is false. Conditions compare values with `<`, `>`,
or `==`, which asks whether two values are equal. -/

#eval if 10 > 3 then "big" else "small"  -- "big"

/-- Work out by hand the value of this expression, without running it:

    String.append "con" (if 2 * 3 == 6 then "cat" else "dog")

Write that value here. The test evaluates the expression and compares. -/
def predictedString : String :=
  -- SOLUTION
  "concat"
  -- END SOLUTION

-- TESTS
#guard predictedString = String.append "con" (if 2 * 3 == 6 then "cat" else "dog")
-- END TESTS

/-! ## 2. Types

You may have wondered what would happen with `String.append 3 "cats"`. It
makes no sense to append a number to a string, and Lean refuses it before
anything runs. It can do that because every expression in Lean has a *type*,
which describes what kind of value it is: `Nat` for the natural numbers
(0, 1, 2, ...), `String` for text, `Bool` for `true` and `false`, and so on.
Lean checks that the types of a program fit together before running it, which
catches many mistakes early.

The command `#check` shows the type of an expression, without evaluating it.

Read more: https://lean-lang.org/functional_programming_in_lean/Getting-to-Know-Lean/Types/
-/

#check 42            -- 42 : Nat
#check "forty-two"   -- "forty-two" : String
#check 42 == 41      -- 42 == 41 : Bool

/-! Numbers are a little more subtle, because a number like `5` could have
several types: it could be a `Nat`, an `Int` (which also includes the negative
numbers) or a `Float` (which has decimals). Unless you say otherwise, Lean
picks `Nat`. To choose a different type, add a *type ascription*, written
`(e : T)`.

The choice matters, because the same operation can behave differently on
different types. A natural number can't be negative, so subtracting a larger
`Nat` from a smaller one gives `0`. Division of natural numbers rounds down,
and `%` gives the remainder that is left over. -/

#eval (2 - 5 : Nat)    -- 0
#eval (2 - 5 : Int)    -- -3
#eval (7 / 2 : Nat)    -- 3
#eval (7 % 2 : Nat)    -- 1
#eval (7 / 2 : Float)  -- 3.500000

/-- The value of `(3 - 5 + 4 : Nat)`. Lean reads it as `(3 - 5) + 4`. -/
def natPuzzle : Nat :=
  -- SOLUTION
  4
  -- END SOLUTION

-- TESTS
#guard natPuzzle = (3 - 5 + 4 : Nat)
-- END TESTS

/-- The value of the same expression with integers: `(3 - 5 + 4 : Int)`. -/
def intPuzzle : Int :=
  -- SOLUTION
  2
  -- END SOLUTION

-- TESTS
#guard intPuzzle = (3 - 5 + 4 : Int)
-- END TESTS

/-! ## 3. Functions and definitions

So far we had to write every expression out in full each time we wanted it.
Real programs reuse the same values and computations again and again, so the
next step is to give them names. `def` does exactly that: it gives a name to a
value, and from then on the name can be used in its place.

Read more: https://lean-lang.org/functional_programming_in_lean/Getting-to-Know-Lean/Functions-and-Definitions/
-/

def greeting : String := "Welcome!"

#eval greeting ++ " Come in."  -- "Welcome! Come in."

/-! A name for a single value is useful, but a name for a *computation* is
much more so. When a definition has arguments, it defines a function. Each
argument is written in parentheses with its name and type, after the colon
comes the type of the result, and the body after `:=` says how to compute the
result from the arguments. -/

def double (n : Nat) : Nat := n * 2

#eval double 21  -- 42

def larger (a : Nat) (b : Nat) : Nat :=
  if a > b then a else b

#eval larger 3 8  -- 8

/-! The type that `#check` shows for `larger` reveals something about how
Lean sees functions. A function with two arguments is really a function that
takes the first argument and returns *another function*, which waits for the
second one. So `larger 3` makes sense on its own: it is a function from `Nat`
to `Nat`, which returns the larger of `3` and its argument. Giving a function
only some of its arguments is called *partial application*. -/

#check larger      -- larger (a b : Nat) : Nat
#check larger 3    -- larger 3 : Nat → Nat
#eval (larger 3) 1 -- 3

/-! When a body gets longer, it helps to name its intermediate steps. Inside
a definition, `let` gives a name to a value, and the lines that follow can use
that name. Here the price before tax gets a name, so that it is written once: -/

def priceWithTax (unitPrice quantity : Nat) : Nat :=
  let before := unitPrice * quantity
  before + before / 10

#eval priceWithTax 25 4  -- 110

/-! Finally, remember that every expression has a type. Types are expressions
too, so `def` can also give a new name to a type, and the new name can be used
anywhere the old one could. -/

def Name : Type := String

def author : Name := "Ada"

/-- The number of seconds in `hours` hours and `minutes` minutes. -/
def secondsIn (hours minutes : Nat) : Nat :=
  -- SOLUTION
  hours * 3600 + minutes * 60
  -- END SOLUTION

-- TESTS
#guard secondsIn 1 30 = 5400
#guard secondsIn 0 0 = 0
-- END TESTS

/-- Keeps `n` between `low` and `high`: if it is below `low` the result is
`low`, if it is above `high` the result is `high`, and otherwise it is `n`. -/
def clamp (low high n : Nat) : Nat :=
  -- SOLUTION
  if n < low then low else if n > high then high else n
  -- END SOLUTION

-- TESTS
#guard clamp 10 20 5 = 10
#guard clamp 10 20 25 = 20
#guard clamp 10 20 15 = 15
-- END TESTS

/-- Puts `wrapper` before and after `text`: `surround "*" "hi" = "*hi*"`. -/
def surround (wrapper text : String) : String :=
  -- SOLUTION
  wrapper ++ text ++ wrapper
  -- END SOLUTION

-- TESTS
#guard surround "*" "hi" = "*hi*"
#guard surround "" "plain" = "plain"
-- END TESTS

-- Try it: what is the type of `surround "**"`? Check it with `#check`.

/-! ## 4. Structures

Numbers and strings take us a long way, but the things a program talks about
are usually made of several values. A book, for instance, has a title, a
number of pages and an edition. We could pass these three values around
separately, but it is easy to mix them up, and every function would need three
arguments. A `structure` groups them into a single value with a name for each
part. The parts are called *fields*.

Read more: https://lean-lang.org/functional_programming_in_lean/Getting-to-Know-Lean/Structures/
-/

structure Book where
  title : String
  pages : Nat
  edition : Nat
  deriving Repr

/-! The line `deriving Repr` asks Lean to write the code that displays a book,
so that `#eval` can show one.

To build a book, give a value to each field inside curly braces. To read a
field back, write its name after a dot: `b.pages` is the number of pages of
the book `b`. -/

def manual : Book := { title := "The Lean Manual", pages := 320, edition := 1 }

#eval manual.pages  -- 320

/-! Writing the field names every time is clear, but long. Every structure
also comes with a *constructor*, a function that takes the fields in order;
for `Book` it is called `Book.mk`. The angle brackets `⟨...⟩` are an even
shorter way to call it, when Lean already knows which type is expected. -/

def novel : Book := Book.mk "A Long Story" 512 3
def leaflet : Book := ⟨"Read Me", 4, 1⟩

/-! What if a book changes, say, because it is reprinted with a new title?
Remember from section 1 that values in Lean never change. Instead of modifying
the book, you build a new one, and `with` saves you from repeating the fields
that stay the same: it copies every field that you don't mention. -/

def manualSecondPrinting : Book := { manual with title := "The Lean Manual (reprint)" }

/-! Functions about books are naturally written next to the structure. If a
function's name starts with `Book.`, it lives in the *namespace* of `Book`,
and that lets you call it with a dot, as if it were a field: `b.isLong` means
`Book.isLong b`. -/

def Book.isLong (b : Book) : Bool := b.pages > 300

#eval manual.isLong   -- true
#eval leaflet.isLong  -- false

/-- A new edition of a book: it has `extraPages` more pages and its edition
number is one higher. Use `with`. -/
def Book.newEdition (b : Book) (extraPages : Nat) : Book :=
  -- SOLUTION
  { b with pages := b.pages + extraPages, edition := b.edition + 1 }
  -- END SOLUTION

-- TESTS
#guard (manual.newEdition 20).pages = 340
#guard (manual.newEdition 20).edition = 2
#guard (manual.newEdition 20).title = "The Lean Manual"
-- END TESTS

/-! The next exercises use another structure: a time of the day, in hours and
minutes. Besides `Repr`, it derives `DecidableEq`, which lets the tests check
whether two times are equal. -/

structure Time where
  hours : Nat
  minutes : Nat
  deriving Repr, DecidableEq

/-- The number of minutes since midnight: `Time.toMinutes ⟨1, 30⟩ = 90`. -/
def Time.toMinutes (t : Time) : Nat :=
  -- SOLUTION
  t.hours * 60 + t.minutes
  -- END SOLUTION

-- TESTS
#guard Time.toMinutes ⟨1, 30⟩ = 90
#guard Time.toMinutes ⟨0, 0⟩ = 0
-- END TESTS

/-- The time `m` minutes later. After 23:59 comes 0:00 again.

Hint: turn the time into minutes first, and remember `/` and `%` from
section 2. A day has `24 * 60` minutes. -/
def Time.later (t : Time) (m : Nat) : Time :=
  -- SOLUTION
  let total := (t.toMinutes + m) % (24 * 60)
  { hours := total / 60, minutes := total % 60 }
  -- END SOLUTION

-- TESTS
#guard Time.later ⟨9, 45⟩ 30 = ⟨10, 15⟩
#guard Time.later ⟨23, 50⟩ 20 = ⟨0, 10⟩
#guard Time.later ⟨12, 0⟩ 0 = ⟨12, 0⟩
-- END TESTS

/-! ## 5. Datatypes and patterns

A structure describes values made of several parts *at the same time*: a book
has a title *and* pages *and* an edition. Just as often, a value is *one of
several options*: a day is Monday, *or* Tuesday, *or* Wednesday, and so on. A
structure can't express that, so Lean has a second way to define types. An
`inductive` type lists the options, and each option is called a
*constructor*.

Read more: https://lean-lang.org/functional_programming_in_lean/Getting-to-Know-Lean/Datatypes-and-Patterns/
-/

inductive Weekday where
  | monday | tuesday | wednesday | thursday | friday | saturday | sunday
  deriving Repr

/-! With a structure, we read a value by asking for one of its fields. With
an inductive type, the natural question is "which option is this?". Asking it
is called *pattern matching*: the function below has one line per case, and
`_` stands for "anything else". When Lean already knows that a `Weekday` is
expected, `.saturday` is enough to mean `Weekday.saturday`. -/

def Weekday.isWeekend : Weekday → Bool
  | .saturday => true
  | .sunday   => true
  | _         => false

#eval Weekday.sunday.isWeekend  -- true

/-! The options can also carry data, and different options can carry
different data. A shape, for example, is either a circle, described by its
radius, or a rectangle, described by its width and height. When you match on
a shape, the pattern gives a name to each piece of data inside it. -/

inductive Shape where
  | circle (radius : Float)
  | rectangle (width height : Float)

def Shape.isSquare : Shape → Bool
  | .circle _      => false
  | .rectangle w h => w == h

#eval (Shape.rectangle 2.0 2.0).isSquare  -- true

/-- The area of a shape. For a circle, use `3.14 * r * r`. -/
def Shape.area : Shape → Float
  -- SOLUTION: | _ => sorry
  | .circle r      => 3.14 * r * r
  | .rectangle w h => w * h
  -- END SOLUTION

-- TESTS
#guard (Shape.circle 1.0).area == 3.14
#guard (Shape.rectangle 2.0 3.5).area == 7.0
-- END TESTS

/-! Here is a surprise: the natural numbers are an inductive type too. A
natural number is either `0`, or `n + 1` for some smaller natural number `n`.
These two cases are all there is, so a function on `Nat` can match on them.
In the second case it can even call itself on the smaller number `n`; this is
called *recursion*. Lean only accepts a recursive function when it can see
that it stops, and here it can, because each call works on a smaller number
than the one before, and numbers can't get smaller forever. -/

def sumUpTo : Nat → Nat
  | 0     => 0
  | n + 1 => (n + 1) + sumUpTo n

#eval sumUpTo 4  -- 10, that is 4 + 3 + 2 + 1 + 0

/-- `power b e` is `b` multiplied by itself `e` times (and `1` when `e = 0`).
Use recursion on `e`, not the built-in `^`. -/
def power (b : Nat) : Nat → Nat
  -- SOLUTION: | _ => sorry
  | 0     => 1
  | e + 1 => b * power b e
  -- END SOLUTION

-- TESTS
#guard power 2 10 = 1024
#guard power 7 0 = 1
#guard power 0 3 = 0
-- END TESTS

/-! Just like `n + 1` contains a smaller number, a constructor of any
inductive type can contain smaller values of the type being defined. Think of
an arithmetic expression: it is a number, or the sum of two smaller
expressions, or the product of two smaller expressions. A recursive function
on such a type has one case per constructor, and calls itself on the smaller
pieces, following the shape of the expression like the branches of a tree. -/

inductive Expr where
  | num (n : Nat)
  | add (a b : Expr)
  | mul (a b : Expr)

/-- The value of an expression: `Expr.eval (.add (.num 2) (.num 3)) = 5`. -/
def Expr.eval : Expr → Nat
  -- SOLUTION: | _ => sorry
  | .num n   => n
  | .add a b => a.eval + b.eval
  | .mul a b => a.eval * b.eval
  -- END SOLUTION

-- TESTS
#guard (Expr.num 7).eval = 7
#guard (Expr.add (.num 2) (.num 3)).eval = 5
#guard (Expr.mul (.add (.num 1) (.num 2)) (.num 4)).eval = 12
-- END TESTS

/-! ## 6. Polymorphism

Suppose we want a function that puts a value in a list twice. For numbers it
would take a `Nat` and return a list of `Nat`; for strings, the same with
`String`. The code would be identical every time, only the types would
change. Rather than writing it once per type, we can make the *type itself* an
argument of the function. Below, `α` stands for any type, and a function like
this, which works for every type, is called *polymorphic*.

The curly braces make `α` an *implicit* argument: you don't write it when you
call the function, because Lean can work it out from the other arguments.

Read more: https://lean-lang.org/functional_programming_in_lean/Getting-to-Know-Lean/Polymorphism/
-/

def twice {α : Type} (x : α) : List α := [x, x]

#eval twice "hi"  -- ["hi", "hi"]
#eval twice 3     -- [3, 3]

/-! The type of the result, `List α`, is polymorphic too. A list can hold
values of any type, but all its entries must have the same type `α`. And
lists are another inductive type, with two constructors: a list is either
empty, `[]`, or an entry followed by the rest of the list, `x :: xs`. So a
recursive function on lists looks just like one on numbers: it handles the
empty list, and otherwise does something with the first entry and calls itself
on the rest. -/

def total : List Nat → Nat
  | []      => 0
  | x :: xs => x + total xs

#eval total [1, 2, 3]  -- 6

/-! Polymorphism also lets the standard library offer a few small types that
solve problems every program meets.

The first problem is a function that sometimes has no answer. What should
`10 / 0` be, or the first entry of an empty list? `Option α` describes a value
that may be missing: it is either `some x`, for an answer `x : α`, or `none`.
A function that returns an `Option` can say "there is no answer" instead of
making one up. -/

def safeDivide (a b : Nat) : Option Nat :=
  if b == 0 then none else some (a / b)

#eval safeDivide 10 2  -- some 5
#eval safeDivide 10 0  -- none

/-! The second problem is a function that needs to return two things at
once. We could define a structure every time, but for something this small a
*pair* is enough. The type `α × β` contains a value of type `α` together with
a value of type `β`, written `(x, y)`, and `.fst` and `.snd` read its two
parts. -/

def minAndMax (a b : Nat) : Nat × Nat :=
  if a < b then (a, b) else (b, a)

#eval (minAndMax 9 4).snd  -- 9

/-! The third problem is a value that can be of one type *or* another. A seat
at a concert, for instance, may be a seat number, or a note like "standing".
The type `α ⊕ β` holds either a value of type `α`, written `.inl x` (for
"left"), or a value of type `β`, written `.inr y` (for "right"), and pattern
matching tells you which one it is. -/

def tickets : List (Nat ⊕ String) := [.inl 12, .inr "standing", .inl 40]

/-! Functions are values like any other, so they can also be arguments. The
first exercise receives a test `p : α → Bool` and counts the entries that pass
it. To call it, you need a test to give it, and it would be tiresome to `def`
a new function for each one. Instead, `fun n => n > 2` writes a function on the
spot, without a name: it takes `n` and returns `n > 2`.

The standard library has many functions of this kind. Two you will use soon
are `List.map`, which applies a function to every entry of a list, and
`List.filter`, which keeps the entries that pass a test. -/

#eval [1, 2, 3].map (fun x => x * 10)          -- [10, 20, 30]
#eval [5, 1, 8, 2].filter (fun x => x > 3)     -- [5, 8]

/-- How many entries of the list satisfy `p`. -/
def countWhere {α : Type} (p : α → Bool) : List α → Nat
  -- SOLUTION: | _ => sorry
  | []      => 0
  | x :: xs => (if p x then 1 else 0) + countWhere p xs
  -- END SOLUTION

-- TESTS
#guard countWhere (fun n => n > 2) [1, 5, 3, 2] = 2
#guard countWhere (fun (s : String) => s == "a") [] = 0
-- END TESTS

/-- Keeps the first entry, the third, the fifth, and so on.
A pattern can take two entries at once: `x :: _ :: rest`. -/
def everyOther {α : Type} : List α → List α
  -- SOLUTION: | _ => sorry
  | x :: _ :: rest => x :: everyOther rest
  | [x]            => [x]
  | []             => []
  -- END SOLUTION

-- TESTS
#guard everyOther [1, 2, 3, 4, 5] = [1, 3, 5]
#guard everyOther ["a", "b"] = ["a"]
#guard everyOther ([] : List Nat) = []
-- END TESTS

/-- The first entry that is not `none`, if there is one. -/
def firstSome? {α : Type} : List (Option α) → Option α
  -- SOLUTION: | _ => sorry
  | []           => none
  | some x :: _  => some x
  | none :: rest => firstSome? rest
  -- END SOLUTION

-- TESTS
#guard firstSome? [none, some 3, some 4] = some 3
#guard firstSome? ([none, none] : List (Option Nat)) = none
-- END TESTS

/-- Splits a list of pairs into the list of first parts and the list of second
parts. Hint: `let (xs, ys) := ...` names both parts of a pair at once. -/
def unzipPairs {α β : Type} : List (α × β) → List α × List β
  -- SOLUTION: | _ => sorry
  | []             => ([], [])
  | (a, b) :: rest =>
    let (as, bs) := unzipPairs rest
    (a :: as, b :: bs)
  -- END SOLUTION

-- TESTS
#guard unzipPairs [(1, "one"), (2, "two")] = ([1, 2], ["one", "two"])
#guard unzipPairs ([] : List (Nat × Nat)) = ([], [])
-- END TESTS

/-- Separates the left values from the right values, keeping their order:
`splitSums tickets = ([12, 40], ["standing"])`. -/
def splitSums {α β : Type} : List (α ⊕ β) → List α × List β
  -- SOLUTION: | _ => sorry
  | [] => ([], [])
  | .inl a :: rest =>
    let (as, bs) := splitSums rest
    (a :: as, bs)
  | .inr b :: rest =>
    let (as, bs) := splitSums rest
    (as, b :: bs)
  -- END SOLUTION

-- TESTS
#guard splitSums tickets = ([12, 40], ["standing"])
#guard splitSums ([] : List (Nat ⊕ Nat)) = ([], [])
-- END TESTS

/-! ## 7. Characters, strings and slices

We have used strings since the first section, but only as whole values that
we join with `++`. To look *inside* a string, say, to check its first letter,
we need to know what it is made of. A `String` is a sequence of characters.
Each character is a value of type `Char`, written in single quotes: `'a'`.

The easiest way to work on the characters of a string is to turn it into a
list with `s.toList`. Then everything you learnt about lists in the previous
section applies, and `String.ofList` turns the list back into a string at the
end.

Read more: https://lean-lang.org/functional_programming_in_lean/Getting-to-Know-Lean/Characters___-Strings___-and-Slices/
-/

#eval "hello".toList                       -- ['h', 'e', 'l', 'l', 'o']
#eval String.ofList ['o', 'k']             -- "ok"
#eval 'a'.toUpper                          -- 'A'
#eval "a,b,c".splitOn ","                  -- ["a", "b", "c"]

/-! Copying text around costs time when strings are long. For that reason,
some operations, like `drop` (which skips characters at the start) and
`dropEnd` (at the end), don't build a new string. They return a *slice*
instead: a view into a part of the original string. Most of the time you can
use a slice like a string, and when you really need a `String`, `.copy` makes
one. -/

#eval ("Mr. Lean".drop 4).copy  -- "Lean"

/-- Whether `s` reads the same backwards, ignoring spaces and upper or lower
case: `isPalindrome "Never odd or even" = true`.

Hint: work on `s.toList`; `List.filter`, `List.map`, `Char.toLower` and
`List.reverse` help. -/
def isPalindrome (s : String) : Bool :=
  -- SOLUTION
  let chars := (s.toList.filter (fun c => c != ' ')).map Char.toLower
  chars == chars.reverse
  -- END SOLUTION

-- TESTS
#guard isPalindrome "Never odd or even"
#guard isPalindrome ""
#guard !isPalindrome "Lean"
-- END TESTS

/-- The capitalised first letters of the words of a name:
`initials "ada lovelace" = "AL"`. The words are separated by single spaces.

Hint: `List.head?` gives the first entry of a list as an `Option`, because an
empty list has none. -/
def initials (name : String) : String :=
  -- SOLUTION
  let firsts := (name.splitOn " ").filterMap (fun w => w.toList.head?)
  String.ofList (firsts.map Char.toUpper)
  -- END SOLUTION

-- TESTS
#guard initials "ada lovelace" = "AL"
#guard initials "Grace Brewster Hopper" = "GBH"
#guard initials "" = ""
-- END TESTS

/-! ## 8. Additional conveniences

By now you have all the ideas of this chapter, and you have already met
several conveniences along the way: `let` for naming steps, `fun` for
functions without a name, and `.name` for constructors when the type is
known. This last section adds a few more pieces of notation. None of them lets
you write anything new, but they make common code shorter and easier to read.

Read more: https://lean-lang.org/functional_programming_in_lean/Getting-to-Know-Lean/Additional-Conveniences/
-/

/-! Short functions like `fun x => x * 10` appear so often that there is an
even shorter way to write them: `(· * 10)`. The `·` marks the place where the
argument goes. -/

#eval [1, 2, 3].map (fun x => x * 10)  -- [10, 20, 30]
#eval [1, 2, 3].map (· * 10)           -- [10, 20, 30]

/-! A `fun` can also take its argument apart with a pattern, just like a
definition by cases. This is handy with pairs: -/

#eval [(1, 2), (3, 4)].map (fun (a, b) => a + b)  -- [3, 7]

/-! Building a string out of pieces with `++` gets awkward quickly, especially
when some of the pieces are numbers, which have to be turned into text first.
*String interpolation* does both at once: in `s!"..."`, whatever is written
between curly braces is evaluated and turned into text. -/

def badge (name : String) (level : Nat) : String := s!"{name} (level {level})"

#eval badge "Ada" 3  -- "Ada (level 3)"

/-- Applies `f` two times: `applyTwice f x = f (f x)`. -/
def applyTwice {α : Type} (f : α → α) (x : α) : α :=
  -- SOLUTION
  f (f x)
  -- END SOLUTION

-- TESTS
#guard applyTwice (· + 3) 10 = 16
#guard applyTwice (fun s => s ++ "!") "hey" = "hey!!"
-- END TESTS

/-- One line per player, `<name>: <points> points`. Use `List.map` and `s!`. -/
def scoreLines (scores : List (String × Nat)) : List String :=
  -- SOLUTION
  scores.map fun (name, points) => s!"{name}: {points} points"
  -- END SOLUTION

-- TESTS
#guard scoreLines [("Ada", 12), ("Alan", 7)] = ["Ada: 12 points", "Alan: 7 points"]
#guard scoreLines [] = []
-- END TESTS

/-! ## Final project of the module: a binary search tree

To finish the module, let's put the pieces together in a classic data
structure. Imagine you keep a collection of numbers and often need to ask
whether a number is in it. With a list, you may have to look at every entry.
A *binary search tree* lets you skip most of them.

A *binary tree* is an inductive type, like `Expr`: it is either empty (a
`leaf`), or a `node` with a value and two smaller trees, one on its left and
one on its right. In a *binary search tree* the values are also kept in order:
everything in the left subtree of a node is smaller than the node's value, and
everything in the right subtree is larger. So each comparison with a node
tells you which of the two subtrees to look in, and the other one can be
ignored.
-/

inductive Tree where
  | leaf
  | node (left : Tree) (value : Nat) (right : Tree)
  deriving Repr, DecidableEq

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
#guard (Tree.node (.node .leaf 1 .leaf) 3 (.node .leaf 4 (.node .leaf 8 .leaf))).toList = [1, 3, 4, 8]
-- END TESTS

/-- Whether `n` is in a binary search tree. Only look in the subtree where `n`
could be. -/
def Tree.contains (n : Nat) : Tree → Bool
  -- SOLUTION: | _ => sorry
  | .leaf => false
  | .node left v right =>
    if n < v then left.contains n
    else if v < n then right.contains n
    else true
  -- END SOLUTION

-- TESTS
#guard (Tree.node (.node .leaf 1 .leaf) 3 (.node .leaf 8 .leaf)).contains 8
#guard !(Tree.node (.node .leaf 1 .leaf) 3 (.node .leaf 8 .leaf)).contains 5
#guard !Tree.leaf.contains 0
-- END TESTS

-- Try it, once the exercises are solved: build a tree from a list of numbers.
-- #eval ([5, 3, 8, 1, 4, 3].foldl (fun t n => t.insert n) Tree.leaf).toList

end GettingToKnow
