# Guide: learning Lean 4

This guide explains what to do in each module, how to work with the project and
which projects you can build afterwards. There are no deadlines: go at your own
pace, and don't move on to the next module until the current one compiles
without any `sorry`.

---

## 0. Before you start (once)

You need:

- **elan**: the Lean version manager (see the [README](README.md#getting-started)).
- **Lean 4** and **lake** (the compiler and the build tool). elan installs the
  right version automatically the first time you run `lake build` in this
  folder.
- **VS Code** with the **Lean 4** extension (`leanprover.lean4`).

If `lean` or `lake` are not found in a new terminal, add this line to your
`~/.bashrc` (or `~/.zshrc`) and open a new terminal:

```bash
source ~/.elan/env
```

### How to work

1. Open the project folder in VS Code:
   ```bash
   code leanlearn
   ```
2. Open a `.lean` file. The **Lean Infoview** panel appears on the right; if it
   doesn't, press `Ctrl+Shift+Enter`.
3. Move the cursor through the code. The Infoview shows:
   - the result of each `#eval` and `#check`;
   - inside a proof (`by ...`), the remaining **goal**.
4. Errors are underlined in red; each `sorry` is underlined in yellow.
5. To check the whole project from the terminal:
   ```bash
   lake build
   ```

### How to approach each module

1. **Reading:** the book chapters listed for the module.
2. **Examples:** go through the module file, change things and see what
   happens.
3. **Exercises:** solve every `sorry` in the file.
4. **Check:** run `lake exe check <Module>` (for example
   `lake exe check Propositions`). It marks each exercise as ✅ solved, ⏳ pending or
   ❌ wrong, and says why.
5. **Compare:** once an exercise is ✅, open the matching file in `Solutions/`.
   Different proofs can be equally valid; look for tactics or ideas you didn't
   use.
6. **Wrap-up:** commit your work.

### When you get stuck

Try for a while first: being stuck is where most of the learning happens.
Re-read the examples in the file, check the hints in this guide and look at
the goal in the Infoview. If you're still stuck, open the solution, read only
the first line or two, and try to finish on your own.

If you keep your solutions in your own fork, commit every time you finish
something, even a single exercise:

```bash
git add .
git commit -m "Module N: exercise X solved"
git push
```

---

## Module 1 — Getting to know Lean

**File:** `Exercises/GettingToKnow.lean` (solutions: `Solutions/GettingToKnow.lean`)

**Read:** *Functional Programming in Lean*, chapter 1 ("Getting to Know Lean").
Each section of the file starts with an explanation of what you need for its
exercises, and links to the matching section of the book.

**Key ideas:**

- `#eval` evaluates an expression and `#check` shows its type.
- `def` defines functions and also types: types are values like any other.
- A function with several arguments takes them one at a time, so
  `larger 3` is itself a function.
- `structure` groups values in named fields. Structures are never modified:
  `{ b with pages := 10 }` builds an updated copy.
- `inductive` defines a type by its constructors, and pattern matching takes a
  value apart. Recursion must terminate: Lean accepts it when each recursive
  call is on a smaller argument (`n` instead of `n + 1`, `xs` instead of
  `x :: xs`).
- Polymorphic functions take types as (usually implicit) arguments. The basic
  polymorphic types are `List`, `Option` (a value that may be missing), `Prod`
  (`α × β`, both values) and `Sum` (`α ⊕ β`, one or the other).

**Exercises:**

- Evaluating expressions and types: `predictedString`, `natPuzzle`,
  `intPuzzle`.
- Functions: `secondsIn`, `clamp`, `surround`.
- Structures: `Book.newEdition`, `Time.toMinutes`, `Time.later`.
- Datatypes and patterns: `Shape.area`, `power`, `Expr.eval`.
- Polymorphism: `countWhere`, `everyOther`, `firstSome?`, `unzipPairs`,
  `splitSums`.
- Strings: `isPalindrome`, `initials`.
- Conveniences: `applyTwice`, `scoreLines`.
- **Final project:** a binary search tree with `Tree.insert`, `Tree.toList`
  and `Tree.contains`.

**Hints:**

- For the puzzles of sections 1 and 2, work the answer out before running
  anything: the point is to learn how Lean reads expressions.
- `Time.later` is easier if you first turn the time into minutes.
- A recursive function on an `Expr` has one case per constructor, and calls
  itself on the smaller expressions inside.
- In `unzipPairs` and `splitSums`, call the function once on the rest of the
  list, name the two parts of its result with `let (xs, ys) := ...`, and add
  the new entry to the right part.
- `Tree.insert` and `Tree.contains` compare the value with the node's value to
  decide which subtree to go into.

**Extra challenge:** write `Tree.ofList : List Nat → Tree`, which inserts every
number of a list, and check that `(Tree.ofList xs).toList` is always sorted.

---

## Module 2 — Hello, World!

**File:** `Exercises/HelloWorld.lean` (solutions: `Solutions/HelloWorld.lean`)

**Read:** *Functional Programming in Lean*, chapter 2 ("Hello, World!"). Each
section of the file starts with an explanation of what you need for its
exercises, and links to the matching section of the book.

**Key ideas:**

- A program is a value of type `IO Unit`: a *description* of actions. Lean
  carries the actions out when the program runs, not when it is defined.
- In a `do` block, `let x ← action` runs the action and names its result;
  `let x := e` only names a value. An action named with `:=` runs each time it
  is used as a step.
- Actions are ordinary values: you can keep them in a list, pass them to a
  function and run them later.
- `IO.getStdin` gives the standard input. `getLine` returns the line *with*
  its newline, and `""` at the end of the input.
- A loop over a stream is written with recursion. Lean can't prove that it
  stops, so it is a `partial def`.
- `main` can take the command-line arguments and return an exit code; error
  messages go to the standard error with `IO.eprintln`.
- `(← e)`, `return`, `unless`, `for` and `let mut` keep `do` blocks short.

**Exercises:**

- Running a program: `introduce`.
- Step by step: `mysteryOutput`, `withBorder`, `runBackwards`, `retry`.
- Starting a project: `greeter`.
- A `wc` clone: `readAll`, `Counts.of`, `wc`.
- Conveniences: `findWord`.
- **Final project:** a guessing game with `hint` and `play`.

The tests run each program with a made-up input, using `run` (defined at the
top of the file). You can use it yourself: `#eval run "mango\n" favouriteFruit`.

**Hints:**

- For `mysteryOutput`, remember that `let shout := ...` doesn't print anything
  by itself.
- In `retry`, `if ← action then ...` runs the action and looks at its result.
- `readAll` stops when `getLine` returns the empty string.
- For `findWord`, `String.splitOn "\n"` cuts a text into lines.
- In `play`, check for the end of the input before trying to read a number.

**Try it in the terminal:** when `play` is solved, play the game with

```bash
lake env lean --run Exercises/HelloWorld.lean
```

**Extra challenge:** make a Lake project of your own with `wc` as its `main`:

```bash
lake new wc
cd wc
# copy readAll, wordsOf, Counts, openInput and wc into Main.lean,
# and add `def main (args : List String) : IO UInt32 := wc args`
lake build
echo "hello world" | .lake/build/bin/wc - Main.lean
```

---

## Module 3 — Propositions, proofs and indexing

**File:** `Exercises/Propositions.lean` (solutions: `Solutions/Propositions.lean`)

**Read:** *Functional Programming in Lean*, the interlude "Propositions,
Proofs, and Indexing". Sections 3 and 4 go further into logic, following
*Theorem Proving in Lean 4*. Each section of the file starts with an
explanation of what you need for its exercises, and links to the matching
section of a book.

**Key ideas:**

- In Lean, **a proposition is a type and a proof is a value of that type**.
  Proving `p → q` means writing a function that turns proofs of `p` into
  proofs of `q`.
- `rfl`, `decide` and `simp` prove facts that hold by computation.
- `by` starts a proof written with tactics. Put the cursor at the end of each
  line and watch the goal change in the Infoview.
- `xs[i]` only compiles when Lean has evidence that `i` is in bounds. A
  function can ask for that evidence as an argument; `xs[i]?` asks for an
  `Option` instead.

**Tactics in this module:**

| If the goal or hypothesis is... | Use |
|---|---|
| Goal `p → q` | `intro hp` |
| You already have exactly what is asked | `exact h` |
| Goal `q` and you have `h : p → q` | `apply h` |
| Goal `p ∧ q` or `p ↔ q` | `constructor` |
| Hypothesis `h : p ∧ q` | `obtain ⟨hp, hq⟩ := h` |
| Goal `p ∨ q` | `left` or `right` |
| Hypothesis `h : p ∨ q` | `cases h with` … |
| Goal `¬p` | `intro hp` (because `¬p` is `p → False`) |
| Hypothesis `h : a = b` | `rw [h]` |
| An equality that holds by computation | `rfl` or `decide` |
| Simplify automatically | `simp` |

**Exercises:**

- Propositions and proofs: `reverseFact`, `takeFact`.
- Tactics: `bigPower`, `zeroTimes`.
- Connectives: `chain`, `andToOr`, `contrapositive`, `orComm`,
  `andOrDistrib`.
- Rewriting with equalities: `rewriteSum`, `rewriteSwap`, `rewriteCall`.
- Evidence as arguments: `ends`, `middle`.
- Indexing without evidence: `sumAt?`, `pick`.
- **Final project:** a minefield, with `squareAt?`, `square`, `minesAround`
  and the proof `cornerIsSafe`.

**Hints:**

- In `pick`, `xs[i]?` gives an `Option`, and `List.filterMap` keeps only the
  `some` results.
- `cornerIsSafe` is a fact about concrete values: once `minesAround` works,
  `decide` can check it.

**Extra practice:** the [Natural Number Game](https://adam.math.hhu.de/#/g/leanprover-community/nng4)
is the best way to get comfortable with tactics. Try to complete the
*Tutorial* and *Addition* worlds.

---

## Module 4 — Overloading and type classes

**File:** `Exercises/TypeClasses.lean` (solutions: `Solutions/TypeClasses.lean`)

**Read:** *Functional Programming in Lean*, chapter 3 ("Overloading and Type
Classes"). Each section of the file starts with an explanation of what you
need for its exercises, and links to the matching section of the book.

**Key ideas:**

- A type class is an interface (`Add`, `ToString`, `OfNat`, ...), and an
  `instance` implements it for one type. Notation like `+`, `s!` and number
  literals is built on classes.
- A function can require an instance with an argument in square brackets,
  `[Add α]`, and an instance can depend on other instances.
- `HAdd`, `HMul` and friends allow operations between *different* types,
  such as a number times an amount of money.
- `Array` is the efficient sequence type; `GetElem` makes your own types
  indexable with `xs[i]`.
- Many standard classes (`BEq`, `Repr`, `Ord`, `Hashable`) can be derived with
  `deriving`. `Functor` gives `<$>`, which applies a function inside a
  container.
- Coercions (`Coe`, `CoeFun`) let Lean convert values automatically, for
  instance using a structure as if it were a function.

**Exercises:**

- Classes and instances: `Money` with `Add`, `OfNat` and `ToString`.
- Type classes and polymorphism: `Describe (Option α)`, `addAll`,
  `Add (Vec2 α)`.
- Controlling instance search: `HMul Nat Money Money`, `HDiv Money Nat Money`.
- Arrays and indexing: `runningTotals`, `GetElem (Triple α)`.
- Standard classes: `Ord Version`, `newest`, `Functor Triple`.
- Coercions: `Coe (Triple α) (List α)`, `CoeFun Line`.
- Additional conveniences: `ToString Version`.
- **Final project:** Fibonacci numbers with 2×2 matrices: `Mul Mat2`,
  `OfNat Mat2 1` and a `power` that works for every type with `*` and `1`.

**Hints:**

- In `Ord Version`, `o₁.then o₂` compares by the next field only when the
  previous fields are equal.
- `runningTotals` is easiest with `Id.run do`, a `for` loop and `let mut`.
- `power` doesn't know anything about matrices: write it for any `α`, and the
  Fibonacci numbers come for free.

---

## Module 5 — Monads

**File:** `Exercises/Monads.lean` (solutions: `Solutions/Monads.lean`)

**Read:** *Functional Programming in Lean*, chapter 4 ("Monads"). Each
section of the file starts with an explanation of what you need for its
exercises, and links to the matching section of the book.

**Key ideas:**

- Computations that may fail (`Option`), report errors (`Except`), keep a
  state or write a log all follow the same pattern: do one step, then use its
  result in the next one. That step is `bind`, written `>>=`.
- The `Monad` class captures the pattern with `pure` and `bind`. A function
  with a `[Monad m]` argument works in every monad.
- A `do` block is notation for `>>=`, so it works in every monad, not only in
  `IO`.
- `IO` is one monad among others. Its errors can be thrown with `throw` and
  caught with `try ... catch`.

**Exercises:**

- One API, many applications: `andThenExcept`, `orderPrice`, `label`,
  `andThenLogged`.
- The `Monad` type class: `Monad Logged`, `keepIf`.
- A stack calculator: `exec`, `execAll`, `popExcept`, `divideExcept`.
- `do` notation: `parseVersion?`, `labelAll`, `sumEvens`.
- The `IO` monad: `safeSum`.
- Additional conveniences: `Instr.arity`.
- **Final project:** a bank whose operations need both a state and errors:
  `Monad Bank`, `Bank.balance`, `Bank.withdraw`, `Bank.transfer`.

**Hints:**

- For `keepIf`, read the code of `forEach` just above it: the shape is the
  same.
- The calculator is written once, with `exec` and `execAll`, for every monad;
  `popExcept` and `divideExcept` only say how `Except` reports the errors.
- In `safeSum`, wrap each action in `try ... catch` so that one failure doesn't
  stop the others.
- `Bank.transfer` is two lines with `withdraw` and `deposit`: the monad takes
  care of stopping at the first error.

---

## Module 6 — Functors, applicative functors and monads

**File:** `Exercises/Applicative.lean` (solutions: `Solutions/Applicative.lean`)

**Read:** *Functional Programming in Lean*, chapter 5 ("Functors, Applicative
Functors, and Monads"). Each section of the file starts with an explanation
of what you need for its exercises, and links to the matching section of the
book.

**Key ideas:**

- A structure can `extend` other structures and inherits their fields.
- An applicative functor combines *independent* computations with `<$>` and
  `<*>`. It is weaker than a monad, and that is useful: a validation can
  collect every error instead of stopping at the first one.
- Applicative functors should follow some laws, and you can prove them for
  your own instances.
- `Alternative` adds choice and failure: `<|>`, `failure` and `guard`.
- Types have types too, organized in universes (`Type`, `Type 1`, ...), which
  is why classes like `Functor` mention universe levels.
- From `pure` and `bind` alone, Lean derives `<$>`, `<*>` and the rest of the
  family.

**Exercises:**

- Structures and inheritance: `duneEbook`, `basketTotal`.
- Applicative functors: `Applicative Checked`, `checkSeats`, `checkEmail`,
  `checkBooking`.
- The applicative contract: `optionMapId`, `checkedPureSeq`, `checkedPureId`.
- Alternatives: `answer?`, `Alternative Checked`, `checkGroup`.
- Universes: `swap`.
- The complete definitions: `Monad WithSettings`, `greeting`.
- **Final project:** a parser of comma-separated numbers: `Monad Parser`,
  `Alternative Parser`, `satisfy`, `digit`, `many1`, `number`, `sepBy1`,
  `numbers`.

**Hints:**

- `checkBooking` is one line: `Booking.mk <$> ... <*> ... <*> ...`.
- To prove the laws, take the values apart with `cases` and let `rfl` or
  `simp` finish each case.
- `many1` is one `p` followed by `many p`.
- In `sepBy1`, `sep *> p` reads a separator and a `p`, and keeps only the `p`.

---

## Module 7 — Induction: proving things about your programs

**File:** `Exercises/Induction.lean` (solutions: `Solutions/Induction.lean`)

**Read:** *Theorem Proving in Lean 4*, chapters 7 ("Inductive Types") and
8 ("Induction and Recursion").

**Key ideas:**

- `induction n with | zero => ... | succ k ih => ...` produces two cases. In
  the second one, `ih` (the induction hypothesis) says the property holds for
  `k`.
- The structure of the proof follows the structure of the function: if the
  function recurses on `xs`, do induction on `xs`.
- `simp [f]` unfolds the definition of `f`.
- `omega` automatically solves linear equalities and inequalities over natural
  numbers and integers.

**Exercises:** `ex1` to `ex3`, plus the **final project**: define `reverse` and
prove that it preserves the length of a list.

**Hint:** for the final project you will probably need a lemma about
`length (append xs ys)`. It is already proved in the file as `length_append`.

**When you finish module 7:** `lake build` should succeed **without any
`sorry`**. That marks the end of the introduction.

---

## After the modules: project ideas

Ideas for your own repositories, from easiest to hardest. Each one combines
programming and proving, which is what makes Lean interesting.

### 1. Verified sorting algorithms ⭐ (recommended first)

- Implement *insertion sort* and *merge sort* on `List Nat`.
- Prove that the result **is sorted**.
- Prove that the result **is a permutation** of the input.
- **You learn:** induction, auxiliary lemmas, inductive predicates (`Sorted`).
- **Estimated time:** 1 week.

### 2. Expression calculator with a verified optimizer

- Define an `Expr` type (numbers, variables, addition and multiplication) and an
  `eval` function.
- Write an optimizer (`x + 0 → x`, `x * 1 → x`, constant folding).
- Prove that `eval (optimize e) = eval e`.
- **You learn:** recursive inductive types and proofs by structural induction.
  It is the "hello world" of compiler verification.
- **Estimated time:** 1 week.

### 3. Mini compiler to a stack machine

- Extend project 2: compile `Expr` to instructions (`push`, `add`, `mul`) for a
  stack machine.
- Prove that running the compiled code gives the same result as `eval`.
- **You learn:** generalizing the induction hypothesis, the most important skill
  in verification.
- **Estimated time:** 1–2 weeks.

### 4. A command-line program in Lean

- A real tool you can run with `lake exe`: a word counter, a CSV-to-JSON
  converter or a to-do manager backed by a text file.
- **You learn:** `IO`, monads, file handling and Lean as a general-purpose
  language (*Functional Programming in Lean*, chapters 2–7).
- **Estimated time:** 1 week.

### 5. Verified data structures

- A binary search tree with `insert`, `find` and `delete`.
- Prove that the ordering invariant is preserved and that `find` finds what was
  inserted.
- **Extra:** do it with AVL or red-black trees.
- **Estimated time:** 2 weeks.

### 6. Mathematics with Mathlib

- Create a new project with `lake new my-math math`, which includes Mathlib,
  Lean's large mathematics library.
- Formalize classic results: the infinitude of primes, the irrationality of √2
  or properties of sequences.
- **You learn:** to search a huge library and to use powerful tactics (`ring`,
  `linarith`, `norm_num`, `exact?`).
- **Resource:** [Mathematics in Lean](https://leanprover-community.github.io/mathematics_in_lean/).
- **Estimated time:** ongoing.

### 7. Advent of Code in Lean

- Solve the [Advent of Code](https://adventofcode.com/) puzzles in Lean and,
  where possible, prove a property of your solution.
- A good way to practice daily with varied problems.

### Suggested layout for each repository

```
my-project/
├── README.md          ← what it is, what is proved and how to build it
├── lakefile.toml
├── lean-toolchain     ← pins the Lean version
├── MyProject.lean
└── MyProject/
    ├── Basic.lean     ← definitions
    └── Theorems.lean  ← proofs
```

Tip: add a *GitHub Action* to each repository that runs `lake build` on every
push, so you always know everything still compiles. The official action is
[`leanprover/lean-action`](https://github.com/leanprover/lean-action).

---

## Resources

| Resource | What for |
|---|---|
| [Functional Programming in Lean](https://lean-lang.org/functional_programming_in_lean/) | Lean as a programming language |
| [Theorem Proving in Lean 4](https://lean-lang.org/theorem_proving_in_lean4/) | Proofs and type theory |
| [Natural Number Game](https://adam.math.hhu.de/#/g/leanprover-community/nng4) | Practicing tactics as a game |
| [Mathematics in Lean](https://leanprover-community.github.io/mathematics_in_lean/) | Mathematics with Mathlib |
| [Lean Zulip](https://leanprover.zulipchat.com/) | Asking the community (`#new members` channel) |
| [Loogle](https://loogle.lean-lang.org/) | Searching for lemmas by their type |
