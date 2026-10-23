// Reads the workbook (GUIDE.md, README.md, Exercises/, Solutions/) at build
// time. The site has no content of its own: everything comes from the repo.

import fs from "node:fs";
import path from "node:path";

const ROOT = path.join(process.cwd(), "..");

export const REPO_URL = "https://github.com/ErnestoMFaloh/leanlearn";
export const BLOB_URL = `${REPO_URL}/blob/main`;

function read(rel: string): string {
  return fs.readFileSync(path.join(ROOT, rel), "utf8");
}

// ---------------------------------------------------------------------------
// Markdown sections

export type Section = { title: string; body: string };

/** Splits a Markdown file into its `## ` sections, dropping `---` rules. */
function sections(markdown: string): Section[] {
  return markdown
    .split(/^## /m)
    .slice(1)
    .map((chunk) => {
      const newline = chunk.indexOf("\n");
      const title = chunk.slice(0, newline).trim();
      const body = chunk
        .slice(newline + 1)
        .replace(/^---\s*$/gm, "")
        .trim();
      return { title, body };
    });
}

function section(list: Section[], title: string): Section {
  const found = list.find((s) => s.title.startsWith(title));
  if (!found) throw new Error(`Section "${title}" not found`);
  return found;
}

const guide = () => sections(read("GUIDE.md"));

export function gettingStarted(): { install: string; workflow: string } {
  const install = section(sections(read("README.md")), "Getting started").body.replace(
    "<repository-url>",
    `${REPO_URL}.git`,
  );
  return { install, workflow: section(guide(), "0. Before you start").body };
}

export const projectIdeas = () => section(guide(), "After the modules").body;
export const resources = () => section(guide(), "Resources").body;

// ---------------------------------------------------------------------------
// Lean files

export type Exercise = {
  name: string;
  /** The declaration as the learner sees it, with `sorry`. */
  statement: string;
  /** The same declaration solved, without the markers. */
  solution: string;
  /** The test commands (`#guard`, `#eval`) that `lake exe check` runs for it. */
  tests: string[];
};

/** A `/-! ## ... -/` section of a module file: an explanation, examples and exercises. */
export type Lesson = {
  title: string;
  /** The explanation, as Markdown, without its "Read more:" line. */
  text: string;
  /** The book section the explanation links to. */
  readMore?: string;
  /** Explanations, examples and exercises, in the order of the file. */
  items: LessonItem[];
};

/** A piece of a lesson: an explanation, example code, or an exercise (by name). */
export type LessonItem =
  | { kind: "text"; text: string }
  | { kind: "code"; code: string }
  | { kind: "exercise"; name: string };

export type Module = {
  slug: string;
  file: string;
  number: number;
  title: string;
  goals: string[];
  /** The module's section of GUIDE.md, without the `**File:**` line. */
  guide: string;
  exercisesSource: string;
  exercises: Exercise[];
  lessons: Lesson[];
};

const DECL =
  /^(?:@\[[^\]]*\]\s*)?(?:(?:private|protected|noncomputable|partial)\s+)*(?:theorem|lemma|def|abbrev|instance)\s+([^\s:({[]+)/;
const MARKER = /^\s*-- (?:END )?(?:SOLUTION|TESTS)(?:\b.*)?$/;
const BEGIN_SOLUTION = /^\s*-- SOLUTION(?::.*)?$/;
const BEGIN_TESTS = /^\s*-- TESTS$/;
const END_TESTS = /^\s*-- END TESTS$/;

/** Moves `start` back over a `/-- ... -/` docstring right above it. */
function withDocstring(lines: string[], start: number): number {
  if (start === 0 || !lines[start - 1].trimEnd().endsWith("-/")) return start;
  for (let i = start - 1; i >= 0; i--) {
    if (lines[i].startsWith("/--")) return i;
  }
  return start;
}

/** The lines of the declaration named `name`, with its docstring. */
function declaration(lines: string[], name: string): string {
  const at = lines.findIndex((line) => DECL.exec(line)?.[1] === name);
  if (at < 0) throw new Error(`Declaration ${name} not found`);
  let end = at;
  while (end < lines.length && lines[end].trim() !== "") end++;
  return lines.slice(withDocstring(lines, at), end).join("\n");
}

/**
 * The exercises of a solution file: the declarations that contain a
 * `-- SOLUTION` marker, the same rule `lake exe check` uses.
 */
function parseExercises(solutionSource: string, exerciseSource: string): Exercise[] {
  const lines = solutionSource.split("\n");
  const exerciseLines = exerciseSource.split("\n");
  const exercises: Exercise[] = [];
  let current: string | null = null;
  let inTests = false;

  for (const line of lines) {
    const decl = DECL.exec(line);
    if (decl) current = decl[1];

    if (BEGIN_TESTS.test(line)) inTests = true;
    else if (END_TESTS.test(line)) inTests = false;
    else if (inTests && /^#/.test(line)) exercises.at(-1)?.tests.push(line.trim());

    if (BEGIN_SOLUTION.test(line) && current && exercises.at(-1)?.name !== current) {
      exercises.push({
        name: current,
        statement: declaration(exerciseLines, current),
        solution: declaration(
          lines.filter((l) => !MARKER.test(l)),
          current,
        ),
        tests: [],
      });
    }
  }
  return exercises;
}

const LESSON = /^\/-! ## (.+?)(?:\s*-\/)?$/;
const READ_MORE = /^Read more:\s*(\S+)\s*$/m;
const TESTS_COMMENT = /^-- Tests \(`lake exe check`/;

/**
 * Splits an exercise file into lessons, one per `/-! ## ... -/` block. The
 * code before the first one (the module header) is left out.
 */
function parseLessons(source: string, names: string[]): Lesson[] {
  const lines = source.split("\n");
  const starts = lines.flatMap((line, i) => (LESSON.test(line) ? [i] : []));
  return starts.map((start, n) => {
    const end = starts[n + 1] ?? lines.length;
    const title = LESSON.exec(lines[start])![1];
    let docEnd = start;
    while (docEnd < end && !lines[docEnd].trimEnd().endsWith("-/")) docEnd++;
    const docLines =
      docEnd === start ? [] : [...lines.slice(start + 1, docEnd), lines[docEnd].replace(/-\/\s*$/, "")];
    let text = docLines.join("\n");
    const readMore = READ_MORE.exec(text)?.[1];
    text = text.replace(READ_MORE, "").trim();

    // The rest of the section, cut at each explanation and exercise. Tests and
    // namespace lines are left out.
    const body = lines.slice(docEnd + 1, end);
    const items: LessonItem[] = [];
    let pending: string[] = [];
    const flush = () => {
      const code = pending.join("\n").replace(/\n{3,}/g, "\n\n").trim();
      if (code) items.push({ kind: "code", code });
      pending = [];
    };
    for (let i = 0; i < body.length; i++) {
      const decl = DECL.exec(body[i]);
      if (decl && names.includes(decl[1])) {
        // Its docstring was already collected as code: take it back.
        pending.splice(pending.length - (i - withDocstring(body, i)));
        flush();
        items.push({ kind: "exercise", name: decl[1] });
        while (i + 1 < body.length && body[i + 1].trim() !== "") i++;
      } else if (body[i].startsWith("/-!")) {
        // A `/-! ... -/` block inside the lesson is more explanation.
        flush();
        const text: string[] = [];
        for (; i < body.length; i++) {
          text.push(body[i]);
          if (body[i].trimEnd().endsWith("-/")) break;
        }
        const markdown = text.join("\n").replace(/^\/-!\s?/, "").replace(/\s*-\/\s*$/, "").trim();
        if (markdown) items.push({ kind: "text", text: markdown });
      } else if (TESTS_COMMENT.test(body[i])) {
        while (i + 1 < body.length && body[i + 1].startsWith("--")) i++;
      } else if (!/^(namespace|end) \S+$/.test(body[i])) {
        pending.push(body[i]);
      }
    }
    flush();
    return { title, text, readMore, items };
  });
}

/** The bullet points under `Goals:` in the file's opening `/-! ... -/` block. */
function parseGoals(source: string): string[] {
  const doc = /\/-!([\s\S]*?)-\//.exec(source)?.[1] ?? "";
  const goals: string[] = [];
  for (const line of doc.split("\n")) {
    if (line.startsWith("* ")) goals.push(line.slice(2).trim());
    else if (line.startsWith("  ") && goals.length && line.trim()) {
      goals[goals.length - 1] += " " + line.trim();
    } else if (goals.length) break;
  }
  return goals;
}

let cache: Module[] | null = null;

export function modules(): Module[] {
  if (cache) return cache;
  cache = guide()
    .map((s) => {
      const heading = /^Module (\d+) — (.+)$/.exec(s.title);
      const fileLine = /^\*\*File:\*\* `Exercises\/(\w+)\.lean`.*$/m.exec(s.body);
      if (!heading || !fileLine) return null;
      const file = fileLine[1];
      const exercisesSource = read(`Exercises/${file}.lean`);
      const exercises = parseExercises(read(`Solutions/${file}.lean`), exercisesSource);
      return {
        slug: file.toLowerCase(),
        file,
        number: Number(heading[1]),
        title: heading[2],
        goals: parseGoals(exercisesSource),
        guide: s.body.replace(fileLine[0], "").trim(),
        exercisesSource,
        exercises,
        lessons: parseLessons(exercisesSource, exercises.map((e) => e.name)),
      };
    })
    .filter((m): m is Module => m !== null)
    .sort((a, b) => a.number - b.number);
  return cache;
}

export function playgroundUrl(source: string): string {
  return `https://live.lean-lang.org/#code=${encodeURIComponent(source)}`;
}
