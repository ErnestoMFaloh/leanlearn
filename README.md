# leanlearn

A hands-on exercise workbook for learning [Lean 4](https://lean-lang.org/), a
functional programming language that is also a proof assistant.

Each module is a Lean file with worked examples followed by **exercises**
marked with `sorry`. You learn by replacing every `sorry` with a working
definition or proof. Lean checks your work for you: when a file compiles with no
`sorry` left, you have solved it.

The full study guide (what to read, key ideas and hints for each module, plus
project ideas for afterwards) is in [`GUIDE.md`](GUIDE.md).

## Modules

| # | Topic | Exercises | Solutions |
|---|-------|-----------|-----------|
| 1 | Lean as a programming language: functions, recursion, inductive types | [`Exercises/Programming.lean`](Exercises/Programming.lean) | [solutions](Solutions/Programming.lean) |
| 2 | Propositions as types, basic tactics, propositional logic | [`Exercises/Logic.lean`](Exercises/Logic.lean) | [solutions](Solutions/Logic.lean) |
| 3 | Induction: proving properties of your own programs | [`Exercises/Induction.lean`](Exercises/Induction.lean) | [solutions](Solutions/Induction.lean) |

Work in `Exercises/`. If you get stuck, or once your file compiles and you want
to compare approaches, the matching file in `Solutions/` has every exercise
solved. Each solution sits between `-- SOLUTION` and `-- END SOLUTION` lines.
There is usually more than one correct answer: if Lean accepts yours, it is
right.

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
