import type { Shape } from "./types.ts";

export interface ShapeGeometry {
  size: number;
  corner: number;
  base: number;
}

export const SHAPES: Record<Shape, ShapeGeometry> = {
  dot: { size: 0.68, corner: 0.5, base: 0.14 },
  square: { size: 0.8, corner: 0.22, base: 0.2 },
};

export function shapeGeometry(shape: Shape | undefined): ShapeGeometry {
  return (shape && SHAPES[shape]) || SHAPES.dot;
}

export function traceCell(ctx: CanvasRenderingContext2D, x: number, y: number, half: number, shape: Shape): void {
  if (shape !== "square") {
    ctx.moveTo(x + half, y);
    ctx.arc(x, y, half, 0, Math.PI * 2);
    return;
  }
  const r = half * 2 * SHAPES.square.corner;
  const l = x - half;
  const t = y - half;
  const s = half * 2;
  ctx.moveTo(l + r, t);
  ctx.arcTo(l + s, t, l + s, t + s, r);
  ctx.arcTo(l + s, t + s, l, t + s, r);
  ctx.arcTo(l, t + s, l, t, r);
  ctx.arcTo(l, t, l + s, t, r);
  ctx.closePath();
}
