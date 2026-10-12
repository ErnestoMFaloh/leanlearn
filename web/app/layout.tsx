import type { Metadata } from "next";
import Link from "next/link";
import { REPO_URL } from "@/lib/content";
import "./globals.css";

export const metadata: Metadata = {
  title: { default: "leanlearn", template: "%s · leanlearn" },
  description: "A hands-on exercise workbook for learning Lean 4.",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body>
        <header className="site-header">
          <nav className="container nav">
            <Link href="/" className="brand">
              lean<span>learn</span>
            </Link>
            <div className="nav-links">
              <Link href="/start/">Get started</Link>
              <Link href="/#modules">Modules</Link>
              <Link href="/projects/">Projects</Link>
              <Link href="/resources/">Resources</Link>
              <a href={REPO_URL} target="_blank" rel="noreferrer">
                GitHub
              </a>
            </div>
          </nav>
        </header>
        <main className="container">{children}</main>
        <footer className="site-footer container">
          Lean code under Apache 2.0, written material under CC BY 4.0.{" "}
          <a href={REPO_URL} target="_blank" rel="noreferrer">
            Contribute on GitHub
          </a>
          .
        </footer>
      </body>
    </html>
  );
}
