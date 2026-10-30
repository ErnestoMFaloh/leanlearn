# leanlearn

A hands-on exercise workbook for learning [Lean 4](https://lean-lang.org/), a
functional programming language that is also a proof assistant.

Each module is a Lean file with worked examples followed by **exercises**
marked with `sorry`. You learn by replacing every `sorry` with a working
definition or proof. Lean checks your work for you: when a file compiles with no
`sorry` left, you have solved it.

The full study guide (what to read, key ideas and hints for each module, plus
project ideas for afterwards) is in [`GUIDE.md`](GUIDE.md), and on the
**[website](https://ernestomfaloh.github.io/leanlearn/)**, where you can also
open each module in the Lean playground and solve it in your browser.

## Modules

| # | Topic | Exercises | Solutions |
|---|-------|-----------|-----------|
| 1 | Getting to know Lean: functions, structures, inductive types, polymorphism | [`Exercises/GettingToKnow.lean`](Exercises/GettingToKnow.lean) | [solutions](Solutions/GettingToKnow.lean) |
| 2 | Hello, World!: programs with `IO`, `do` blocks, a `wc` clone | [`Exercises/HelloWorld.lean`](Exercises/HelloWorld.lean) | [solutions](Solutions/HelloWorld.lean) |
| 3 | Propositions, proofs and indexing: propositions as types, basic tactics, safe indexing | [`Exercises/Propositions.lean`](Exercises/Propositions.lean) | [solutions](Solutions/Propositions.lean) |
| 4 | Overloading and type classes: instances, arrays, standard classes, coercions | [`Exercises/TypeClasses.lean`](Exercises/TypeClasses.lean) | [solutions](Solutions/TypeClasses.lean) |
| 5 | Monads: `Option`, `Except`, state and logs as one pattern, `do` in every monad | [`Exercises/Monads.lean`](Exercises/Monads.lean) | [solutions](Solutions/Monads.lean) |
| 6 | Functors, applicative functors and monads: validation, alternatives, a parser | [`Exercises/Applicative.lean`](Exercises/Applicative.lean) | [solutions](Solutions/Applicative.lean) |
| 7 | Induction: proving properties of your own programs | [`Exercises/Induction.lean`](Exercises/Induction.lean) | [solutions](Solutions/Induction.lean) |

Work in `Exercises/`. To see how you are doing, run:

```
$ lake exe check Propositions
Propositions (Exercises/Propositions.lean)
  ✅ reverseFact
  ✅ takeFact
  ❌ bigPower: error at line 121: …
  ⏳ zeroTimes: still has `sorry`
  …
  2/20 solved
```

The checker never compares your answer with the solution as text, because
there is usually more than one correct answer. An exercise counts as solved
when it compiles without `sorry`, its statement is unchanged, it relies on no
extra axioms and, for programs, its tests pass. Run `lake exe check` with no
module name to check them all.

If you get stuck, or once an exercise is solved and you want to compare
approaches, the matching file in `Solutions/` has every exercise solved
between `-- SOLUTION` and `-- END SOLUTION` lines.

## Getting started

1. Install [elan](https://github.com/leanprover/elan), the Lean version
   manager:
   ```bash
   curl https://raw.githubusercontent.com/leanprover/elan/master/elan-init.sh -sSf | sh
   ```
2. Clone this repository and build it. The first build downloads the Lean
   version pinned in `lean-toolchain`:
   ```bash
   git clone <repository-url> leanlearn
   cd leanlearn
   lake build
   ```
   The build succeeds with a warning for each `sorry` in `Exercises/`. Those
   are your exercises.
3. Open the folder in [VS Code](https://code.visualstudio.com/) with the
   **Lean 4** extension (`leanprover.lean4`) and start with module 1.

## Contributing

Ideas, fixes and new exercises are welcome. See
[`CONTRIBUTING.md`](CONTRIBUTING.md) for how the exercises are generated from
the solutions.

## License

The Lean code is licensed under the [Apache License 2.0](LICENSE). The written
material (`README.md`, `GUIDE.md` and other Markdown files) is licensed under
[CC BY 4.0](https://creativecommons.org/licenses/by/4.0/).
