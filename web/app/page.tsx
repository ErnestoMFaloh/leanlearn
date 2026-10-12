import Link from "next/link";
import { ModuleProgress } from "@/components/ModuleProgress";
import { modules } from "@/lib/content";
import { highlightLean } from "@/lib/render";

const checkOutput = `$ lake exe check Logic
Logic (Exercises/Logic.lean)
  ✅ ex1
  ✅ ex2
  ❌ ex3: error at line 76: Type mismatch …
  ⏳ ex4: still has \`sorry\`
  ⏳ ex5: still has \`sorry\`
  2/5 solved`;

export default async function Home() {
  const example = await highlightLean(`theorem and_swap (p q : Prop) : p ∧ q → q ∧ p := by
  sorry  -- your turn: replace this with a proof`);

  return (
    <>
      <section className="hero">
        <div>
          <p className="eyebrow">A hands-on workbook</p>
          <h1>Learn Lean 4 by solving exercises</h1>
          <p className="lead">
            Lean is a functional programming language that is also a proof assistant. Each module
            has worked examples followed by exercises marked with <code>sorry</code>. Replace every{" "}
            <code>sorry</code> with a definition or a proof, and Lean checks your work.
          </p>
          <div className="hero-actions">
            <Link href="/start/" className="button primary">
              Get started
            </Link>
            <Link href={`/modules/${modules()[0].slug}/`} className="button">
              Jump to module 1
            </Link>
          </div>
        </div>
        <div className="code hero-code" dangerouslySetInnerHTML={{ __html: example }} />
      </section>

      <section id="modules">
        <h2>Modules</h2>
        <p className="muted">Go in order, and move on once a module compiles without any sorry.</p>
        <div className="module-grid">
          {modules().map((m) => (
            <Link key={m.slug} href={`/modules/${m.slug}/`} className="card module-card">
              <span className="module-number">Module {m.number}</span>
              <h3>{m.title}</h3>
              <ul>
                {m.goals.slice(0, 3).map((g) => (
                  <li key={g}>{g.replace(/`/g, "")}</li>
                ))}
              </ul>
              <ModuleProgress module={m.file} names={m.exercises.map((e) => e.name)} />
            </Link>
          ))}
        </div>
      </section>

      <section className="how">
        <h2>How it works</h2>
        <ol className="steps">
          <li>
            <h3>Read</h3>
            <p>Each module tells you which book chapters to read and the key ideas to look for.</p>
          </li>
          <li>
            <h3>Solve</h3>
            <p>
              Work in <code>Exercises/</code> in VS Code, or straight in your browser with the Lean
              playground.
            </p>
          </li>
          <li>
            <h3>Check</h3>
            <p>
              <code>lake exe check</code> tells you which exercises are solved. It never compares your
              answer with the solution as text: any correct proof counts.
            </p>
          </li>
        </ol>
        <pre className="terminal">{checkOutput}</pre>
      </section>
    </>
  );
}
