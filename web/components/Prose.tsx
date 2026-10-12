/** HTML rendered at build time from the repository's own Markdown. */
export function Prose({ html }: { html: string }) {
  return <div className="prose" dangerouslySetInnerHTML={{ __html: html }} />;
}
