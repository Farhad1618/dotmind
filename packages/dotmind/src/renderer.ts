import { GRID, PATTERNS, SCENE_COLORS } from "./patterns.ts";
import type { PatternContext, RGB, SceneName } from "./types.ts";

const CELLS = GRID * GRID;
const BLEND_SECONDS = 0.35;

const clamp = (v: number, a: number, b: number) => (v < a ? a : v > b ? b : v);

interface Layer {
  scene: SceneName;
  color: RGB;
  t: number;
  origin: number;
}

export class DotRenderer {
  private current: Layer;
  private previous: Layer | null = null;
  private blend = 1;
  private readonly cur = new Float32Array(CELLS);
  private readonly prev = new Float32Array(CELLS);
  private readonly curCtx: PatternContext = { energy: 0, progress: 0 };
  private readonly prevCtx: PatternContext = { energy: 0, progress: 0 };
  private energy = 0.3;
  private rate = 0;
  private lastProgress: number | null = null;
  private lastProgressAt = 0;
  private synthetic = 0;
  private clock = 0;
  private hasProgress = false;

  constructor(scene: SceneName = "breathe", color: RGB = SCENE_COLORS[scene]) {
    this.current = { scene, color, t: 0, origin: 0 };
  }

  get scene(): SceneName {
    return this.current.scene;
  }

  get level(): number {
    return this.energy;
  }

  show(scene: SceneName, color: RGB = SCENE_COLORS[scene], instant = false): void {
    if (scene === this.current.scene) {
      this.current.color = color;
      return;
    }
    this.previous = instant ? null : this.current;
    this.current = { scene, color, t: 0, origin: this.progressNow() };
    this.blend = instant ? 1 : 0;
  }

  feed(progress: number | undefined): void {
    if (progress === undefined) {
      this.hasProgress = false;
      return;
    }
    this.hasProgress = true;
    if (this.lastProgress === null || progress < this.lastProgress) {
      this.lastProgress = progress;
      this.lastProgressAt = this.clock;
      this.rate = 0;
      this.current.origin = Math.min(this.current.origin, progress);
      return;
    }
    if (progress === this.lastProgress) return;
    const dt = Math.max(1 / 60, this.clock - this.lastProgressAt);
    const inst = (progress - this.lastProgress) / dt;
    this.rate = this.rate * 0.7 + inst * 0.3;
    this.lastProgress = progress;
    this.lastProgressAt = this.clock;
  }

  step(dt: number): void {
    this.clock += dt;
    if (this.clock - this.lastProgressAt > 0.45) this.rate *= Math.exp(-dt * 3);
    const target = clamp(0.3 + this.rate / 160, 0.3, 1.5);
    this.energy += (target - this.energy) * (1 - Math.exp(-dt * 6));
    const speed = 0.6 + 0.6 * this.energy;
    this.current.t += dt * speed;
    if (this.previous) this.previous.t += dt * speed;
    this.synthetic += dt * 40 * speed;
    if (this.blend < 1) {
      this.blend = Math.min(1, this.blend + dt / BLEND_SECONDS);
      if (this.blend >= 1) this.previous = null;
    }
  }

  sample(out: Float32Array = new Float32Array(CELLS)): Float32Array {
    const now = this.progressNow();
    this.curCtx.energy = this.energy;
    this.curCtx.progress = Math.max(0, now - this.current.origin);
    PATTERNS[this.current.scene](this.current.t, this.cur, this.curCtx);
    if (!this.previous) {
      out.set(this.cur);
      return out;
    }
    this.prevCtx.energy = this.energy;
    this.prevCtx.progress = Math.max(0, now - this.previous.origin);
    PATTERNS[this.previous.scene](this.previous.t, this.prev, this.prevCtx);
    const k = this.easedBlend();
    for (let i = 0; i < CELLS; i++) out[i] = this.prev[i] * (1 - k) + this.cur[i] * k;
    return out;
  }

  color(out: [number, number, number] = [0, 0, 0]): [number, number, number] {
    const from = this.previous?.color ?? this.current.color;
    const to = this.current.color;
    const k = this.previous ? this.easedBlend() : 1;
    out[0] = from[0] + (to[0] - from[0]) * k;
    out[1] = from[1] + (to[1] - from[1]) * k;
    out[2] = from[2] + (to[2] - from[2]) * k;
    return out;
  }

  private progressNow(): number {
    return this.hasProgress ? this.lastProgress ?? 0 : this.synthetic;
  }

  private easedBlend(): number {
    const k = this.blend;
    return k * k * (3 - 2 * k);
  }
}
