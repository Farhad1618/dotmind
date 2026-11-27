import { classifyTool } from "./tools.ts";
import type { Activity, AgentEvent, ToolKind } from "./types.ts";

export interface TrackerOptions {
  tools?: Readonly<Record<string, ToolKind>>;
}

export type ActivityListener = (activity: Activity) => void;

export class ActivityTracker {
  private state: Activity = { phase: "idle", progress: 0 };
  private readonly listeners = new Set<ActivityListener>();
  private readonly openTools = new Map<string, string>();
  private readonly tools?: Readonly<Record<string, ToolKind>>;

  constructor(options: TrackerOptions = {}) {
    this.tools = options.tools;
  }

  get activity(): Activity {
    return this.state;
  }

  subscribe(listener: ActivityListener): () => void {
    this.listeners.add(listener);
    listener(this.state);
    return () => {
      this.listeners.delete(listener);
    };
  }

  reset(): void {
    this.openTools.clear();
    this.set({ phase: "idle", progress: 0 });
  }

  push(event: AgentEvent): void {
    const progress = this.state.progress ?? 0;
    switch (event.type) {
      case "start":
        this.openTools.clear();
        return this.set({ phase: "thinking", progress });
      case "thinking":
        return this.set({ phase: "thinking", progress: progress + (event.chars ?? 0) });
      case "tool":
        if (event.id) this.openTools.set(event.id, event.name);
        return this.set({ phase: "tool", tool: event.name, kind: classifyTool(event.name, this.tools), progress });
      case "tool-input":
        return this.set({ ...this.state, progress: progress + (event.chars ?? 0) });
      case "tool-result":
        if (event.id) this.openTools.delete(event.id);
        return this.set({ phase: "thinking", progress });
      case "text":
        return this.set({ phase: "writing", progress: progress + (event.chars ?? 0) });
      case "approval":
        return this.set({ phase: "waiting", tool: event.name, kind: classifyTool(event.name, this.tools), progress });
      case "error":
        return this.set({ phase: "error", label: undefined, progress });
      case "finish": {
        if (!event.pendingTools) return this.set({ phase: "done", progress });
        const last = [...this.openTools.values()].pop() ?? this.state.tool;
        return this.set({ phase: "tool", tool: last, kind: classifyTool(last, this.tools), progress });
      }
    }
  }

  pushAll(events: Iterable<AgentEvent>): void {
    for (const e of events) this.push(e);
  }

  private set(next: Activity): void {
    const prev = this.state;
    if (prev.phase === next.phase && prev.tool === next.tool && prev.kind === next.kind && prev.progress === next.progress) return;
    this.state = next;
    for (const l of this.listeners) l(next);
  }
}
