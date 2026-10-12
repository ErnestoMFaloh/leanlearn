"use client";

import { useState } from "react";
import { exerciseId, setSolved, useSolved } from "@/lib/progress";

type Props = {
  module: string;
  index: number;
  name: string;
  statementHtml: string;
  solutionHtml: string;
  tests: string[];
};

export function ExerciseCard({ module, index, name, statementHtml, solutionHtml, tests }: Props) {
  const id = exerciseId(module, name);
  const solved = useSolved().includes(id);
  const [showSolution, setShowSolution] = useState(false);

  return (
    <article className={`exercise${solved ? " solved" : ""}`} id={name}>
      <header className="exercise-header">
        <h3>
          <span className="exercise-index">{index}</span>
          <code>{name}</code>
        </h3>
        <label className="solved-toggle">
          <input type="checkbox" checked={solved} onChange={(e) => setSolved(id, e.target.checked)} />
          Solved
        </label>
      </header>

      <div className="code" dangerouslySetInnerHTML={{ __html: statementHtml }} />

      {tests.length > 0 && (
        <p className="exercise-note">
          {tests.length} {tests.length === 1 ? "test checks" : "tests check"} your definition when you run{" "}
          <code>lake exe check {module}</code>.
        </p>
      )}

      <div className="exercise-actions">
        <button type="button" className="button" onClick={() => setShowSolution((s) => !s)}>
          {showSolution ? "Hide solution" : "Show solution"}
        </button>
      </div>

      {showSolution && (
        <div className="solution">
          <p className="exercise-note">
            One possible solution. Yours may be different and just as correct.
          </p>
          <div className="code" dangerouslySetInnerHTML={{ __html: solutionHtml }} />
        </div>
      )}
    </article>
  );
}
