import type { Metadata } from "next";
import { Prose } from "@/components/Prose";
import { gettingStarted, modules, playgroundUrl } from "@/lib/content";
import { renderMarkdown } from "@/lib/render";

export const metadata: Metadata = { title: "Get started" };

export default async function Start() {
  const { install, workflow } = gettingStarted();
  const first = modules()[0];
  return (
    <article className="page">
      <h1>Get started</h1>

      <div className="callout">
        <strong>Just want to try it?</strong> Open module 1 in the{" "}
        <a href={playgroundUrl(first.exercisesSource)} target="_blank" rel="noreferrer">
          Lean playground
        </a>{" "}
        and solve it in your browser, no installation needed. Install Lean locally when you want
        <code>lake exe check</code> and the full editor experience.
      </div>

      <h2>Install</h2>
      <Prose html={await renderMarkdown(install)} />

      <h2>How to work</h2>
      <Prose html={await renderMarkdown(workflow)} />
    </article>
  );
}
