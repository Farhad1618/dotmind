import { readFileSync } from "node:fs";
import { join } from "node:path";
import type { Activity, RGB, SceneName, ToolKind } from "dotmind";
import type { FrameScheduler } from "../src/frameLoop.ts";
import type { MatrixPainter } from "../src/painter.ts";

export class RecordingPainter implements MatrixPainter {
  readonly buffers: Float32Array[] = [];
  readonly colors: RGB[] = [];
  last = new Float32Array(64);

  get count(): number {
    return this.buffers.length;
  }

  paint(values: Float32Array, color: RGB): void {
    this.buffers.push(values);
    this.colors.push([color[0], color[1], color[2]]);
    this.last = values.slice();
  }
}

export class ManualScheduler implements FrameScheduler {
  private next = 1;
  readonly pending = new Map<number, (now: number) => void>();
  requests = 0;

  request(callback: (now: number) => void): number {
    const handle = this.next++;
    this.requests++;
    this.pending.set(handle, callback);
    return handle;
  }

  cancel(handle: number): void {
    this.pending.delete(handle);
  }

  flush(now: number): void {
    const due = [...this.pending.values()];
    this.pending.clear();
    for (const callback of due) callback(now);
  }
}

export interface Golden {
  tolerance: number;
  frames: { scene: SceneName; t: number; progress: number; energy: number; values: number[] }[];
  tools: { name: string; kind: ToolKind }[];
  scenes: { activity: Activity; scene: string; label: string }[];
  energy: { frame: number; energy: number; values: number[] }[];
}

export function loadGolden(): Golden {
  return JSON.parse(readFileSync(join(import.meta.dirname, "../../../spec/golden.json"), "utf8")) as Golden;
}
