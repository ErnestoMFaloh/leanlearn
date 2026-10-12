// Markdown and Lean to HTML, at build time. Code is highlighted with Shiki in
// a light and a dark theme; globals.css picks one with prefers-color-scheme.

import { createHighlighter, type Highlighter } from "shiki";
import rehypeShikiFromHighlighter from "@shikijs/rehype/core";
import rehypeSlug from "rehype-slug";
import rehypeStringify from "rehype-stringify";
import remarkGfm from "remark-gfm";
import remarkParse from "remark-parse";
import remarkRehype from "remark-rehype";
import { unified } from "unified";
import { BLOB_URL, modules } from "./content";

const themes = { light: "github-light", dark: "github-dark" } as const;

let highlighter: Promise<Highlighter> | null = null;

function getHighlighter(): Promise<Highlighter> {
  highlighter ??= createHighlighter({
    themes: Object.values(themes),
    langs: ["lean4", "bash"],
  });
  return highlighter;
}

export async function highlightLean(code: string): Promise<string> {
  return (await getHighlighter()).codeToHtml(code, {
    lang: "lean4",
    themes,
    defaultColor: false,
  });
}

const basePath = process.env.NEXT_PUBLIC_BASE_PATH ?? "";

/**
 * Where a link in GUIDE.md or README.md should point on the site: pages for
 * the files the site renders, GitHub for the rest of the repository.
 */
function rewriteHref(href: string): string {
  if (/^[a-z]+:|^#/.test(href)) return href;
  if (href.startsWith("README.md#getting-started")) return `${basePath}/start/`;
  const module = modules().find((m) => href.endsWith(`/${m.file}.lean`) && href.startsWith("Exercises/"));
  if (module) return `${basePath}/modules/${module.slug}/`;
  return `${BLOB_URL}/${href}`;
}

type Node = { type: string; url?: string; children?: Node[] };

function remarkRewriteLinks() {
  const visit = (node: Node) => {
    if (node.type === "link" && node.url) node.url = rewriteHref(node.url);
    node.children?.forEach(visit);
  };
  return visit;
}

/** Opens links that leave the site in a new tab. */
function rehypeExternalLinks() {
  type El = { type: string; tagName?: string; properties?: Record<string, unknown>; children?: El[] };
  const visit = (node: El) => {
    const href = node.properties?.href;
    if (node.tagName === "a" && typeof href === "string" && /^https?:/.test(href)) {
      node.properties!.target = "_blank";
      node.properties!.rel = "noreferrer";
    }
    node.children?.forEach(visit);
  };
  return visit;
}

export async function renderMarkdown(markdown: string): Promise<string> {
  const file = await unified()
    .use(remarkParse)
    .use(remarkGfm)
    .use(remarkRewriteLinks)
    .use(remarkRehype)
    .use(rehypeSlug)
    .use(rehypeExternalLinks)
    .use(rehypeShikiFromHighlighter, await getHighlighter(), {
      themes,
      defaultColor: false,
      defaultLanguage: "text",
      fallbackLanguage: "text",
    })
    .use(rehypeStringify)
    .process(markdown);
  return String(file);
}
