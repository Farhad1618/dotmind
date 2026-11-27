export const SHIMMER_FROM = 1.3;
export const SHIMMER_TO = -0.3;
export const SHIMMER_REST = 1;
export const SHIMMER_STILL = 0.5;
export const SHIMMER_SPAN = 2.6;
export const SHIMMER_ANGLE = (100 * Math.PI) / 180;
export const SHIMMER_STOPS = [0, 0.38, 0.47, 0.52, 0.62, 1];

export type ShimmerMode = "sweep" | "rest" | "still";

export interface Point {
  x: number;
  y: number;
}

export function shimmerMode(busy: boolean, reducedMotion: boolean): ShimmerMode {
  if (!busy) return "rest";
  return reducedMotion ? "still" : "sweep";
}

export function shimmerPoint(position: number, width: number, height: number, edge: -1 | 1, out: Point): Point {
  "worklet";
  const span = width * SHIMMER_SPAN;
  const dx = Math.sin(SHIMMER_ANGLE);
  const dy = -Math.cos(SHIMMER_ANGLE);
  const length = Math.abs(span * dx) + Math.abs(height * dy);
  const cx = (width - span) * position + span / 2;
  const cy = height / 2;
  out.x = cx + (dx * length * edge) / 2;
  out.y = cy + (dy * length * edge) / 2;
  return out;
}
