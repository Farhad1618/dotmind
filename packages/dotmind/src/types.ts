export type Phase = "idle" | "thinking" | "tool" | "writing" | "waiting" | "error" | "done";

export type ToolKind = "search" | "browse" | "code" | "file" | "database" | "compute" | "generic";

export type RGB = readonly [number, number, number];

export interface Activity {
  phase: Phase;
  tool?: string;
  kind?: ToolKind;
  label?: string;
  progress?: number;
}

export type AgentEvent =
  | { type: "start" }
  | { type: "thinking"; chars?: number }
  | { type: "tool"; name: string; id?: string }
  | { type: "tool-input"; chars?: number }
  | { type: "tool-result"; id?: string; error?: boolean }
  | { type: "text"; chars?: number }
  | { type: "approval"; name?: string; id?: string }
  | { type: "error"; message?: string }
  | { type: "finish"; pendingTools?: boolean };

export interface PatternContext {
  energy: number;
  progress: number;
}

export type Pattern = (t: number, out: Float32Array, ctx: PatternContext) => void;

export type SceneName =
  | "breathe"
  | "comet"
  | "radar"
  | "globe"
  | "code"
  | "pages"
  | "stack"
  | "prism"
  | "circuit"
  | "type"
  | "halo"
  | "cross"
  | "check"
  | "ember"
  | "orbit"
  | "serpent"
  | "pulse";
