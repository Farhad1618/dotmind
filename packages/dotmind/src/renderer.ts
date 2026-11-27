import { GRID, PATTERNS, SCENE_COLORS } from "./patterns.ts";
import type { RGB, SceneName } from "./types.ts";

const CELLS = GRID * GRID;
const BLEND_SECONDS = 0.35;

const clamp = (v: number, a: number, b: number) => (v < a ? a : v > b ? b : v);
const mix = (a: RGB, b: RGB, k: number): RGB => [a[0] + (b[0] - a[0]) * k, a[1] + (b[1] - a[1]) * k, a[2] + (b[2] - a[2]) * k];

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
    const ctxFor = (layer: Layer) => ({ energy: this.energy, progress: Math.max(0, now - layer.origin) });
    PATTERNS[this.current.scene](this.current.t, this.cur, ctxFor(this.current));
    if (!this.previous) {
      out.set(this.cur);
      return out;
    }
    PATTERNS[this.previous.scene](this.previous.t, this.prev, ctxFor(this.previous));
    const k = this.easedBlend();
    for (let i = 0; i < CELLS; i++) out[i] = this.prev[i] * (1 - k) + this.cur[i] * k;
    return out;
  }

  color(): RGB {
    return this.previous ? mix(this.previous.color, this.current.color, this.easedBlend()) : this.current.color;
  }

  draw(ctx: CanvasRenderingContext2D, px: number, base = 0.14): void {
    const values = this.sample();
    const [r, g, b] = this.color();
    const pad = px * 0.12;
    const step = (px - pad * 2) / (GRID - 1);
    const rad = step * 0.34;
    ctx.clearRect(0, 0, px, px);
    ctx.shadowBlur = 0;
    ctx.fillStyle = `rgba(${r | 0},${g | 0},${b | 0},${base})`;
    ctx.beginPath();
    for (let i = 0; i < CELLS; i++) {
      const x = pad + (i % GRID) * step;
      const y = pad + Math.floor(i / GRID) * step;
      ctx.moveTo(x + rad, y);
      ctx.arc(x, y, rad, 0, Math.PI * 2);
    }
    ctx.fill();
    for (let i = 0; i < CELLS; i++) {
      const v = clamp(values[i], 0, 1.5);
      if (v < 0.03) continue;
      const x = pad + (i % GRID) * step;
      const y = pad + Math.floor(i / GRID) * step;
      const w = clamp((v - 0.85) / 0.55, 0, 1);
      const a = clamp(v, 0, 1);
      ctx.shadowColor = `rgba(${r | 0},${g | 0},${b | 0},${a})`;
      ctx.shadowBlur = rad * (1.5 + w * 2.5);
      ctx.fillStyle = `rgba(${(r + (255 - r) * w) | 0},${(g + (255 - g) * w) | 0},${(b + (255 - b) * w) | 0},${a})`;
      ctx.beginPath();
      ctx.arc(x, y, rad * (1 + w * 0.12), 0, Math.PI * 2);
      ctx.fill();
    }
  }

  private progressNow(): number {
    return this.hasProgress ? this.lastProgress ?? 0 : this.synthetic;
  }

  private easedBlend(): number {
    const k = this.blend;
    return k * k * (3 - 2 * k);
  }
}
