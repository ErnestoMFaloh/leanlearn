import type { Metadata } from "next";
import { Prose } from "@/components/Prose";
import { resources } from "@/lib/content";
import { renderMarkdown } from "@/lib/render";

export const metadata: Metadata = { title: "Resources" };

export default async function Resources() {
  return (
    <article className="page">
      <h1>Resources</h1>
      <Prose html={await renderMarkdown(resources())} />
    </article>
  );
}
