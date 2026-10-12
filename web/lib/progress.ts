"use client";

// Which exercises the learner has marked as solved. Kept in this browser's
// localStorage only: there are no accounts.

import { useSyncExternalStore } from "react";

const KEY = "leanlearn:solved";
const EVENT = "leanlearn:progress";

function load(): Set<string> {
  try {
    return new Set(JSON.parse(localStorage.getItem(KEY) ?? "[]") as string[]);
  } catch {
    return new Set();
  }
}

let snapshot: string[] | null = null;

function getSnapshot(): string[] {
  snapshot ??= [...load()].sort();
  return snapshot;
}

const empty: string[] = [];

function subscribe(onChange: () => void): () => void {
  const handler = () => {
    snapshot = null;
    onChange();
  };
  window.addEventListener(EVENT, handler);
  window.addEventListener("storage", handler);
  return () => {
    window.removeEventListener(EVENT, handler);
    window.removeEventListener("storage", handler);
  };
}

export function useSolved(): string[] {
  return useSyncExternalStore(subscribe, getSnapshot, () => empty);
}

export function setSolved(id: string, solved: boolean): void {
  const ids = load();
  if (solved) ids.add(id);
  else ids.delete(id);
  try {
    localStorage.setItem(KEY, JSON.stringify([...ids]));
  } catch {
    // Storage unavailable (private window): progress lasts until reload.
  }
  window.dispatchEvent(new Event(EVENT));
}

export const exerciseId = (module: string, name: string) => `${module}.${name}`;
