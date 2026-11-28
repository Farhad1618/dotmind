import { GRID, SHAPES, type Shape } from "dotmind";

export const CELLS = GRID * GRID;

export interface MatrixGeometry {
  readonly size: number;
  readonly shape: Shape;
  readonly padding: number;
  readonly step: number;
  readonly half: number;
  readonly corner: number;
  readonly base: number;
  readonly xs: Float32Array;
  readonly ys: Float32Array;
}

export interface CellBox {
  rect: { x: number; y: number; width: number; height: number };
  rx: number;
  ry: number;
}

export function matrixGeometry(size: number, shape: Shape = "dot"): MatrixGeometry {
  const resolved: Shape = Object.hasOwn(SHAPES, shape) ? shape : "dot";
  const { size: cell, corner, base } = SHAPES[resolved];
  const padding = size * 0.12;
  const step = (size - padding * 2) / (GRID - 1);
  const xs = new Float32Array(CELLS);
  const ys = new Float32Array(CELLS);
  for (let i = 0; i < CELLS; i++) {
    xs[i] = padding + (i % GRID) * step;
    ys[i] = padding + Math.floor(i / GRID) * step;
  }
  return { size, shape: resolved, padding, step, half: (step * cell) / 2, corner, base, xs, ys };
}

export function createCellBox(): CellBox {
  return { rect: { x: 0, y: 0, width: 0, height: 0 }, rx: 0, ry: 0 };
}

export function cellBox(x: number, y: number, half: number, corner: number, out: CellBox): CellBox {
  const side = half * 2;
  out.rect.x = x - half;
  out.rect.y = y - half;
  out.rect.width = side;
  out.rect.height = side;
  out.rx = side * corner;
  out.ry = out.rx;
  return out;
}
