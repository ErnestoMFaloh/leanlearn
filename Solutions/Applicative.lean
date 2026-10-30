/-!
# Module 6 — Functors, applicative functors and monads

Module 5 found one pattern, `Monad`, behind many kinds of computation. But
`bind` is a strong requirement: the next step may look at the result of the
previous one, and decide what to do. Some useful computations can't offer
that, and still have a lot of structure. This module fills the gap between
`Functor` and `Monad` with *applicative functors* and *alternatives*, and
shows how Lean builds the whole family of classes, starting from structures
that extend other structures.

Goals:
* Define structures that extend other structures, and use their parents.
* Combine independent computations with `<$>` and `<*>`.
* Collect every error of a validation instead of stopping at the first one.
* Know the laws that applicative functors should follow, and prove some.
* Express choice and failure with `<|>`, `failure` and `guard`.
* Understand universe levels, and why classes mention them.
* Build a small parser with `Monad` and `Alternative` instances.

Read alongside: *Functional Programming in Lean*, chapter 5
(https://lean-lang.org/functional_programming_in_lean/Functors___-Applicative-Functors___-and-Monads/).
Each section of this file covers a section of the chapter, with its own
explanation, so you can also work without the book.
-/

namespace Applicative

/-! ## 1. Structures and inheritance

A bookshop sells many kinds of items. Every item has a name and a price, a
book also has an author, and an e-book is a book that also has a file size.
We could repeat the common fields in each structure, but then a function
about items would not accept a book. Instead, a structure can *extend*
another one: it gets all the parent's fields, and adds its own. -/

structure Item where
  name : String
  price : Nat
  /-- Fields can have default values, used when a value doesn't give them. -/
  taxed : Bool := true
  deriving Repr

structure Book extends Item where
  author : String
  deriving Repr

/-- An e-book is a book, but e-books are not taxed. A child structure can
change the default value of a parent's field. -/
structure Ebook extends Book where
  megabytes : Nat
  taxed := false
  deriving Repr

/-! A `Book` value is written with all its fields, its own and its parent's,
and the fields of the parent can be read directly: -/

def dune : Book := { name := "Dune", price := 1200, author := "Frank Herbert" }

#eval dune.price   -- 1200
#eval dune.taxed   -- true

/-! Behind the scenes, a `Book` contains an `Item` in a field called
`toItem`, and `dune.price` is short for `dune.toItem.price`. So `dune.toItem`
is the item part of the book, and can be given to any function about items.
Lean also lets you call such a function with dot notation directly on the
book.

A structure can extend several parents at once. If two parents share a
field, the child has it only once.

Read more: https://lean-lang.org/functional_programming_in_lean/Functors___-Applicative-Functors___-and-Monads/Structures-and-Inheritance/
-/

/-- The price with tax: taxed items cost 10% more, rounded down. -/
def Item.finalPrice (i : Item) : Nat := if i.taxed then i.price + i.price / 10 else i.price

#eval dune.finalPrice  -- 1320: `Item.finalPrice dune.toItem`

/-- An e-book of *Dune*, with the name, price and author of `dune`, and a file
size of 3 megabytes. Leave out `taxed`, so that the e-book default applies.

(Writing `toBook := dune` would also work, but it would copy `dune.taxed`,
which is `true`.) -/
def duneEbook : Ebook :=
  -- SOLUTION
  { name := dune.name, price := dune.price, author := dune.author, megabytes := 3 }
  -- END SOLUTION

-- TESTS
#guard duneEbook.author = "Frank Herbert"
#guard duneEbook.megabytes = 3
#guard duneEbook.taxed = false
#guard duneEbook.finalPrice = 1200
-- END TESTS

/-- The total price with tax of a shopping basket of paper books and e-books. -/
def basketTotal (books : List Book) (ebooks : List Ebook) : Nat :=
  -- SOLUTION
  ((books.map (·.toItem)) ++ (ebooks.map (·.toItem))).foldl (fun total i => total + i.finalPrice) 0
  -- END SOLUTION

-- TESTS
#guard basketTotal [dune, dune] [duneEbook] = 3840
#guard basketTotal [] [] = 0
-- END TESTS

/-! ## 2. Applicative functors

A theatre takes bookings through a web form, and the form must be checked
before a booking is made: -/

structure Booking where
  name : String
  seats : Nat
  email : String
  deriving Repr, BEq

/-! With the `Except` monad of module 5, each check would be a step of a `do`
block, and the first problem would stop the block. That is annoying for the
user, who fixes one mistake, sends the form again, and learns about the next
one. We would like *all* the problems at once.

That is impossible with `bind`. In `step >>= next`, `next` needs the result
of `step`, and when `step` fails there is no result: `next` can't run. But
our three checks don't need each other's results. They are independent, and
only at the end do we combine their results into a `Booking`.

Combining independent computations is what an *applicative functor* does.
Recall from module 4 that a `Functor` has `f <$> x`, which applies an
ordinary function to the result of `x`. An `Applicative` adds:

* `pure x`, as in a monad;
* `fs <*> x` ("seq"), where both sides are computations: the left one gives a
  function, the right one gives its argument.

A function with three arguments is applied to three computations like this:

    Booking.mk <$> checkName n <*> checkSeats s <*> checkEmail e

`Booking.mk <$> checkName n` is a computation that gives a function still
waiting for two arguments, `<*> checkSeats s` gives it the second one, and so
on. The instance decides what happens when a computation fails, and that is
where we can collect the errors.

Read more: https://lean-lang.org/functional_programming_in_lean/Functors___-Applicative-Functors___-and-Monads/Applicative-Functors/
-/

/-- The result of checking: a value, or the list of problems found. -/
inductive Checked (α : Type) where
  | ok : α → Checked α
  | problems : List String → Checked α
  deriving Repr, BEq

/-! Lean's `Applicative` gives `seq` an unusual second argument: not a
computation, but a function from `()` to it, written `fun () => x`. It lets
an instance avoid running the second computation, when it doesn't need to.
We will always need it, so we simply call it with `x ()`. -/

/-- `pure` is a successful check. In `fs <*> x`: if both succeed, apply the
function; if only one fails, keep its problems; if both fail, keep the
problems of `fs` followed by those of `x`. -/
instance instApplicativeChecked : Applicative Checked where
  -- SOLUTION: pure _ := sorry
  pure := .ok
  -- END SOLUTION
  -- SOLUTION: seq _ _ := sorry
  seq fs x :=
    match fs, x () with
    | .ok f, .ok v => .ok (f v)
    | .ok _, .problems ps => .problems ps
    | .problems ps, .ok _ => .problems ps
    | .problems ps, .problems qs => .problems (ps ++ qs)
  -- END SOLUTION

-- TESTS
#guard (Prod.mk <$> (pure 1 : Checked Nat) <*> (pure 2 : Checked Nat)) == .ok (1, 2)
#guard (Prod.mk <$> (pure 1 : Checked Nat) <*> (.problems ["b"] : Checked Nat)) == .problems ["b"]
#guard (Prod.mk <$> (.problems ["a"] : Checked Nat) <*> (pure 2 : Checked Nat)) == .problems ["a"]
#guard (Prod.mk <$> (.problems ["a"] : Checked Nat) <*> (.problems ["b"] : Checked Nat))
  == .problems ["a", "b"]
-- END TESTS

/-- A name must not be empty. -/
def checkName (name : String) : Checked String :=
  if name.isEmpty then .problems ["the name is empty"] else pure name

/-- The number of seats must be a number between 1 and 8. The problems are
`"<s> is not a number"` and `"you can book 1 to 8 seats"`. -/
def checkSeats (s : String) : Checked Nat :=
  -- SOLUTION
  match s.toNat? with
  | none => .problems [s!"{s} is not a number"]
  | some n => if n < 1 || n > 8 then .problems ["you can book 1 to 8 seats"] else pure n
  -- END SOLUTION

-- TESTS
#guard checkSeats "3" == .ok 3
#guard checkSeats "8" == .ok 8
#guard checkSeats "0" == .problems ["you can book 1 to 8 seats"]
#guard checkSeats "three" == .problems ["three is not a number"]
-- END TESTS

/-- An email must contain `'@'`; otherwise the problem is
`"the email has no @"`. -/
def checkEmail (email : String) : Checked String :=
  -- SOLUTION
  if email.contains '@' then pure email else .problems ["the email has no @"]
  -- END SOLUTION

-- TESTS
#guard checkEmail "a@b.org" == .ok "a@b.org"
#guard checkEmail "ab.org" == .problems ["the email has no @"]
-- END TESTS

/-- Checks the whole form, reporting every problem. Use `<$>` and `<*>`. -/
def checkBooking (name seats email : String) : Checked Booking :=
  -- SOLUTION
  Booking.mk <$> checkName name <*> checkSeats seats <*> checkEmail email
  -- END SOLUTION

-- TESTS
#guard checkBooking "Ada" "2" "ada@example.org" == .ok ⟨"Ada", 2, "ada@example.org"⟩
#guard checkBooking "" "two" "ada" ==
  .problems ["the name is empty", "two is not a number", "the email has no @"]
#guard checkBooking "Ada" "12" "ada" ==
  .problems ["you can book 1 to 8 seats", "the email has no @"]
-- END TESTS

/-! ## 3. The applicative contract

Like monads, applicative functors should follow some laws, so that code
written for every applicative behaves as expected. In words: `pure` really
does nothing, and `<*>` doesn't care how its computations are grouped. Two of
the laws are:

* `pure id <*> v = v`: applying the function that does nothing changes
  nothing. Since `f <$> v` is `pure f <*> v`, this also says that
  `id <$> v = v`, the main law of functors.
* `pure f <*> pure x = pure (f x)`: combining two computations that do
  nothing is the same as applying `f` directly.

Every monad is an applicative functor: `fs <*> x` can be written as "run
`fs`, then run `x`, then apply". An applicative instance of a type that is
also a monad should agree with that. `Checked` deliberately has no `Monad`
instance: collecting the problems of both sides is exactly what a `bind`
could never do, since the second step can't run when the first one fails.

These laws are propositions, so Lean can prove them, with the tactics of
module 3. `cases x with` works on any inductive type, not only on `∨`: it
gives one goal for each constructor.

Read more: https://lean-lang.org/functional_programming_in_lean/Functors___-Applicative-Functors___-and-Monads/The-Applicative-Contract/
-/

theorem optionPureSeq (f : α → β) (x : α) : (pure f <*> pure x : Option β) = pure (f x) := rfl

/-- The functor law for `Option`. Take `x` apart with `cases`. -/
theorem optionMapId (x : Option α) : id <$> x = x := by
  -- SOLUTION
  cases x with
  | none => rfl
  | some v => rfl
  -- END SOLUTION

/-- The second law for `Checked`. -/
theorem checkedPureSeq (f : α → β) (x : α) :
    (pure f <*> pure x : Checked β) = pure (f x) := by
  -- SOLUTION
  rfl
  -- END SOLUTION

/-- The first law for `Checked`. -/
theorem checkedPureId (v : Checked α) : (pure id <*> v) = v := by
  -- SOLUTION
  cases v with
  | ok x => rfl
  | problems ps => rfl
  -- END SOLUTION

/-! ## 4. Alternatives

Failure is only half of the story: often, when something fails, we want to
try something else. A setting can come from the user's preferences, or
otherwise from the defaults; an answer can be written `yes`, or `y`. The
class `Alternative` adds two operations to an applicative functor:

* `failure`, a computation that fails;
* `a <|> b` ("or else"), which gives the result of `a`, or, if `a` fails,
  the result of `b`.

`Option` is an alternative: `failure` is `none`, and `a <|> b` is `a` unless
`a` is `none`. With them comes `guard cond`, which fails when `cond` is
false. In a `do` block, `guard` stops the block unless the condition holds.

Read more: https://lean-lang.org/functional_programming_in_lean/Functors___-Applicative-Functors___-and-Monads/Alternatives/
-/

def defaults : List (String × String) := [("theme", "light"), ("language", "en")]

def preferences : List (String × String) := [("theme", "dark")]

#eval preferences.lookup "theme" <|> defaults.lookup "theme"        -- some "dark"
#eval preferences.lookup "language" <|> defaults.lookup "language"  -- some "en"

/-- The whole number whose square is `n`, if there is one. -/
def exactSqrt? (n : Nat) : Option Nat := do
  let r := (List.range (n + 1)).find? (fun r => r * r ≥ n) |>.getD 0
  guard (r * r == n)
  return r

#eval exactSqrt? 49  -- some 7
#eval exactSqrt? 50  -- none

/-! (`x |>.f` is `(x).f`, the method call put after a long expression, and
`Option.getD o d` is the value in `o`, or `d` if there is none.) -/

/-- Reads an answer: `yes` or `y` is `true`, and `no` or `n` is `false`, in
any mix of upper and lower case. Anything else is `none`.

Hint: write it with `<|>` and `guard`, for instance
`(do guard (a == "yes"); pure true) <|> ...`. -/
def answer? (s : String) : Option Bool :=
  -- SOLUTION
  let a := s.toLower
  (do guard (a == "yes" || a == "y"); pure true) <|>
  (do guard (a == "no" || a == "n"); pure false)
  -- END SOLUTION

-- TESTS
#guard answer? "Yes" = some true
#guard answer? "n" = some false
#guard answer? "maybe" = none
-- END TESTS

/-- `Checked` is an alternative too. `failure` has no problems to report.
`a <|> b` is `a` if it succeeds; otherwise `b` if it succeeds; and if both
fail, the problems of `a` followed by those of `b`. -/
instance instAlternativeChecked : Alternative Checked where
  -- SOLUTION: failure := sorry
  failure := .problems []
  -- END SOLUTION
  -- SOLUTION: orElse _ _ := sorry
  orElse a b :=
    match a with
    | .ok x => .ok x
    | .problems ps =>
      match b () with
      | .ok y => .ok y
      | .problems qs => .problems (ps ++ qs)
  -- END SOLUTION

-- TESTS
#guard (failure : Checked Nat) == .problems []
#guard ((pure 1 : Checked Nat) <|> .problems ["b"]) == .ok 1
#guard ((.problems ["a"] : Checked Nat) <|> pure 2) == .ok 2
#guard ((.problems ["a"] : Checked Nat) <|> .problems ["b"]) == .problems ["a", "b"]
-- END TESTS

/-- Seats can also be booked by name: `"pair"` is 2 and `"family"` is 4.
Accept either a number (with `checkSeats`) or one of these names. If neither
works, report the problems of `checkSeats` followed by
`"unknown group <s>"`. -/
def checkGroup (s : String) : Checked Nat :=
  -- SOLUTION
  checkSeats s <|>
    (if s == "pair" then pure 2 else if s == "family" then pure 4
     else .problems [s!"unknown group {s}"])
  -- END SOLUTION

-- TESTS
#guard checkGroup "3" == .ok 3
#guard checkGroup "family" == .ok 4
#guard checkGroup "crowd" == .problems ["crowd is not a number", "unknown group crowd"]
-- END TESTS

/-! ## 5. Universes

Types are values, as module 1 said, so they have types themselves. `Nat` has
type `Type`. But `Type` can't have type `Type`: allowing it would make the
logic contradictory. So there is a tower of *universes*: `Type` has type
`Type 1`, which has type `Type 2`, and so on. Propositions live at the
bottom: `Prop` has type `Type`. (`Sort u` names any level of the tower:
`Sort 0` is `Prop`, and `Sort (u + 1)` is `Type u`.)

This matters as soon as types are put in data. `[Nat, String]` is a list of
types, so its type is `List Type`, and `List Type` lives in `Type 1`. If
`List` only accepted types from `Type`, that list couldn't exist. So `List`
is *universe polymorphic*: it accepts `α : Type u` for every level `u`.

Our own definitions can be polymorphic in the same way. After declaring
`universe u`, we can write `{α : Type u}`. That is what the `Type u_1` in the
types of module 4 meant: Lean adds such a level on its own to an implicit
argument whose universe we didn't mention. The type classes of this module,
like `Functor`, are written this way too, so that they work at every level.

Read more: https://lean-lang.org/functional_programming_in_lean/Functors___-Applicative-Functors___-and-Monads/Universes/
-/

#check Nat                -- Nat : Type
#check Type               -- Type : Type 1
#check ([Nat, String] : List Type)

universe u v

/-- Swaps the two parts of a pair, for types in any universes. -/
def swap {α : Type u} {β : Type v} (p : α × β) : β × α :=
  -- SOLUTION
  (p.2, p.1)
  -- END SOLUTION

-- TESTS
#guard swap (1, "one") = ("one", 1)
example : swap (Nat, 3) = (3, Nat) := rfl
-- END TESTS

/-! ## 6. The complete definitions

We have used `Functor`, `Applicative`, `Alternative` and `Monad` as if each
were a single class. In Lean, they are a family of small classes connected by
`extends`, the structure inheritance of section 1:

* `Functor` has `map` (`<$>`);
* `Pure` has `pure`, `Seq` has `seq` (`<*>`), and `SeqLeft` and `SeqRight`
  have `<*` and `*>`, which run both sides and keep only the result of one;
* `Applicative` extends `Functor`, `Pure`, `Seq`, `SeqLeft` and `SeqRight`;
* `Bind` has `bind` (`>>=`), and `Monad` extends `Applicative` and `Bind`;
* `Alternative` extends `Applicative` and adds `failure` and `orElse`.

Most of their operations have default definitions in terms of the others.
When we gave `Monad Logged` only `pure` and `bind` in module 5, Lean defined
`map`, `seq`, `<*` and `*>` from them, so `<$>` and `<*>` already worked for
`Logged`. Likewise, `Applicative Checked` got `map` from `pure` and `seq`.

Read more: https://lean-lang.org/functional_programming_in_lean/Functors___-Applicative-Functors___-and-Monads/The-Complete-Definitions/
-/

/-! A program's behaviour often depends on some settings that never change
while it runs. Passing them to every function is tedious, so we make a
monad of "computations that can read the settings". -/

structure Settings where
  user : String
  language : String

def WithSettings (α : Type) : Type := Settings → α

def askUser : WithSettings String := fun s => s.user
def askLanguage : WithSettings String := fun s => s.language

/-- Give `pure` and `bind` only. A computation receives the settings; `bind`
gives the *same* settings to both steps. -/
instance instMonadWithSettings : Monad WithSettings where
  -- SOLUTION: pure _ := sorry
  pure x := fun _ => x
  -- END SOLUTION
  -- SOLUTION: bind _ _ := sorry
  bind step next := fun s => next (step s) s
  -- END SOLUTION

-- TESTS
#guard (pure 3 : WithSettings Nat) ⟨"Ana", "es"⟩ = 3
#guard (askUser >>= fun u => pure u.length : WithSettings Nat) ⟨"Ana", "es"⟩ = 3
-- END TESTS

def greet (language user : String) : String :=
  if language == "es" then s!"¡Hola, {user}!" else s!"Hello, {user}!"

/-- The greeting for the current settings. Don't write a `fun`: combine
`askLanguage` and `askUser` with `<$>` and `<*>`, which Lean derived from
your `Monad` instance. -/
def greeting : WithSettings String :=
  -- SOLUTION
  greet <$> askLanguage <*> askUser
  -- END SOLUTION

-- TESTS
#guard greeting ⟨"Ana", "es"⟩ = "¡Hola, Ana!"
#guard greeting ⟨"Bob", "en"⟩ = "Hello, Bob!"
-- END TESTS

/-! ## Final project of the module: a parser

A *parser* reads text and turns it into data: `"12,7,30"` into
`[12, 7, 30]`. Each piece of a parser reads the start of the input and
returns what it found, with the rest of the input. A piece may also fail,
when the input doesn't start with what it expects. Small parsers are combined
into bigger ones with `Monad` (read this, then that) and `Alternative` (read
this, or else that). -/

structure Parser (α : Type) where
  run : List Char → Option (α × List Char)

/-- `pure x` reads nothing and returns `x`. `bind p next` runs `p` on the
input, then `next` with its result on what `p` left over. -/
instance instMonadParser : Monad Parser where
  -- SOLUTION: pure _ := sorry
  pure x := ⟨fun input => some (x, input)⟩
  -- END SOLUTION
  -- SOLUTION: bind _ _ := sorry
  bind p next := ⟨fun input =>
    match p.run input with
    | none => none
    | some (x, rest) => (next x).run rest⟩
  -- END SOLUTION

-- TESTS
#guard (pure 3 : Parser Nat).run ['a'] = some (3, ['a'])
#guard ((Parser.mk fun cs => some (cs.length, cs.drop 1)) >>= fun n => pure (n + 1)).run ['a', 'b']
  = some (3, ['b'])
#guard ((Parser.mk fun _ => none : Parser Nat) >>= fun n => pure (n + 1)).run ['a'] = none
-- END TESTS

/-- `failure` fails on any input. `p <|> q` runs `p`, and if it fails, runs
`q` on the same input. -/
instance instAlternativeParser : Alternative Parser where
  -- SOLUTION: failure := sorry
  failure := ⟨fun _ => none⟩
  -- END SOLUTION
  -- SOLUTION: orElse _ _ := sorry
  orElse p q := ⟨fun input =>
    match p.run input with
    | some r => some r
    | none => (q ()).run input⟩
  -- END SOLUTION

-- TESTS
#guard (failure : Parser Nat).run ['a'] = none
#guard ((failure : Parser Nat) <|> pure 1).run ['x'] = some (1, ['x'])
#guard ((pure 0 : Parser Nat) <|> pure 1).run [] = some (0, [])
-- END TESTS

/-- Reads one character, whatever it is; fails at the end of the input. -/
def anyChar : Parser Char :=
  ⟨fun input =>
    match input with
    | [] => none
    | c :: rest => some (c, rest)⟩

/-- Reads one character that satisfies `ok`. Use `anyChar` and `guard`. -/
def satisfy (ok : Char → Bool) : Parser Char := do
  -- SOLUTION
  let c ← anyChar
  guard (ok c)
  return c
  -- END SOLUTION

/-- Runs a parser on a whole string: it must read all of it. -/
def parse (p : Parser α) (s : String) : Option α :=
  match p.run s.toList with
  | some (x, []) => some x
  | _ => none

-- TESTS
#guard parse (satisfy Char.isDigit) "7" = some '7'
#guard parse (satisfy Char.isDigit) "x" = none
-- END TESTS

/-- Reads one digit, as a number from 0 to 9. -/
def digit : Parser Nat := do
  -- SOLUTION
  let c ← satisfy Char.isDigit
  return c.toNat - '0'.toNat
  -- END SOLUTION

-- TESTS
#guard parse digit "4" = some 4
-- END TESTS

instance : Inhabited (Parser α) := ⟨failure⟩

/-- Runs `p` as many times as it succeeds, zero times or more. (It is
`partial`, as in module 2, because Lean can't see that the input gets shorter;
the `Inhabited` instance above is what `partial` needs.) -/
partial def many (p : Parser α) : Parser (List α) :=
  (do let x ← p; let xs ← many p; return x :: xs) <|> pure []

/-- Like `many`, but `p` must succeed at least once. -/
def many1 (p : Parser α) : Parser (List α) := do
  -- SOLUTION
  let x ← p
  let xs ← many p
  return x :: xs
  -- END SOLUTION

-- TESTS
#guard parse (many1 digit) "123" = some [1, 2, 3]
#guard parse (many1 digit) "" = none
-- END TESTS

/-- A number made of one digit or more. -/
def number : Parser Nat := do
  -- SOLUTION
  let ds ← many1 digit
  return ds.foldl (fun n d => 10 * n + d) 0
  -- END SOLUTION

-- TESTS
#guard parse number "2026" = some 2026
#guard parse number "" = none
#guard parse number "12a" = none
-- END TESTS

/-- One `p` or more, separated by `sep`, whose results are thrown away.

Hint: after the first `p`, read `many` times "a separator, then a `p`". The
operator `sep *> p` runs both and keeps only the result of `p`. -/
def sepBy1 (p : Parser α) (sep : Parser β) : Parser (List α) := do
  -- SOLUTION
  let x ← p
  let xs ← many (sep *> p)
  return x :: xs
  -- END SOLUTION

-- TESTS
#guard parse (sepBy1 digit (satisfy (· == '-'))) "1-2-3" = some [1, 2, 3]
#guard parse (sepBy1 digit (satisfy (· == '-'))) "1-" = none
-- END TESTS

/-- A list of numbers separated by commas, or nothing at all. -/
def numbers : Parser (List Nat) :=
  -- SOLUTION
  sepBy1 number (satisfy (· == ',')) <|> pure []
  -- END SOLUTION

-- TESTS
#guard parse numbers "12,7,30" = some [12, 7, 30]
#guard parse numbers "5" = some [5]
#guard parse numbers "" = some []
#guard parse numbers "1,,2" = none
-- END TESTS

end Applicative
