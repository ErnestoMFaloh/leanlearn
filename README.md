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

| # | Topic | File |
|---|-------|------|
| 1 | Lean as a programming language: functions, recursion, inductive types | [`LeanLearn/Programming.lean`](LeanLearn/Programming.lean) |
| 2 | Propositions as types, basic tactics, propositional logic | [`LeanLearn/Logic.lean`](LeanLearn/Logic.lean) |
| 3 | Induction: proving properties of your own programs | [`LeanLearn/Induction.lean`](LeanLearn/Induction.lean) |

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
   The build succeeds with a warning for each `sorry`. Those are your
   exercises.
3. Open the folder in [VS Code](https://code.visualstudio.com/) with the
   **Lean 4** extension (`leanprover.lean4`) and start with module 1.

## License

The Lean code is licensed under the [Apache License 2.0](LICENSE). The written
material (`README.md`, `GUIDE.md` and other Markdown files) is licensed under
[CC BY 4.0](https://creativecommons.org/licenses/by/4.0/).
