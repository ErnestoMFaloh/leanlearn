# leanlearn website

The study guide as a website: a Next.js + TypeScript static site, deployed to
GitHub Pages by `.github/workflows/pages.yml`.

It has no content of its own. At build time it reads `GUIDE.md`, `README.md`,
`Exercises/` and `Solutions/` from the repository root (see `lib/content.ts`),
so editing those files is all it takes to update the site. An exercise is a
declaration of `Solutions/<Module>.lean` with a `-- SOLUTION` marker, the same
rule `lake exe check` uses.

```bash
cd web
npm install
npm run dev        # http://localhost:3000
npm run build      # static site in out/
```

Progress ("Solved" ticks) is stored in the browser's `localStorage`.
