import Lean

/-!
# `lake exe check`: tells learners which exercises they have solved

For each module, the checker elaborates the learner's file in `Exercises/` and
the reference file in `Solutions/`, then compares them declaration by
declaration. It never compares proofs or code as text. An exercise is solved
when:

* its statement (its type) is exactly the one in the solution;
* it compiles, without `sorry` and without axioms beyond Lean's standard ones;
* for programs, the tests in the solution's `-- TESTS` block pass.

The exercises of a module are the declarations of `Solutions/<Module>.lean`
that contain a `-- SOLUTION` marker (see `CONTRIBUTING.md`).

Usage:

    lake exe check                   check every module
    lake exe check Logic Induction   check only these modules
    lake exe check --dir Solutions   check another folder (used in CI)
    lake exe check --strict          exit with an error unless all is solved
-/

open Lean Elab

namespace Checker

/-- The axioms an exercise may rely on: the standard ones of Lean. -/
def allowedAxioms : List Name := [``propext, ``Classical.choice, ``Quot.sound]

inductive Status where
  | solved
  | pending (reason : String)
  | failed (reason : String)

structure Elaborated where
  env : Environment
  /-- Error messages, as (line, first line of the text). -/
  errors : List (Nat × String)

/-- Elaborates a whole Lean file given as text, collecting its errors. -/
def elaborate (input fileName : String) : IO Elaborated := do
  let inputCtx := Parser.mkInputContext input fileName
  let (header, parserState, messages) ← Parser.parseHeader inputCtx
  let (env, messages) ← processHeader header {} messages inputCtx
  let commandState := Command.mkState env messages {}
  let s ← IO.processCommands inputCtx parserState commandState
  let mut errors := []
  for msg in s.commandState.messages.toList do
    if msg.severity == .error then
      let text ← msg.data.toString
      errors := errors ++ [(msg.pos.line, (text.splitOn "\n").headD "")]
  return { env := s.commandState.env, errors }

/-- Runs a `CoreM` action in the given environment. -/
def runCore (env : Environment) (x : CoreM α) : IO α := do
  let (a, _) ← x.toIO { fileName := "<checker>", fileMap := default } { env }
  return a

/-- Lines (1-based) of the source that start with the given marker. -/
def markerLines (source : String) (marker : String) : List Nat :=
  (source.splitOn "\n").zipIdx.filterMap fun (line, i) =>
    if line.trimLeft == marker || line.trimLeft.startsWith (marker ++ ":") then
      some (i + 1)
    else none

/-- First and last line of a declaration, if it was written in this file. -/
def declLines (env : Environment) (name : Name) : IO (Option (Nat × Nat)) :=
  runCore env do
    let some ranges ← findDeclarationRanges? name | return none
    return some (ranges.range.pos.line, ranges.range.endPos.line)

/-- The exercises of a solution file, in source order, with their line ranges. -/
def exercises (solution : Elaborated) (source : String) :
    IO (List (Name × Nat × Nat)) := do
  let markers := markerLines source "-- SOLUTION"
  let mut found := []
  for (name, _) in solution.env.constants.toList do
    if solution.env.getModuleIdxFor? name |>.isSome then continue
    if name.isInternalDetail then continue
    let some (first, last) ← declLines solution.env name | continue
    if markers.any (fun l => first ≤ l && l ≤ last) then
      found := found ++ [(name, first, last)]
  return found.mergeSort (fun a b => a.2.1 ≤ b.2.1)

/-- The `-- TESTS` blocks of a solution file, as (first line, test lines). -/
def testBlocks (source : String) : List (Nat × List String) := Id.run do
  let lines := (source.splitOn "\n").toArray
  let mut blocks := []
  let mut current : Option (Nat × List String) := none
  for i in [0:lines.size] do
    let line := lines[i]!.trim
    match current with
    | none => if line == "-- TESTS" then current := some (i + 1, [])
    | some (start, acc) =>
      if line == "-- END TESTS" then
        blocks := blocks ++ [(start, acc)]
        current := none
      else
        current := some (start, acc ++ [lines[i]!])
  return blocks

/-- Each exercise's tests: the blocks that come after it and before the next one. -/
def testsFor (exs : List (Name × Nat × Nat)) (blocks : List (Nat × List String)) :
    Name → List String := fun name =>
  match exs.find? (·.1 == name) with
  | none => []
  | some (_, _, last) =>
    let next := (exs.filterMap fun (_, first, _) => if first > last then some first else none).min?
    blocks.foldl (init := []) fun acc (start, lines) =>
      if start > last && next.all (start < ·) then acc ++ lines else acc

/-- The top-level namespace of a declaration, in which its tests are run. -/
def topNamespace : Name → Option Name
  | .str .anonymous _ => none
  | name => name.components.head?

/-- Checks one exercise. `testErrors` are the errors raised by its tests. -/
def checkExercise (learner solution : Elaborated) (name : Name)
    (testErrors : List (Nat × String)) : IO Status := do
  let some expected := solution.env.find? name | return .failed "missing from the solutions"
  let some actual := learner.env.find? name
    | match learner.errors.head? with
      | some (line, msg) => return .failed s!"not found; first error at line {line}: {msg}"
      | none => return .failed "not found: was it renamed or deleted?"
  if let some (first, last) ← declLines learner.env name then
    if let some (line, msg) := learner.errors.find? (fun (l, _) => first ≤ l && l ≤ last) then
      return .failed s!"error at line {line}: {msg}"
  if actual.type != expected.type || actual.levelParams != expected.levelParams then
    return .failed "its statement was changed; restore it from the solution file"
  if actual.value?.any (·.hasSorry) then
    return .pending "still has `sorry`"
  let axioms ← runCore learner.env (collectAxioms name)
  if axioms.contains ``sorryAx then
    return .pending "uses an exercise that still has `sorry`"
  if let some ax := axioms.find? (!allowedAxioms.contains ·) then
    return .failed s!"relies on the axiom `{ax}`"
  if let some (_, msg) := testErrors.head? then
    return .failed s!"a test failed: {msg}"
  return .solved

/-- Shows a name without its module namespace: `Programming.Tree.size` ↦ `Tree.size`. -/
def shortName (name : Name) : String :=
  match name.components with
  | [single] => single.toString
  | _ :: rest => ".".intercalate (rest.map (·.toString))
  | [] => name.toString

/-- Checks a module and prints a report. Returns (solved, total). -/
def checkModule (dir : String) (module : String) : IO (Nat × Nat) := do
  let solutionPath := s!"Solutions/{module}.lean"
  let learnerPath := s!"{dir}/{module}.lean"
  let solutionSource ← IO.FS.readFile solutionPath
  let learnerSource ← IO.FS.readFile learnerPath
  let solution ← elaborate solutionSource solutionPath
  let exs ← exercises solution solutionSource
  let blocks := testBlocks solutionSource

  -- Append every exercise's tests to the learner's file and elaborate it once,
  -- remembering which lines belong to which exercise.
  let mut input := learnerSource
  let mut testLines : List (Name × Nat × Nat) := []
  for (name, _, _) in exs do
    let tests := testsFor exs blocks name
    if tests.isEmpty then continue
    let ns := (topNamespace name).map (·.toString)
    let header := ns.map (s!"namespace {·}\n") |>.getD ""
    let footer := ns.map (s!"end {·}\n") |>.getD ""
    let first := (input.splitOn "\n").length + 1
    input := input ++ "\n" ++ header ++ "\n".intercalate tests ++ "\n" ++ footer
    testLines := testLines ++ [(name, first, (input.splitOn "\n").length)]
  let learnerLineCount := (learnerSource.splitOn "\n").length
  let learnerFull ← elaborate input learnerPath
  let learner := { learnerFull with
    errors := learnerFull.errors.filter (·.1 ≤ learnerLineCount) }

  IO.println s!"\n{module} ({learnerPath})"
  let mut solved := 0
  for (name, _, _) in exs do
    let testErrors := match testLines.find? (·.1 == name) with
      | some (_, first, last) => learnerFull.errors.filter fun (l, _) => first ≤ l && l ≤ last
      | none => []
    match ← checkExercise learner solution name testErrors with
    | .solved =>
      solved := solved + 1
      IO.println s!"  ✅ {shortName name}"
    | .pending reason => IO.println s!"  ⏳ {shortName name}: {reason}"
    | .failed reason => IO.println s!"  ❌ {shortName name}: {reason}"
  IO.println s!"  {solved}/{exs.length} solved"
  return (solved, exs.length)

/-- The modules, in the order `Solutions.lean` imports them. -/
def allModules : IO (List String) := do
  let root ← IO.FS.readFile "Solutions.lean"
  return (root.splitOn "\n").filterMap fun line =>
    (line.trim.dropPrefix? "import Solutions.").map (·.toString)

end Checker

open Checker in
def main (args : List String) : IO UInt32 := do
  initSearchPath (← findSysroot)
  let mut dir := "Exercises"
  let mut strict := false
  let mut modules := []
  let mut rest := args
  while !rest.isEmpty do
    match rest with
    | "--dir" :: d :: more => dir := d; rest := more
    | "--strict" :: more => strict := true; rest := more
    | m :: more => modules := modules ++ [m]; rest := more
    | [] => rest := []
  if modules.isEmpty then modules ← allModules
  let mut solved := 0
  let mut total := 0
  for module in modules do
    let (s, t) ← checkModule dir module
    solved := solved + s
    total := total + t
  IO.println s!"\nTotal: {solved}/{total} exercises solved"
  return if strict && solved < total then 1 else 0
