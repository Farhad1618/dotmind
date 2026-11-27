import { GRID } from "dotmind";

export const CELLS = GRID * GRID;

export interface MatrixGeometry {
  readonly size: number;
  readonly padding: number;
  readonly step: number;
  readonly radius: number;
  readonly xs: Float32Array;
  readonly ys: Float32Array;
}

export function matrixGeometry(size: number): MatrixGeometry {
  const padding = size * 0.12;
  const step = (size - padding * 2) / (GRID - 1);
  const xs = new Float32Array(CELLS);
  const ys = new Float32Array(CELLS);
  for (let i = 0; i < CELLS; i++) {
    xs[i] = padding + (i % GRID) * step;
    ys[i] = padding + Math.floor(i / GRID) * step;
  }
  return { size, padding, step, radius: step * 0.34, xs, ys };
}
