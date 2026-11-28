export const GRID = 8;
export const C = 3.5;
export const TAU = Math.PI * 2;

export type Cell = readonly [number, number];

export const clamp = (v: number, a: number, b: number) => (v < a ? a : v > b ? b : v);

export const hash = (i: number, s: number) => {
  const x = Math.sin(i * 127.1 + s * 311.7) * 43758.5453;
  return x - Math.floor(x);
};

export const at = (x: number, y: number) => y * GRID + x;

export const wrapAngle = (a: number) => ((a % TAU) + TAU) % TAU;

export const mod = (a: number, n: number) => ((a % n) + n) % n;

export function bitmap(rows: readonly string[]): Cell[] {
  const cells: Cell[] = [];
  rows.forEach((row, y) => [...row].forEach((ch, x) => ch === "#" && cells.push([x, y])));
  return cells;
}

export function light(out: Float32Array, x: number, y: number, v: number): void {
  if (x < 0 || x >= GRID || y < 0 || y >= GRID) return;
  const i = at(x, y);
  if (v > out[i]) out[i] = v;
}

export function fillCells(out: Float32Array, cells: readonly Cell[], v: number): void {
  for (const [x, y] of cells) light(out, x, y, v);
}

export function trail(out: Float32Array, path: readonly Cell[], head: number, len: number, decay: number): void {
  const n = path.length;
  for (let k = 0; k < len; k++) {
    const [x, y] = path[mod(Math.floor(head) - k, n)];
    light(out, x, y, k === 0 ? 1.4 : Math.pow(decay, k) * 1.05);
  }
}

export function line(a: Cell, b: Cell): Cell[] {
  const cells: Cell[] = [];
  let [x0, y0] = a;
  const [x1, y1] = b;
  const dx = Math.abs(x1 - x0);
  const dy = -Math.abs(y1 - y0);
  const sx = x0 < x1 ? 1 : -1;
  const sy = y0 < y1 ? 1 : -1;
  let err = dx + dy;
  for (;;) {
    cells.push([x0, y0]);
    if (x0 === x1 && y0 === y1) return cells;
    const e2 = 2 * err;
    if (e2 >= dy) {
      err += dy;
      x0 += sx;
    }
    if (e2 <= dx) {
      err += dx;
      y0 += sy;
    }
  }
}
