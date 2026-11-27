import type { ToolKind } from "./types.ts";

const RULES: ReadonlyArray<readonly [ToolKind, readonly string[]]> = [
  ["search", ["search", "find", "lookup", "grep", "retriev", "rag", "google", "bing", "glob"]],
  ["database", ["sql", "db", "database", "table", "query", "clickhouse", "postgres", "bigquery", "snowflake", "mongo", "redis"]],
  ["browse", ["browse", "browser", "navigate", "fetch", "url", "scrape", "crawl", "http", "page", "click", "screenshot", "computer", "web"]],
  ["code", ["code", "exec", "run", "python", "bash", "shell", "terminal", "sandbox", "eval", "interpreter", "script", "notebook"]],
  ["file", ["file", "read", "write", "edit", "fs", "doc", "pdf", "upload", "download", "save", "replace", "editor", "ls", "dir"]],
  ["compute", ["calc", "math", "compute", "sum", "stat", "analy", "chart", "plot", "forecast"]],
];

export function toolTokens(name: string): string[] {
  return name
    .replace(/([a-z0-9])([A-Z])/g, "$1_$2")
    .toLowerCase()
    .split(/[^a-z0-9]+/)
    .filter(Boolean);
}

export function classifyTool(name: string | undefined, overrides?: Readonly<Record<string, ToolKind>>): ToolKind {
  if (!name) return "generic";
  const own = overrides?.[name];
  if (own) return own;
  const tokens = toolTokens(name);
  for (const [kind, words] of RULES) {
    if (tokens.some((tok) => words.some((w) => tok === w || (w.length > 3 && tok.startsWith(w))))) return kind;
  }
  return "generic";
}

export function humanizeTool(name: string): string {
  const words = toolTokens(name);
  return words.join(" ");
}
