/-!
# Module 2 — Hello, World!

Goals:
* Write programs that talk to the outside world with `IO`.
* Read and write lines with the standard input and output streams.
* Sequence actions with `do`, and tell `let x := e` apart from `let x ← e`.
* Treat actions as values: store them, pass them around, run them later.
* Loop over a stream with `partial def`, and build a small `wc` tool.
* Use nested actions `(← e)`, early `return` and `for` loops in `do` blocks.

Read alongside: *Functional Programming in Lean*, chapter 2
(https://lean-lang.org/functional_programming_in_lean/Hello___-World___/).
Each section of this file covers a section of the chapter, with its own
explanation, so you can also work without the book.

Tip: to try a program, `#eval` it and its output appears in the Infoview.
-/

namespace HelloWorld

/-! ## Testing programs

You don't need to understand these helpers yet. `run input action` runs a
program as if `input` had been typed on the keyboard, and returns everything
it printed together with its result. Try it:

    #eval run "mango\n" favouriteFruit

The tests of this module use `run` and `expect`, and you can use them too.
-/

/-- Runs `action` with `input` as its standard input. Returns what it wrote to
the standard output and the standard error, and its result. -/
def run (input : String) (action : IO α) : IO (String × α) := do
  let inBuffer ← IO.mkRef { data := input.toUTF8 : IO.FS.Stream.Buffer }
  let outBuffer ← IO.mkRef ({} : IO.FS.Stream.Buffer)
  let oldIn ← IO.setStdin (.ofBuffer inBuffer)
  let oldOut ← IO.setStdout (.ofBuffer outBuffer)
  let oldErr ← IO.setStderr (.ofBuffer outBuffer)
  try
    let result ← action
    return (String.fromUTF8! (← outBuffer.get).data, result)
  finally
    discard <| IO.setStdin oldIn
    discard <| IO.setStdout oldOut
    discard <| IO.setStderr oldErr

/-- Like `run`, but only returns what the program printed. -/
def outputOf (input : String) (action : IO α) : IO String := do
  return (← run input action).1

/-- Fails, with a message, unless `actual` is `expected`. -/
def expect [BEq α] [Repr α] (actual expected : α) : IO Unit :=
  unless actual == expected do
    throw <| IO.userError s!"expected {repr expected}, but got {repr actual}"

/-! ## 1. Running a program

So far every `def` was a value or a function. A *program* is a value of type
`IO Unit`: a description of actions (printing, reading, ...) that Lean carries
out when the program runs. `IO.println "hi"` describes "print `hi`"; defining
it prints nothing, running it does.

A `do` block glues actions together, one per line. Inside it:

* `IO.getStdin` and `IO.getStdout` give the input and output *streams*;
* `stream.getLine` reads one line, *including* its final `"\n"`;
* `s.trimAscii` removes the spaces and newlines around a string (it returns a
  `String.Slice`, a view into the string; `.toString` turns it back into a
  `String`).

The last line of the block must have type `IO Unit` (or `IO α` in general).

Read more: https://lean-lang.org/functional_programming_in_lean/Hello___-World___/Running-a-Program/
-/

def hello : IO Unit := IO.println "Hello, world!"

#eval hello  -- Hello, world!

def favouriteFruit : IO Unit := do
  let stdin ← IO.getStdin
  IO.println "What is your favourite fruit?"
  let fruit ← stdin.getLine
  IO.println s!"{fruit.trimAscii} is a great choice!"

#eval run "mango\n" favouriteFruit
-- ("What is your favourite fruit?\nmango is a great choice!\n", ())

/-- Asks `What is your name?` and then `How old are you?`, and answers
`Nice to meet you, <name>! Next year you will be <age + 1>.` If the age is not
a number, it answers `That is not an age.` instead.

Hint: `String.toNat?` returns an `Option Nat`; `match` on it. -/
def introduce : IO Unit := do
  -- SOLUTION
  let stdin ← IO.getStdin
  IO.println "What is your name?"
  let name := (← stdin.getLine).trimAscii
  IO.println "How old are you?"
  let age := (← stdin.getLine).trimAscii.toString
  match age.toNat? with
  | some n => IO.println s!"Nice to meet you, {name}! Next year you will be {n + 1}."
  | none   => IO.println "That is not an age."
  -- END SOLUTION

-- TESTS
#eval do
  expect (← outputOf "Ada\n36\n" introduce)
    "What is your name?\nHow old are you?\nNice to meet you, Ada! Next year you will be 37.\n"
#eval do
  expect (← outputOf "Ada\nold\n" introduce)
    "What is your name?\nHow old are you?\nThat is not an age.\n"
-- END TESTS

/-! ## 2. Step by step

Lean runs a `do` block from top to bottom. Two kinds of `let` look alike but
do different things:

* `let x ← action` *runs* `action` now and names its result `x`;
* `let x := e` only gives `e` a name. Nothing runs. If `e` is an action, it
  runs every time `x` appears as a line of the block, and not before.

`pure v` is the action that does nothing and returns `v`, so
`let x ← pure v` is the same as `let x := v`.

Because actions are values, they can be arguments of functions, elements of
lists and results of functions, like numbers or strings.

Read more: https://lean-lang.org/functional_programming_in_lean/Hello___-World___/Step-By-Step/
-/

-- Try it on paper first: what does this print, and in which order?
def mystery : IO Unit := do
  let shout := IO.println "HEY!"
  let secret ← pure "psst"
  IO.println "start"
  shout
  IO.println secret
  shout

/-- The lines `mystery` prints, in order. Work it out on paper; the test runs
the program and compares. -/
def mysteryOutput : List String :=
  -- SOLUTION
  ["start", "HEY!", "psst", "HEY!"]
  -- END SOLUTION

-- TESTS
#eval do expect (← outputOf "" mystery) (String.join (mysteryOutput.map (· ++ "\n")))
-- END TESTS

-- An action as an argument: `twice` runs it two times.
def twice (action : IO Unit) : IO Unit := do
  action
  action

#eval twice (IO.println "hip hip hooray")

-- A list of actions; building it runs nothing.
def lineOfStars : List (IO Unit) :=
  [IO.println "*", IO.println "**", IO.println "***"]

-- `for x in xs do ...` runs the block once for each element.
#eval do
  for action in lineOfStars do
    action

/-- Prints a line of ten dashes, then runs `action`, then prints the dashes
again. -/
def withBorder (action : IO Unit) : IO Unit := do
  -- SOLUTION
  let border := IO.println "----------"
  border
  action
  border
  -- END SOLUTION

-- TESTS
#eval do expect (← outputOf "" (withBorder (IO.println "news"))) "----------\nnews\n----------\n"
-- END TESTS

/-- Runs the actions of a list from the *last* to the first. Use recursion on
the list, not `for`. -/
def runBackwards : List (IO Unit) → IO Unit
  -- SOLUTION: | _ => sorry
  | []                => pure ()
  | action :: actions => do
    runBackwards actions
    action
  -- END SOLUTION

-- TESTS
#eval do expect (← outputOf "" (runBackwards lineOfStars)) "***\n**\n*\n"
#eval do expect (← outputOf "" (runBackwards [])) ""
-- END TESTS

/-! Actions can also return values. `askReady` asks a question and returns
whether the answer was `yes`. -/

def askReady : IO Bool := do
  IO.println "Ready?"
  let answer ← (← IO.getStdin).getLine
  return answer.trimAscii.toString == "yes"

/-- Runs `action` until it returns `true`, at most `attempts` times. Returns
whether it ever returned `true`. -/
def retry (attempts : Nat) (action : IO Bool) : IO Bool :=
  -- SOLUTION
  match attempts with
  | 0     => pure false
  | n + 1 => do
    if ← action then
      pure true
    else
      retry n action
  -- END SOLUTION

-- TESTS
#eval do expect (← run "no\nyes\nno\n" (retry 3 askReady)) ("Ready?\nReady?\n", true)
#eval do expect (← run "no\nno\nyes\n" (retry 2 askReady)) ("Ready?\nReady?\n", false)
#eval do expect (← run "yes\n" (retry 0 askReady)) ("", false)
-- END TESTS

/-! ## 3. Starting a project

A real program lives in its own Lake project. `lake new hello` creates one
with a `Main.lean` file, and `lake build` compiles it to
`.lake/build/bin/hello`. When the program starts, Lean runs its `main`, which
can have one of these types:

* `main : IO Unit` ignores the command-line arguments;
* `main : List String → IO Unit` receives them, as a list of strings;
* `main : List String → IO UInt32` also returns an *exit code*: `0` means
  success, anything else means that something went wrong.

Error messages go to the standard error (`IO.eprintln`), not the standard
output, so that they don't mix with the real output of the program.

You can also run a single file that defines `main`, without a project. This
file defines one at the very end; once the final project is solved, play it
with:

    lake env lean --run Exercises/HelloWorld.lean

Read more: https://lean-lang.org/functional_programming_in_lean/Hello___-World___/Starting-a-Project/
-/

/-- The `main` of a `greeter` program: prints `Hello, <name>!` for each
argument and returns `0`. Without arguments, it prints
`Usage: greeter NAME...` to the standard error and returns `1`. -/
def greeter (args : List String) : IO UInt32 := do
  -- SOLUTION
  if args.isEmpty then
    IO.eprintln "Usage: greeter NAME..."
    return 1
  for name in args do
    IO.println s!"Hello, {name}!"
  return 0
  -- END SOLUTION

-- TESTS
#eval do expect (← run "" (greeter ["Ada", "Alan"])) ("Hello, Ada!\nHello, Alan!\n", 0)
#eval do expect (← run "" (greeter [])) ("Usage: greeter NAME...\n", 1)
-- END TESTS

/-! ## 4. Worked example: counting words

The book's example is `cat`, which prints files. Here we build `wc`, another
classic Unix tool, which counts the lines, words and characters of files.

A stream may be a file, the keyboard or the output of another program, so
Lean can't know whether it ends. A function that reads until the end calls
itself an unknown number of times, and Lean can't prove that it stops: mark it
`partial def`, and Lean doesn't ask. (It still needs the result type to have
some value, which is true of `IO` actions.)

`getLine` returns `""` only at the end of the stream; an empty line in the
middle is `"\n"`.

Read more: https://lean-lang.org/functional_programming_in_lean/Hello___-World___/Worked-Example___--cat/
-/

/-- Reads the rest of a stream and returns it as one string, newlines
included. -/
partial def readAll (stream : IO.FS.Stream) : IO String := do
  -- SOLUTION
  let line ← stream.getLine
  if line.isEmpty then
    pure ""
  else
    pure (line ++ (← readAll stream))
  -- END SOLUTION

-- TESTS
#eval do expect (← outputOf "one\n\ntwo\n" do IO.print (← readAll (← IO.getStdin))) "one\n\ntwo\n"
#eval do expect (← outputOf "" do IO.print (← readAll (← IO.getStdin))) ""
-- END TESTS

/-- The words of a string: the pieces between spaces, tabs and newlines. -/
def wordsOf (s : String) : List String :=
  (s.split Char.isWhitespace).toList.map (·.toString) |>.filter (!·.isEmpty)

#eval wordsOf "  the cat\tsat\n"  -- ["the", "cat", "sat"]

structure Counts where
  lines : Nat
  words : Nat
  chars : Nat
  deriving BEq, Repr

/-- The counts of a text: lines are the number of `'\n'` characters, words are
as in `wordsOf`, and chars is the number of characters. -/
def Counts.of (text : String) : Counts :=
  -- SOLUTION
  { lines := (text.toList.filter (· == '\n')).length,
    words := (wordsOf text).length,
    chars := text.length }
  -- END SOLUTION

-- TESTS
#guard Counts.of "one two\nthree\n" == { lines := 2, words := 3, chars := 14 }
#guard Counts.of "" == { lines := 0, words := 0, chars := 0 }
#guard Counts.of "no newline" == { lines := 0, words := 2, chars := 10 }
-- END TESTS

/-- Opens an input: `-` is the standard input, and anything else is a file
name. Returns `none` if the file doesn't exist.

`return` ends the `do` block early, like in other languages. -/
def openInput (name : String) : IO (Option IO.FS.Stream) := do
  if name == "-" then
    return some (← IO.getStdin)
  if !(← System.FilePath.pathExists name) then
    return none
  let handle ← IO.FS.Handle.mk name .read
  return some (.ofHandle handle)

/-- The `main` of `wc`: for each input in `args`, prints
`<lines> <words> <chars> <name>`. A missing file prints
`wc: <name>: no such file` to the standard error, and the other inputs are
still counted. Returns `1` if any input was missing, and `0` otherwise.

Hint: write a recursive helper, or use `for` with a mutable variable:
`let mut code := 0` and later `code := 1`. -/
def wc (args : List String) : IO UInt32 := do
  -- SOLUTION
  let mut code := 0
  for name in args do
    match ← openInput name with
    | none =>
      IO.eprintln s!"wc: {name}: no such file"
      code := 1
    | some stream =>
      let counts := Counts.of (← readAll stream)
      IO.println s!"{counts.lines} {counts.words} {counts.chars} {name}"
  return code
  -- END SOLUTION

-- TESTS
#eval do expect (← run "one two\nthree\n" (wc ["-"])) ("2 3 14 -\n", 0)
#eval do expect (← run "a b\n" (wc ["missing.txt", "-"])) ("wc: missing.txt: no such file\n1 2 4 -\n", 1)
#eval do
  IO.FS.withTempFile fun handle path => do
    handle.putStr "a file\nwith three lines\nhere\n"
    handle.flush
    expect (← run "" (wc [path.toString])) (s!"3 6 29 {path}\n", 0)
-- END TESTS

-- Try it, once `wc` is solved: count this project's README.
-- #eval wc ["README.md"]

/-! ## 5. Additional conveniences

A few things that make `do` blocks shorter:

* `(← e)` runs the action `e` in the middle of an expression:
  `IO.println (← stdin.getLine)` reads a line and prints it. Lean moves it to
  its own `let x ← e` line, just before the line where it appears.
* `if` without `else` and `unless cond do ...` run a step only sometimes.
* `return v` ends the block early with the result `v`.
* `for x in xs do ...` loops over a list, and `[0:n]` is the range
  `0, 1, ..., n - 1`. `let mut x := v` makes a variable that the loop can
  change with `x := ...`.

Read more: https://lean-lang.org/functional_programming_in_lean/Hello___-World___/Additional-Conveniences/
-/

def shoutBack : IO Unit := do
  let line := (← (← IO.getStdin).getLine).trimAscii
  unless line.isEmpty do
    IO.println line.toString.toUpper

#eval outputOf "quiet please\n" shoutBack  -- "QUIET PLEASE\n"

/-- Reads the standard input and prints the lines that contain `word` as one
of their words (see `wordsOf`), each with its line number (counting from 1):
`<number>: <line>`. The lines are printed without their newline. -/
def findWord (word : String) : IO Unit := do
  -- SOLUTION
  let lines := (← readAll (← IO.getStdin)).splitOn "\n"
  let mut number := 1
  for line in lines do
    if (wordsOf line).contains word then
      IO.println s!"{number}: {line}"
    number := number + 1
  -- END SOLUTION

-- TESTS
#eval do
  expect (← outputOf "the cat\nthe dog\na cat and a dog\ncatalog\n" (findWord "cat"))
    "1: the cat\n3: a cat and a dog\n"
#eval do expect (← outputOf "nothing here\n" (findWord "cat")) ""
-- END TESTS

/-! ## Final project of the module: a guessing game

The computer picks a secret number and the player guesses it. After each guess,
the game says whether the secret is higher or lower. -/

/-- The game's answer to a guess. -/
def hint (secret guess : Nat) : String :=
  -- SOLUTION
  if guess < secret then "Higher!"
  else if secret < guess then "Lower!"
  else "Correct!"
  -- END SOLUTION

-- TESTS
#guard hint 50 20 = "Higher!"
#guard hint 50 80 = "Lower!"
#guard hint 50 50 = "Correct!"
-- END TESTS

/-- Plays the game: asks `Your guess?`, reads a line and prints its `hint`,
until the guess is right. Then it prints `You needed <n> guesses.` Lines that
are not numbers print `That is not a number.` and don't count as guesses. If
the input ends first, it prints `Bye!`.

`guesses` is how many guesses were made before this one. -/
partial def play (secret : Nat) (guesses : Nat := 0) : IO Unit := do
  -- SOLUTION
  IO.println "Your guess?"
  let line ← (← IO.getStdin).getLine
  if line.isEmpty then
    IO.println "Bye!"
    return
  match line.trimAscii.toString.toNat? with
  | none =>
    IO.println "That is not a number."
    play secret guesses
  | some guess =>
    IO.println (hint secret guess)
    if guess == secret then
      IO.println s!"You needed {guesses + 1} guesses."
    else
      play secret (guesses + 1)
  -- END SOLUTION

-- TESTS
#eval do
  expect (← outputOf "50\n25\n37\n" (play 37))
    ("Your guess?\nLower!\nYour guess?\nHigher!\nYour guess?\nCorrect!\n" ++
     "You needed 3 guesses.\n")
#eval do
  expect (← outputOf "abc\n7\n" (play 7))
    "Your guess?\nThat is not a number.\nYour guess?\nCorrect!\nYou needed 1 guesses.\n"
#eval do expect (← outputOf "1\n" (play 7)) "Your guess?\nHigher!\nYour guess?\nBye!\n"
-- END TESTS

end HelloWorld

/-- Run with `lake env lean --run Exercises/HelloWorld.lean` to play. -/
def main : IO Unit := do
  IO.println "I'm thinking of a number between 1 and 100."
  HelloWorld.play (← IO.rand 1 100)
