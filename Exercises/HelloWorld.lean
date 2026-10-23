-- Stuck? The solutions are in `Solutions/HelloWorld.lean`.
-- Contributors: this file is generated from `Solutions/HelloWorld.lean`;
-- edit that file and run `python3 scripts/generate.py`.

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

In module 1, testing a function was easy: give it some arguments and compare
its result with the expected one. The programs of this module are different,
because they read what a person types and print text on the screen, and a test
can't sit at the keyboard. So before we start, here are a few helpers that
pretend to be that person.

`run input action` runs a program as if `input` had been typed on the
keyboard, and returns everything the program printed, together with its
result. `outputOf` is the same but only returns what was printed, and
`expect` fails with a message when two values are different. The tests of
this module are written with them, and you can use them too, for example:

    #eval run "mango\n" favouriteFruit

Their code uses ideas from later chapters, so you don't need to read it now.
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

In module 1 a program was an expression, and running it meant working out its
value. That is a fine way to compute, but a useful program must also talk to
the outside world: print text, read what the user types, open files. None of
these is a value that can be worked out. Printing twice is not the same as
printing once, and reading a line gives a different answer each time.

Lean solves this by keeping the two worlds apart. A value of type `IO Unit`
is a *description* of things to do (print this, read that), and Lean only
carries those things out when the program runs. `IO.println "hi"` is such a
value: it describes "print `hi`". Defining it prints nothing; running it
does. Every ordinary function stays the same as in module 1, always giving the
same result for the same arguments, and only `IO` actions touch the world.

A program rarely does just one thing, so we need to put actions in a sequence.
That is the job of a `do` block: you write one action per line, and the whole
block is a single action that carries out the lines in order. Its last line
decides what the block returns.

Read more: https://lean-lang.org/functional_programming_in_lean/Hello___-World___/Running-a-Program/
-/

def hello : IO Unit := IO.println "Hello, world!"

#eval hello  -- Hello, world!

/-! Printing is half of the conversation; the other half is reading. Text
typed at the keyboard (or sent by another program) arrives through the
*standard input*, a stream that `IO.getStdin` gives you, and `stream.getLine`
reads one line from it.

Both of these are actions, and their results are only known when the program
runs. To use such a result, write `let x ← action` in the `do` block: the
arrow runs the action at that point and gives its result the name `x`.

The line that was read still ends with its `"\n"`, so `trimAscii` removes the
spaces and newlines around it. Like `drop` in module 1, `trimAscii` returns a
slice; `.copy` turns it into a `String` when you need one, for example to call
`String.toNat?`. -/

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
  sorry

-- Tests (`lake exe check` runs them for you):
-- #eval do
--   expect (← outputOf "Ada\n36\n" introduce)
--     "What is your name?\nHow old are you?\nNice to meet you, Ada! Next year you will be 37.\n"
-- #eval do
--   expect (← outputOf "Ada\nold\n" introduce)
--     "What is your name?\nHow old are you?\nThat is not an age.\n"

/-! ## 2. Step by step

The `do` blocks of section 1 were short enough to follow at a glance. As they
grow, it pays to be precise about what happens at each line, because one
detail surprises almost everyone at first.

Lean runs a `do` block from top to bottom, and there are two kinds of `let`
that look alike but do very different things. `let x ← action`, as we saw,
*runs* the action at that point and names its result: after
`let line ← stdin.getLine`, `line` is the text that was read. `let x := e`,
the `let` of module 1, only gives `e` a name and runs nothing. If `e` is an
action, `x` is that action, still waiting: it runs each time `x` appears later
as a line of the block, and not before.

Sometimes a block has to return a value that it already has, without doing
anything. The action `pure v` is exactly that: it does nothing and returns
`v`.

Read more: https://lean-lang.org/functional_programming_in_lean/Hello___-World___/Step-By-Step/
-/

/-! Here is a small program that mixes both kinds of `let`. Before running
it, work out on paper what it prints and in which order: that is the first
exercise. -/

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
  sorry

-- Tests (`lake exe check` runs them for you):
-- #eval do expect (← outputOf "" mystery) (String.join (mysteryOutput.map (· ++ "\n")))

/-! Because actions are values, they can be passed to functions like
numbers or strings. `twice` receives an action and builds a bigger action that
runs it two times. -/

def twice (action : IO Unit) : IO Unit := do
  action
  action

#eval twice (IO.println "hip hip hooray")

/-! Actions can also be stored in a list, and building the list runs nothing.
To run them, a `do` block can loop over the list: `for x in xs do` runs the
indented lines below it once for each entry `x` of `xs`. -/

def lineOfStars : List (IO Unit) :=
  [IO.println "*", IO.println "**", IO.println "***"]

#eval do
  for action in lineOfStars do
    action

/-- Prints a line of ten dashes, then runs `action`, then prints the dashes
again. -/
def withBorder (action : IO Unit) : IO Unit := do
  sorry

-- Tests (`lake exe check` runs them for you):
-- #eval do expect (← outputOf "" (withBorder (IO.println "news"))) "----------\nnews\n----------\n"

/-- Runs the actions of a list from the *last* to the first. Use recursion on
the list, not `for`. -/
def runBackwards : List (IO Unit) → IO Unit
  | _ => sorry

-- Tests (`lake exe check` runs them for you):
-- #eval do expect (← outputOf "" (runBackwards lineOfStars)) "***\n**\n*\n"
-- #eval do expect (← outputOf "" (runBackwards [])) ""

/-! So far our actions only did something, and their type was `IO Unit`,
where `Unit` means "no interesting result". But an action can also produce a
value, like `getLine` produces a string. An action of type `IO Bool`, for
example, does something and then returns a `Bool`. `askReady` asks a question
and returns whether the answer was `yes`; the last line of its block uses
`pure` to return the answer. -/

def askReady : IO Bool := do
  IO.println "Ready?"
  let stdin ← IO.getStdin
  let answer ← stdin.getLine
  pure (answer.trimAscii.copy == "yes")

/-- Runs `action` until it returns `true`, at most `attempts` times. Returns
whether it ever returned `true`. -/
def retry (attempts : Nat) (action : IO Bool) : IO Bool :=
  sorry

-- Tests (`lake exe check` runs them for you):
-- #eval do expect (← run "no\nyes\nno\n" (retry 3 askReady)) ("Ready?\nReady?\n", true)
-- #eval do expect (← run "no\nno\nyes\n" (retry 2 askReady)) ("Ready?\nReady?\n", false)
-- #eval do expect (← run "yes\n" (retry 0 askReady)) ("", false)

/-! ## 3. Starting a project

A real program lives in its own Lake project. `lake new hello` creates one
with a `Main.lean` file, and `lake build` compiles it to
`.lake/build/bin/hello`. When the program starts, Lean runs the definition
called `main`.

The simplest `main` has type `IO Unit`. If the program needs the words typed
after its name on the command line, `main` takes them as a `List String`. And
if it should report whether it worked, it returns a number, the *exit code*:
`0` means success, and anything else means that something went wrong. So the
most complete form is `main : List String → IO UInt32`.

Error messages go to the *standard error* with `IO.eprintln`, instead of the
standard output, so that they don't get mixed with the real output of the
program.

A `main` that checks its arguments often wants to stop as soon as something
is wrong. Inside a `do` block, `return v` does that: it ends the whole block
at once, with the result `v`, like `return` in other languages. For the same
reason, an `if` in a `do` block may leave out its `else`. When the condition
is false, the block simply goes on with the next line.

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
  sorry

-- Tests (`lake exe check` runs them for you):
-- #eval do expect (← run "" (greeter ["Ada", "Alan"])) ("Hello, Ada!\nHello, Alan!\n", 0)
-- #eval do expect (← run "" (greeter [])) ("Usage: greeter NAME...\n", 1)

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

The code below often uses a result only once, and naming it with
`let x ← e` on its own line gets tedious. Writing `(← e)` in the middle of an
expression does the same in place: `IO.println (← stdin.getLine)` reads a line
and prints it. Section 5 says more about how it works.

Read more: https://lean-lang.org/functional_programming_in_lean/Hello___-World___/Worked-Example___--cat/
-/

/-- Reads the rest of a stream and returns it as one string, newlines
included. -/
partial def readAll (stream : IO.FS.Stream) : IO String := do
  sorry

-- Tests (`lake exe check` runs them for you):
-- #eval do expect (← outputOf "one\n\ntwo\n" do IO.print (← readAll (← IO.getStdin))) "one\n\ntwo\n"
-- #eval do expect (← outputOf "" do IO.print (← readAll (← IO.getStdin))) ""

/-- The words of a string: the pieces between spaces, tabs and newlines. -/
def wordsOf (s : String) : List String :=
  ((s.split Char.isWhitespace).toList.map (·.toString)).filter (fun w => !w.isEmpty)

#eval wordsOf "  the cat\tsat\n"  -- ["the", "cat", "sat"]

structure Counts where
  lines : Nat
  words : Nat
  chars : Nat
  deriving BEq, Repr

/-- The counts of a text: lines are the number of `'\n'` characters, words are
as in `wordsOf`, and chars is the number of characters. -/
def Counts.of (text : String) : Counts :=
  sorry

-- Tests (`lake exe check` runs them for you):
-- #guard Counts.of "one two\nthree\n" == { lines := 2, words := 3, chars := 14 }
-- #guard Counts.of "" == { lines := 0, words := 0, chars := 0 }
-- #guard Counts.of "no newline" == { lines := 0, words := 2, chars := 10 }

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

/-! The last piece of `wc` has to go through all its inputs and remember
whether any of them was missing. A `for` loop goes through them, but names in
Lean never change, so how can the loop remember anything? A `do` block allows
one exception: a *mutable variable*, declared with `let mut x := v`, can be
given a new value later with `x := ...`. Lean turns this into ordinary
definitions behind the scenes, so the rest of the language stays as before. -/

def countLong (words : List String) : Nat := Id.run do
  let mut count := 0
  for w in words do
    if w.length > 5 then
      count := count + 1
  return count

#eval countLong ["a", "lengthy", "list", "of", "examples"]  -- 2

/-! (`Id.run do` lets an ordinary function, which is not an `IO` action, use a
`do` block; chapter 4 explains it.) -/

/-- The `main` of `wc`: for each input in `args`, prints
`<lines> <words> <chars> <name>`. A missing file prints
`wc: <name>: no such file` to the standard error, and the other inputs are
still counted. Returns `1` if any input was missing, and `0` otherwise.

Hint: use `for` with a mutable variable, `let mut code := 0`, or a recursive
helper. -/
def wc (args : List String) : IO UInt32 := do
  sorry

-- Tests (`lake exe check` runs them for you):
-- #eval do expect (← run "one two\nthree\n" (wc ["-"])) ("2 3 14 -\n", 0)
-- #eval do expect (← run "a b\n" (wc ["missing.txt", "-"])) ("wc: missing.txt: no such file\n1 2 4 -\n", 1)
-- #eval do
--   IO.FS.withTempFile fun handle path => do
--     handle.putStr "a file\nwith three lines\nhere\n"
--     handle.flush
--     expect (← run "" (wc [path.toString])) (s!"3 6 29 {path}\n", 0)

-- Try it, once `wc` is solved: count this project's README.
-- #eval wc ["README.md"]

/-! ## 5. Additional conveniences

Along the way, this module has already shown most of what makes `do` blocks
pleasant to write: `return`, an `if` without `else`, `for` loops and mutable
variables. This section looks more closely at the nested action `(← e)` from
section 4, and adds one more piece of notation.

`(← e)` is only a shorthand. Lean turns it into its own `let x ← e` line, just
before the line where it appears, and then uses `x` in its place. That is why
the action runs *before* the rest of its line, even if it is written at the
end, and why `(← e)` can only be used inside a `do` block.

The new piece is `unless cond do ...`, which runs its indented lines only when
the condition is false. It is the same as `if !cond then ...`, but reads more
naturally when the lines are the exception.

Read more: https://lean-lang.org/functional_programming_in_lean/Hello___-World___/Additional-Conveniences/
-/

/-! `shoutBack` reads a line with a nested action, and only prints when the
line isn't empty. -/

def shoutBack : IO Unit := do
  let line := (← (← IO.getStdin).getLine).trimAscii
  unless line.isEmpty do
    IO.println line.copy.toUpper

#eval outputOf "quiet please\n" shoutBack  -- "QUIET PLEASE\n"

/-- Reads the standard input and prints the lines that contain `word` as one
of their words (see `wordsOf`), each with its line number (counting from 1):
`<number>: <line>`. The lines are printed without their newline. -/
def findWord (word : String) : IO Unit := do
  sorry

-- Tests (`lake exe check` runs them for you):
-- #eval do
--   expect (← outputOf "the cat\nthe dog\na cat and a dog\ncatalog\n" (findWord "cat"))
--     "1: the cat\n3: a cat and a dog\n"
-- #eval do expect (← outputOf "nothing here\n" (findWord "cat")) ""

/-! ## Final project of the module: a guessing game

The computer picks a secret number and the player guesses it. After each guess,
the game says whether the secret is higher or lower. -/

/-- The game's answer to a guess. -/
def hint (secret guess : Nat) : String :=
  sorry

-- Tests (`lake exe check` runs them for you):
-- #guard hint 50 20 = "Higher!"
-- #guard hint 50 80 = "Lower!"
-- #guard hint 50 50 = "Correct!"

/-- Plays the game: asks `Your guess?`, reads a line and prints its `hint`,
until the guess is right. Then it prints `You needed <n> guesses.` Lines that
are not numbers print `That is not a number.` and don't count as guesses. If
the input ends first, it prints `Bye!`.

`guesses` is how many guesses were made before this one. -/
partial def play (secret : Nat) (guesses : Nat := 0) : IO Unit := do
  sorry

-- Tests (`lake exe check` runs them for you):
-- #eval do
--   expect (← outputOf "50\n25\n37\n" (play 37))
--     ("Your guess?\nLower!\nYour guess?\nHigher!\nYour guess?\nCorrect!\n" ++
--      "You needed 3 guesses.\n")
-- #eval do
--   expect (← outputOf "abc\n7\n" (play 7))
--     "Your guess?\nThat is not a number.\nYour guess?\nCorrect!\nYou needed 1 guesses.\n"
-- #eval do expect (← outputOf "1\n" (play 7)) "Your guess?\nHigher!\nYour guess?\nBye!\n"

end HelloWorld

/-- Run with `lake env lean --run Exercises/HelloWorld.lean` to play. -/
def main : IO Unit := do
  IO.println "I'm thinking of a number between 1 and 100."
  HelloWorld.play (← IO.rand 1 100)
