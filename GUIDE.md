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
4. **Wrap-up:** commit your work.

If you keep your solutions in your own fork, commit every time you finish
something, even a single exercise:

```bash
git add .
git commit -m "Module N: exercise X solved"
git push
```

---

## Module 1 — Lean as a programming language

**File:** `LeanLearn/Programming.lean`

**Read:** *Functional Programming in Lean*, chapter 1 ("Getting to Know Lean").

**Key ideas:**

- `#eval` evaluates an expression and `#check` shows its type.
- `def` defines functions. Types are written after `:`.
- Pattern matching with `|` and `match`.
- Recursion: Lean must check that it terminates, and it can when the recursive
  call uses a "smaller" argument (`n` instead of `n + 1`, `xs` instead of
  `x :: xs`).
- `inductive` defines new types and `structure` defines records with fields.

**Exercises:** `length`, `reverse` and `Tree.size`.

**Hint:** for `reverse`, the `++` operator appends two lists.

**Extra challenge:** implement `Tree.insert` for a binary search tree and
`Tree.toList`, which traverses it in order.

---

## Module 2 — Propositions and proofs

**File:** `LeanLearn/Logic.lean`

**Read:** *Theorem Proving in Lean 4*, chapters 3 ("Propositions and Proofs")
and 5 ("Tactics").

**Central idea:** in Lean, **a proposition is a type and a proof is a value of
that type**. Proving `p → q` means writing a function that turns proofs of `p`
into proofs of `q`.

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
| An equality that holds by computation | `rfl` |
| Simplify automatically | `simp` |

**Exercises:** `ex1` to `ex5`.

**Extra practice:** the [Natural Number Game](https://adam.math.hhu.de/#/g/leanprover-community/nng4)
is the best way to get comfortable with tactics. Try to complete the
*Tutorial* and *Addition* worlds.

---

## Module 3 — Induction: proving things about your programs

**File:** `LeanLearn/Induction.lean`

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

**When you finish module 3:** `lake build` should succeed **without any
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
