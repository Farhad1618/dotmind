import type { RGB } from "dotmind";

export const LIT_THRESHOLD = 0.03;
export const GLOW_LEVELS = 8;

export interface DotLook {
  alpha: number;
  heat: number;
  red: number;
  green: number;
  blue: number;
  glowRadius: number;
  radiusScale: number;
}

const clamp = (v: number, lo: number, hi: number) => (v < lo ? lo : v > hi ? hi : v);

export function createDotLook(): DotLook {
  return { alpha: 0, heat: 0, red: 0, green: 0, blue: 0, glowRadius: 0, radiusScale: 1 };
}

export function heatOf(value: number): number {
  return clamp((clamp(value, 0, 1.5) - 0.85) / 0.55, 0, 1);
}

export function glowRadius(half: number, heat: number): number {
  return half * (1.5 + heat * 2.5);
}

export function glowLevel(heat: number): number {
  return Math.round(heat * GLOW_LEVELS);
}

export function lookAt(value: number, color: RGB, half: number, out: DotLook): boolean {
  const v = clamp(value, 0, 1.5);
  if (v < LIT_THRESHOLD) return false;
  const w = heatOf(v);
  out.alpha = clamp(v, 0, 1);
  out.heat = w;
  out.red = (color[0] + (255 - color[0]) * w) | 0;
  out.green = (color[1] + (255 - color[1]) * w) | 0;
  out.blue = (color[2] + (255 - color[2]) * w) | 0;
  out.glowRadius = glowRadius(half, w);
  out.radiusScale = 1 + w * 0.12;
  return true;
}
