#!/usr/bin/env python3
"""Generate the exercise files in `Exercises/` from the solutions in `Solutions/`.

Solutions mark the parts a learner must write with these comment lines:

    -- SOLUTION                 the block is replaced by `sorry`
    -- SOLUTION: <stub>         the block is replaced by <stub>
    -- END SOLUTION

    -- SOLUTION ONLY            the block is removed from the exercises
    -- END SOLUTION ONLY        (e.g. helper lemmas that would give hints)

The replacement keeps the indentation of the opening marker.

Usage:
    python3 scripts/generate.py           write Exercises/
    python3 scripts/generate.py --check   exit with an error if Exercises/ is out of date
"""

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SOLUTIONS = ROOT / "Solutions"
EXERCISES = ROOT / "Exercises"

BEGIN = re.compile(r"^(\s*)-- SOLUTION(?::(.*))?$")
END = re.compile(r"^\s*-- END SOLUTION$")
BEGIN_ONLY = re.compile(r"^\s*-- SOLUTION ONLY$")
END_ONLY = re.compile(r"^\s*-- END SOLUTION ONLY$")


def header(name: str) -> str:
    return (
        f"-- Stuck? The solutions are in `Solutions/{name}`.\n"
        f"-- Contributors: this file is generated from `Solutions/{name}`;\n"
        f"-- edit that file and run `python3 scripts/generate.py`.\n\n"
    )


def strip_solutions(text: str, source: str) -> str:
    out = []
    state = None  # None, "solution" or "only"
    start = 0
    for number, line in enumerate(text.splitlines(), start=1):
        if state is None:
            if BEGIN_ONLY.match(line):
                state, start = "only", number
            elif m := BEGIN.match(line):
                indent, stub = m.group(1), (m.group(2) or "").strip()
                out.append(indent + (stub or "sorry"))
                state, start = "solution", number
            elif END.match(line) or END_ONLY.match(line):
                sys.exit(f"{source}:{number}: closing marker without an opening one")
            else:
                out.append(line)
        elif state == "solution":
            if END.match(line):
                state = None
            elif BEGIN.match(line) or BEGIN_ONLY.match(line) or END_ONLY.match(line):
                sys.exit(f"{source}:{number}: unexpected marker inside the block opened at line {start}")
        elif state == "only":
            if END_ONLY.match(line):
                state = None
            elif BEGIN.match(line) or BEGIN_ONLY.match(line) or END.match(line):
                sys.exit(f"{source}:{number}: unexpected marker inside the block opened at line {start}")
    if state is not None:
        sys.exit(f"{source}:{start}: block is never closed")
    return "\n".join(out) + "\n"


def expected_files() -> dict[Path, str]:
    files = {}
    for path in sorted(SOLUTIONS.glob("*.lean")):
        source = f"Solutions/{path.name}"
        files[EXERCISES / path.name] = header(path.name) + strip_solutions(path.read_text(), source)
    root = (ROOT / "Solutions.lean").read_text()
    files[ROOT / "Exercises.lean"] = root.replace("import Solutions.", "import Exercises.")
    return files


def main() -> None:
    check = "--check" in sys.argv[1:]
    files = expected_files()
    stale = [p for p, content in files.items() if not p.exists() or p.read_text() != content]
    extra = [p for p in EXERCISES.glob("*.lean") if p not in files]

    if check:
        for p in stale:
            print(f"out of date: {p.relative_to(ROOT)}")
        for p in extra:
            print(f"no matching solution: {p.relative_to(ROOT)}")
        if stale or extra:
            sys.exit("Run `python3 scripts/generate.py` and commit the result.")
        print("Exercises are up to date.")
        return

    EXERCISES.mkdir(exist_ok=True)
    for p in stale:
        p.write_text(files[p])
        print(f"wrote {p.relative_to(ROOT)}")
    for p in extra:
        p.unlink()
        print(f"removed {p.relative_to(ROOT)}")
    if not stale and not extra:
        print("Exercises are already up to date.")


if __name__ == "__main__":
    main()
