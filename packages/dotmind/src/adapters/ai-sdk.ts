import { classifyTool } from "../tools.ts";
import type { Activity, ToolKind } from "../types.ts";

export type ChatStatus = "submitted" | "streaming" | "ready" | "error";

export interface UIMessagePart {
  type: string;
  text?: string;
  state?: string;
  toolName?: string;
  input?: unknown;
}

export interface UIMessageLike {
  role: string;
  parts?: UIMessagePart[];
}

const SKIP = new Set(["step-start", "source-url", "source-document", "file"]);

function isTool(part: UIMessagePart): boolean {
  return part.type === "dynamic-tool" || part.type.startsWith("tool-");
}

function toolNameOf(part: UIMessagePart): string {
  return part.toolName ?? part.type.slice("tool-".length);
}

function sizeOf(part: UIMessagePart): number {
  if (typeof part.text === "string") return part.text.length;
  if (part.input !== undefined) {
    try {
      return JSON.stringify(part.input)?.length ?? 0;
    } catch {
      return 0;
    }
  }
  return 0;
}

export function aiSdkActivity(
  messages: readonly UIMessageLike[],
  status: ChatStatus,
  options: { tools?: Readonly<Record<string, ToolKind>> } = {},
): Activity {
  if (status === "error") return { phase: "error" };
  const last = messages[messages.length - 1];
  const assistant = last?.role === "assistant" ? last : undefined;
  const parts = assistant?.parts ?? [];
  const progress = parts.reduce((n, p) => n + sizeOf(p), 0);
  const live = [...parts].reverse().find((p) => !SKIP.has(p.type) && !p.type.startsWith("data-"));
  const tool = (part: UIMessagePart, phase: Activity["phase"]): Activity => {
    const name = toolNameOf(part);
    return { phase, tool: name, kind: classifyTool(name, options.tools), progress };
  };

  if (status === "submitted") return { phase: "thinking", progress };

  if (live && isTool(live)) {
    if (live.state === "approval-requested") return tool(live, "waiting");
    if (live.state === "input-streaming" || live.state === "input-available") return tool(live, "tool");
  }

  if (status === "ready") return assistant ? { phase: "done", progress } : { phase: "idle" };

  if (!live) return { phase: "thinking", progress };
  if (live.type === "reasoning") return { phase: "thinking", progress };
  if (live.type === "text") return { phase: "writing", progress };
  return { phase: "thinking", progress };
}
