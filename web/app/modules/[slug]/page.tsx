import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import { CopyButton } from "@/components/CopyButton";
import { ExerciseCard } from "@/components/ExerciseCard";
import { ModuleProgress } from "@/components/ModuleProgress";
import { Prose } from "@/components/Prose";
import { BLOB_URL, modules, playgroundUrl } from "@/lib/content";
import { highlightLean, renderMarkdown } from "@/lib/render";

const slugify = (title: string) =>
  title
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-|-$/g, "");

type Params = { params: Promise<{ slug: string }> };

export function generateStaticParams() {
  return modules().map((m) => ({ slug: m.slug }));
}

export const dynamicParams = false;

export async function generateMetadata({ params }: Params): Promise<Metadata> {
  const { slug } = await params;
  const module = modules().find((m) => m.slug === slug);
  return { title: module ? `Module ${module.number}: ${module.title}` : "Module" };
}

export default async function ModulePage({ params }: Params) {
  const { slug } = await params;
  const all = modules();
  const index = all.findIndex((m) => m.slug === slug);
  if (index < 0) notFound();
  const m = all[index];
  const prev = all[index - 1];
  const next = all[index + 1];

  const exercises = await Promise.all(
    m.exercises.map(async (e) => ({
      ...e,
      statementHtml: await highlightLean(e.statement),
      solutionHtml: await highlightLean(e.solution),
    })),
  );

  const lessons = await Promise.all(
    m.lessons.map(async (l) => ({
      ...l,
      html: l.text ? await renderMarkdown(l.text) : "",
      items: await Promise.all(
        l.items.map(async (item) =>
          item.kind === "code" ? { ...item, html: await highlightLean(item.code) } : item,
        ),
      ),
    })),
  );

  return (
    <article className="page module-page">
      <p className="eyebrow">Module {m.number}</p>
      <h1>{m.title}</h1>

      {m.goals.length > 0 && (
        <ul className="goals">
          {m.goals.map((g) => (
            <li key={g}>{g.replace(/`/g, "")}</li>
          ))}
        </ul>
      )}

      <div className="module-actions">
        <a className="button primary" href={playgroundUrl(m.exercisesSource)} target="_blank" rel="noreferrer">
          Open in the Lean playground
        </a>
        <CopyButton text={m.exercisesSource} label="Copy the file" />
        <a className="button" href={`${BLOB_URL}/Exercises/${m.file}.lean`} target="_blank" rel="noreferrer">
          View on GitHub
        </a>
      </div>
      <p className="muted small">
        The playground runs the latest Lean in your browser. Locally, the file is{" "}
        <code>Exercises/{m.file}.lean</code> and you check it with <code>lake exe check {m.file}</code>.
      </p>

      <h2>Guide</h2>
      <Prose html={await renderMarkdown(m.guide)} />

      <div className="exercises-heading">
        <h2>Lessons and exercises</h2>
        <ModuleProgress module={m.file} names={m.exercises.map((e) => e.name)} />
      </div>
      <p className="muted">
        Each lesson explains what its exercises need. Solve them in the file, not here: the playground or VS
        Code shows the goal at each step. Tick an exercise once <code>lake exe check</code> marks it ✅ (or it
        compiles without <code>sorry</code> in the playground).
      </p>
      {lessons.map((lesson) => (
        <section key={lesson.title} className="lesson">
          <h2 id={slugify(lesson.title)}>{lesson.title}</h2>
          {lesson.html && <Prose html={lesson.html} />}
          {lesson.readMore && (
            <p className="read-more">
              <a href={lesson.readMore} target="_blank" rel="noreferrer">
                Read more in the book →
              </a>
            </p>
          )}
          {lesson.items.map((item, i) => {
            if (item.kind === "code") {
              return <div key={i} className="code" dangerouslySetInnerHTML={{ __html: item.html }} />;
            }
            const e = exercises.find((x) => x.name === item.name)!;
            return (
              <ExerciseCard
                key={e.name}
                module={m.file}
                index={exercises.indexOf(e) + 1}
                name={e.name}
                statementHtml={e.statementHtml}
                solutionHtml={e.solutionHtml}
                tests={e.tests}
              />
            );
          })}
        </section>
      ))}

      <nav className="pager">
        {prev ? (
          <Link href={`/modules/${prev.slug}/`}>← Module {prev.number}: {prev.title}</Link>
        ) : (
          <Link href="/start/">← Get started</Link>
        )}
        {next ? (
          <Link href={`/modules/${next.slug}/`}>Module {next.number}: {next.title} →</Link>
        ) : (
          <Link href="/projects/">Project ideas →</Link>
        )}
      </nav>
    </article>
  );
}
