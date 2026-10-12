"use client";

import { exerciseId, useSolved } from "@/lib/progress";

/** "2/5 solved" with a bar, from the exercises the learner has ticked. */
export function ModuleProgress({ module, names }: { module: string; names: string[] }) {
  const solved = useSolved();
  const done = names.filter((n) => solved.includes(exerciseId(module, n))).length;
  return (
    <div className="progress" aria-label={`${done} of ${names.length} exercises solved`}>
      <div className="progress-bar">
        <div className="progress-fill" style={{ width: `${(100 * done) / names.length}%` }} />
      </div>
      <span className="progress-label">
        {done}/{names.length} solved
      </span>
    </div>
  );
}
