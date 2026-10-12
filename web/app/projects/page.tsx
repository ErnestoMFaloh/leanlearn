import type { Metadata } from "next";
import { Prose } from "@/components/Prose";
import { projectIdeas } from "@/lib/content";
import { renderMarkdown } from "@/lib/render";

export const metadata: Metadata = { title: "Project ideas" };

export default async function Projects() {
  return (
    <article className="page">
      <h1>After the modules: project ideas</h1>
      <Prose html={await renderMarkdown(projectIdeas())} />
    </article>
  );
}
