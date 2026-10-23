#!/usr/bin/env python3
"""Regression test for `lake exe check`.

Runs the checker on the untouched exercises and on a copy of the solutions
with deliberate mistakes, and verifies that each exercise gets the expected
verdict: ✅ solved, ⏳ pending or ❌ failed.

Usage (after `lake build`):
    python3 scripts/test_checker.py
"""

import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
BROKEN = ROOT / ".lake" / "checker-test"

# (file, original text, replacement): each one breaks an exercise on purpose.
MISTAKES = [
    # Wrong program: its tests fail.
    ("GettingToKnow.lean", "| x :: _ :: rest => x :: everyOther rest", "| x :: _ :: rest => x :: rest"),
    # Wrong program with side effects: its `#eval` tests fail.
    ("HelloWorld.lean", "    runBackwards actions\n    action\n", "    action\n    runBackwards actions\n"),
    # Proof left unfinished.
    ("Propositions.lean", "  intro hpq hqr hp\n  exact hqr (hpq hp)\n", "  sorry\n"),
    # Proof that does not compile.
    ("Propositions.lean", "  left\n  exact hp", "  right\n  exact hp"),
    # Proof that cheats with a new axiom.
    ("Propositions.lean", "theorem ex4", "axiom cheat : ∀ {p : Prop}, p\n\ntheorem ex4"),
    ("Propositions.lean", "  intro hpq hnq hp\n  exact hnq (hpq hp)\n", "  exact cheat\n"),
    # Statement made easier.
    ("Propositions.lean", "(h : a = b) : a + 0 = b := by", "(h : a = b) : a = b := by"),
    ("Propositions.lean", "  rw [Nat.add_zero, h]\n", "  exact h\n"),
    # Definition left unfinished; the theorem about it then breaks too.
    ("Induction.lean", "  | []      => []\n  | x :: xs => append (reverse xs) [x]\n", "  | _ => sorry\n"),
]

EXPECTED_BROKEN = {
    "GettingToKnow": {
        "predictedString": "✅", "natPuzzle": "✅", "intPuzzle": "✅", "secondsIn": "✅",
        "clamp": "✅", "surround": "✅", "Book.newEdition": "✅", "Time.toMinutes": "✅",
        "Time.later": "✅", "Shape.area": "✅", "power": "✅", "Expr.eval": "✅",
        "countWhere": "✅", "everyOther": "❌", "firstSome?": "✅", "unzipPairs": "✅",
        "splitSums": "✅", "isPalindrome": "✅", "initials": "✅", "applyTwice": "✅",
        "scoreLines": "✅", "Tree.insert": "✅", "Tree.toList": "✅", "Tree.contains": "✅",
    },
    "HelloWorld": {
        "introduce": "✅", "mysteryOutput": "✅", "withBorder": "✅", "runBackwards": "❌",
        "retry": "✅", "greeter": "✅", "readAll": "✅", "Counts.of": "✅", "wc": "✅",
        "findWord": "✅", "hint": "✅", "play": "✅",
    },
    "Propositions": {"ex1": "⏳", "ex2": "❌", "ex3": "✅", "ex4": "❌", "ex5": "❌"},
    "Induction": {"ex1": "✅", "ex2": "✅", "ex3": "✅", "reverse": "⏳", "length_reverse": "❌"},
}


def verdicts(directory: str) -> dict[str, dict[str, str]]:
    """Runs the checker and parses its report into {module: {exercise: icon}}."""
    result = subprocess.run(["lake", "exe", "check", "--dir", directory],
                            cwd=ROOT, capture_output=True, text=True)
    if result.returncode != 0:
        sys.exit(f"`lake exe check --dir {directory}` failed:\n{result.stdout}{result.stderr}")
    print(result.stdout)
    report: dict[str, dict[str, str]] = {}
    module = None
    for line in result.stdout.splitlines():
        if line and not line.startswith(" ") and line.endswith(".lean)"):
            module = line.split(" ")[0]
            report[module] = {}
        elif module and line.startswith("  ") and line[2:3] in "✅⏳❌":
            name = line[4:].split(":")[0]
            report[module][name] = line[2]
    return report


def compare(label: str, actual: dict, expected: dict) -> bool:
    if actual == expected:
        return True
    print(f"FAIL ({label}): expected {expected}\n{' ' * len(label)}        got {actual}")
    return False


def main() -> None:
    shutil.rmtree(BROKEN, ignore_errors=True)
    shutil.copytree(ROOT / "Solutions", BROKEN)
    for name, old, new in MISTAKES:
        path = BROKEN / name
        text = path.read_text()
        if text.count(old) != 1:
            sys.exit(f"test setup: {old!r} not found exactly once in Solutions/{name}")
        path.write_text(text.replace(old, new))

    ok = True
    unsolved = verdicts("Exercises")
    ok &= compare("untouched exercises", unsolved,
                  {m: {e: "⏳" for e in es} for m, es in EXPECTED_BROKEN.items()})
    ok &= compare("broken solutions", verdicts(str(BROKEN.relative_to(ROOT))), EXPECTED_BROKEN)
    shutil.rmtree(BROKEN)
    if not ok:
        sys.exit(1)
    print("The checker gives every exercise the expected verdict.")


if __name__ == "__main__":
    main()
