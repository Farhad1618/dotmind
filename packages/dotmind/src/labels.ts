import { humanizeTool } from "./tools.ts";
import type { Activity, Phase, ToolKind } from "./types.ts";

export type LabelMap = Record<Exclude<Phase, "tool">, string> & Record<`tool:${ToolKind}`, string>;

export const DEFAULT_LABELS: LabelMap = {
  idle: "Ready",
  thinking: "Thinking",
  writing: "Writing",
  waiting: "Waiting for you",
  error: "Something went wrong",
  done: "Done",
  "tool:search": "Searching",
  "tool:browse": "Browsing",
  "tool:code": "Running code",
  "tool:file": "Reading files",
  "tool:database": "Querying data",
  "tool:compute": "Calculating",
  "tool:generic": "Using a tool",
};

export function labelFor(activity: Activity, labels: Partial<LabelMap> = {}): string {
  if (activity.label) return activity.label;
  const map = { ...DEFAULT_LABELS, ...labels };
  if (activity.phase === "tool") {
    const kind = activity.kind ?? "generic";
    if (kind === "generic" && activity.tool && !labels["tool:generic"]) return `Using ${humanizeTool(activity.tool)}`;
    return map[`tool:${kind}`];
  }
  return map[activity.phase];
}
