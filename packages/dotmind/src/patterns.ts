import type { Pattern, RGB, SceneName } from "./types.ts";

export const GRID = 8;
const C = 3.5;
const TAU = Math.PI * 2;

const clamp = (v: number, a: number, b: number) => (v < a ? a : v > b ? b : v);
const hash = (i: number, s: number) => {
  const x = Math.sin(i * 127.1 + s * 311.7) * 43758.5453;
  return x - Math.floor(x);
};
const at = (x: number, y: number) => y * GRID + x;
const wrapAngle = (a: number) => ((a % TAU) + TAU) % TAU;

type Cell = readonly [number, number];

function bitmap(rows: readonly string[]): Cell[] {
  const cells: Cell[] = [];
  rows.forEach((row, y) => [...row].forEach((ch, x) => ch === "#" && cells.push([x, y])));
  return cells;
}

function trail(out: Float32Array, path: readonly Cell[], head: number, len: number, decay: number) {
  const n = path.length;
  for (let k = 0; k < len; k++) {
    const i = (((Math.floor(head) - k) % n) + n) % n;
    const [x, y] = path[i];
    const v = k === 0 ? 1.4 : Math.pow(decay, k) * 1.05;
    out[at(x, y)] = Math.max(out[at(x, y)], v);
  }
}

function fillCells(out: Float32Array, cells: readonly Cell[], v: number) {
  for (const [x, y] of cells) out[at(x, y)] = Math.max(out[at(x, y)], v);
}

const RING12: Cell[] = [[2, 2], [3, 2], [4, 2], [5, 2], [5, 3], [5, 4], [5, 5], [4, 5], [3, 5], [2, 5], [2, 4], [2, 3]];
const CENTER: Cell[] = [[3, 3], [4, 3], [3, 4], [4, 4]];

const PERIMETER: Cell[] = (() => {
  const p: Cell[] = [];
  for (let x = 0; x < 8; x++) p.push([x, 0]);
  for (let y = 1; y < 8; y++) p.push([7, y]);
  for (let x = 6; x >= 0; x--) p.push([x, 7]);
  for (let y = 6; y > 0; y--) p.push([0, y]);
  return p;
})();

const SERPENT: Cell[] = (() => {
  const p: Cell[] = [];
  for (let x = 1; x < 8; x++) {
    for (let k = 0; k < 8; k++) p.push([x, x % 2 ? k : 7 - k]);
  }
  for (let y = 7; y >= 0; y--) p.push([0, y]);
  return p;
})();

const CODE = bitmap([
  "........",
  "..#..#..",
  ".#....#.",
  "#......#",
  ".#....#.",
  "..#..#..",
  "........",
  "........",
]);

const PAGE = bitmap([
  ".####...",
  ".#..##..",
  ".#...##.",
  ".#....#.",
  ".#....#.",
  ".#....#.",
  ".#....#.",
  ".######.",
]);
const PAGE_LINES: Cell[][] = [
  [[2, 3], [3, 3], [4, 3], [5, 3]],
  [[2, 4], [3, 4], [4, 4]],
  [[2, 5], [3, 5], [4, 5], [5, 5]],
  [[2, 6], [3, 6]],
];

const CROSS = bitmap([
  "........",
  ".#....#.",
  "..#..#..",
  "...##...",
  "...##...",
  "..#..#..",
  ".#....#.",
  "........",
]);

const CHECK_STROKE: Cell[] = [[1, 4], [2, 5], [3, 6], [4, 5], [5, 4], [6, 3], [7, 2]];

const DISKS = [0, 3, 6].map((y) => [
  ...[1, 2, 3, 4, 5, 6].map((x) => [x, y] as Cell),
  ...[1, 2, 3, 4, 5, 6].map((x) => [x, y + 1] as Cell),
]);

export const PATTERNS: Record<SceneName, Pattern> = {
  breathe(t, o) {
    o.fill(0);
    const p = 0.5 + 0.5 * Math.sin(t * 1.6);
    fillCells(o, CENTER, 0.18 + p * 0.5);
  },

  comet(t, o) {
    o.fill(0);
    for (let k = 0; k < 14; k++) {
      const a = t * 2.6 - k * 0.17;
      const x = Math.round(C + 3.2 * Math.sin(a));
      const y = Math.round(C + 3.1 * Math.sin(2 * a));
      const i = at(clamp(x, 0, 7), clamp(y, 0, 7));
      o[i] = Math.max(o[i], k === 0 ? 1.45 : Math.pow(0.8, k));
    }
  },

  radar(t, o) {
    const sweep = t * TAU / 1.6;
    const turn = Math.floor(sweep / TAU);
    for (let i = 0; i < 64; i++) {
      const dx = (i % 8) - C;
      const dy = Math.floor(i / 8) - C;
      const r = Math.hypot(dx, dy);
      if (r > 4) {
        o[i] = 0;
        continue;
      }
      const behind = wrapAngle(sweep - Math.atan2(dy, dx));
      let v = 0.1 + 1.1 * Math.exp(-behind * 2.4) * (0.4 + r / 6);
      if (hash(i, turn) > 0.9 && behind < 3) v = Math.max(v, 1.4 * Math.exp(-behind * 0.8));
      o[i] = v;
    }
  },

  globe(t, o) {
    o.fill(0);
    for (let i = 0; i < 64; i++) {
      const x = i % 8;
      const y = Math.floor(i / 8);
      const r = Math.hypot(x - C, y - C);
      if (Math.abs(r - 3.2) < 0.7) o[i] = 0.35;
      if (y === 3 || y === 4) o[i] = Math.max(o[i], r < 3.6 ? 0.22 : 0);
    }
    for (const off of [0, Math.PI]) {
      const s = Math.sin(t * 1.8 + off);
      const front = Math.cos(t * 1.8 + off) > 0;
      for (let y = 0; y < 8; y++) {
        const w = Math.sqrt(Math.max(0, 12.25 - (y - C) ** 2));
        const x = Math.round(C + w * s);
        if (x < 0 || x > 7) continue;
        const i = at(x, y);
        o[i] = Math.max(o[i], front ? 1.3 : 0.45);
      }
    }
  },

  code(t, o, ctx) {
    o.fill(0);
    fillCells(o, CODE, 0.7);
    const typed = Math.floor((ctx.progress * 0.2 + t * 3) % 6);
    for (let k = 0; k < typed && k < 4; k++) o[at(2 + k, 3)] = 0.85;
    const cx = 2 + Math.min(typed, 4);
    if (cx <= 5) o[at(cx, 3)] = Math.sin(t * 9) > 0 ? 1.45 : 0.3;
  },

  pages(t, o) {
    o.fill(0);
    fillCells(o, PAGE, 0.55);
    const line = Math.floor(t * 1.8) % (PAGE_LINES.length + 1);
    PAGE_LINES.forEach((cells, k) => {
      if (k < line) fillCells(o, cells, 0.75);
      if (k === line) {
        const head = (t * 1.8 - Math.floor(t * 1.8)) * cells.length;
        cells.forEach(([x, y], j) => {
          if (j <= head) o[at(x, y)] = j === Math.floor(head) ? 1.4 : 0.9;
        });
      }
    });
  },

  stack(t, o) {
    o.fill(0);
    const active = Math.floor(t * 2.2) % 3;
    const frac = t * 2.2 - Math.floor(t * 2.2);
    DISKS.forEach((cells, k) => {
      fillCells(o, cells, k === active ? 0.95 : 0.28);
      if (k === active) {
        const x = 1 + Math.floor(frac * 6);
        o[at(x, k * 3)] = 1.45;
        o[at(7 - x, k * 3 + 1)] = 1.2;
      }
    });
  },

  prism(t, o) {
    const s = 0.5 + 0.5 * Math.sin(t * 2.1);
    const r = 1 + 2.6 * s;
    for (let i = 0; i < 64; i++) {
      const x = i % 8;
      const y = Math.floor(i / 8);
      const m = Math.abs(x - C) + Math.abs(y - C);
      const on = Math.exp(-((m - r) ** 2) / 0.18);
      const axis = Math.abs(x - C) < 1 || Math.abs(y - C) < 1 ? 0.45 : 0;
      o[i] = on * (0.75 + axis + (1 - s) * 0.3);
    }
  },

  circuit(t, o) {
    o.fill(0);
    trail(o, PERIMETER, t * 13, 9, 0.8);
    fillCells(o, CENTER, 0.25 + (0.5 + 0.5 * Math.sin(t * 4)) * 0.9);
  },

  type(t, o, ctx) {
    o.fill(0);
    const total = Math.floor(ctx.progress / 4);
    let line = 0;
    let used = 0;
    const len = (k: number) => 3 + Math.floor(hash(k, 7) * 5);
    while (used + len(line) <= total) {
      used += len(line);
      line++;
    }
    const pos = total - used;
    const first = Math.max(0, line - 7);
    for (let k = first; k <= line; k++) {
      const row = k - first;
      const n = k < line ? len(k) : pos;
      for (let x = 0; x < n; x++) o[at(x, row)] = k === line ? 0.85 : 0.5;
      if (k === line && pos < 8) o[at(pos, row)] = Math.sin(t * 10) > -0.2 ? 1.45 : 0.25;
    }
  },

  halo(t, o) {
    o.fill(0);
    trail(o, RING12, t * 10, 6, 0.68);
    fillCells(o, CENTER, 0.15 + (0.5 + 0.5 * Math.sin(t * 2.2)) * 0.35);
  },

  cross(t, o) {
    o.fill(0);
    const flash = t < 0.9 ? (Math.sin(t * 22) > 0 ? 1.4 : 0.35) : 0.85 + 0.15 * Math.sin(t * 2);
    fillCells(o, CROSS, flash);
  },

  check(t, o) {
    o.fill(0);
    const drawn = t * 14;
    CHECK_STROKE.forEach(([x, y], k) => {
      if (k < drawn) o[at(x, y)] = k + 1 > drawn ? 1.45 : t > 1.2 ? 0.8 + 0.1 * Math.sin(t * 2) : 1.1;
    });
  },

  ember(t, o) {
    const hx = C + 2.4 * Math.sin(t * 1.3);
    const hy = C + 2.4 * Math.sin(t * 1.9 + 1);
    for (let i = 0; i < 64; i++) {
      const x = i % 8;
      const y = Math.floor(i / 8);
      const flick = Math.pow(Math.max(0, Math.sin(t * (2 + hash(i, 1) * 3) + hash(i, 2) * TAU)), 6) * 0.75;
      o[i] = Math.min(1.5, 0.12 + flick + 1.35 * Math.exp(-((x - hx) ** 2 + (y - hy) ** 2) / 1.1));
    }
  },

  orbit(t, o) {
    const head = t * TAU / 1.5;
    for (let i = 0; i < 64; i++) {
      const dx = (i % 8) - C;
      const dy = Math.floor(i / 8) - C;
      if (Math.abs(Math.hypot(dx, dy) - 3.1) > 0.75) {
        o[i] = 0;
        continue;
      }
      o[i] = 0.22 + 1.25 * Math.exp(-wrapAngle(head - Math.atan2(dy, dx)) * 1.1);
    }
  },

  serpent(t, o) {
    o.fill(0);
    trail(o, SERPENT, t * 11, 9, 0.78);
  },

  pulse(t, o) {
    for (let x = 0; x < 8; x++) {
      const h = 1 + 6.5 * (0.5 + 0.5 * Math.sin(t * 3.1 + x * 0.8) * Math.cos(t * 1.3 - x * 0.35));
      for (let y = 0; y < 8; y++) {
        const up = 7 - y;
        o[at(x, y)] = up < h - 1 ? 0.7 : up < h ? 1.4 : 0;
      }
    }
  },
};

export const SCENE_COLORS: Record<SceneName, RGB> = {
  breathe: [160, 160, 172],
  comet: [143, 125, 255],
  radar: [61, 123, 255],
  globe: [74, 168, 255],
  code: [255, 162, 31],
  pages: [56, 210, 190],
  stack: [255, 122, 26],
  prism: [255, 190, 60],
  circuit: [74, 168, 255],
  type: [228, 228, 236],
  halo: [255, 176, 32],
  cross: [255, 74, 62],
  check: [70, 220, 130],
  ember: [255, 74, 42],
  orbit: [61, 123, 255],
  serpent: [154, 107, 255],
  pulse: [255, 122, 26],
};

export const SCENE_NAMES = Object.keys(PATTERNS) as SceneName[];
