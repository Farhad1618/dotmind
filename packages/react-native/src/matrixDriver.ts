import { DotRenderer, type RGB, type SceneName } from "dotmind";
import { CELLS } from "./geometry.ts";
import type { FrameClient } from "./frameLoop.ts";
import type { MatrixPainter } from "./painter.ts";

const STILL_STEPS = [1.2, 0.5] as const;

export class MatrixDriver implements FrameClient {
  private readonly renderer = new DotRenderer();
  private readonly values = new Float32Array(CELLS);
  private readonly rgb: [number, number, number] = [0, 0, 0];
  private shownColor: RGB | null = null;
  private painter: MatrixPainter | null = null;
  private drawn = false;
  private still = false;
  private visible = true;
  private foreground = true;

  get animating(): boolean {
    return this.painter !== null && !this.still && this.shown;
  }

  get shown(): boolean {
    return this.visible && this.foreground;
  }

  get scene(): SceneName {
    return this.renderer.scene;
  }

  get level(): number {
    return this.renderer.level;
  }

  get frame(): Float32Array {
    return this.values;
  }

  attach(painter: MatrixPainter): void {
    this.painter = painter;
    this.draw();
  }

  detach(): void {
    this.painter = null;
  }

  setStill(still: boolean): void {
    if (still === this.still) return;
    this.still = still;
    if (still) this.settle();
  }

  setVisible(visible: boolean): void {
    this.visible = visible;
  }

  setForeground(foreground: boolean): void {
    this.foreground = foreground;
  }

  show(scene: SceneName, color: RGB, progress: number | undefined): void {
    const changed = scene !== this.renderer.scene || color !== this.shownColor;
    this.shownColor = color;
    this.renderer.feed(progress);
    this.renderer.show(scene, color, !this.drawn || !this.shown);
    if (this.still) this.settle();
    else if (!this.drawn || (changed && !this.shown)) this.draw();
  }

  sample(out: Float32Array): Float32Array {
    return this.renderer.sample(out);
  }

  tick(dt: number): void {
    if (!this.animating) return;
    this.renderer.step(dt);
    this.draw();
  }

  private settle(): void {
    for (const dt of STILL_STEPS) this.renderer.step(dt);
    this.draw();
  }

  private draw(): void {
    if (!this.painter) return;
    this.renderer.sample(this.values);
    this.painter.paint(this.values, this.renderer.color(this.rgb));
    this.drawn = true;
  }
}
