import { C, at, bitmap, fillCells, hash, light, line, mod, type Cell } from "./grid.ts";
import type { IconScene, Pattern, RGB } from "./types.ts";

const NODES: Cell[] = [[1, 0], [6, 1], [3, 3], [0, 5], [7, 4], [5, 6], [2, 7]];
const EDGES: ReadonlyArray<readonly [number, number]> = [
  [0, 2], [1, 2], [1, 4], [2, 3], [2, 4], [2, 5], [3, 6], [4, 5], [5, 6],
];
const EDGE_CELLS = EDGES.map(([a, b]) => line(NODES[a], NODES[b]));
const FIRE_STEP = 0.35;
const FIRE_MEMORY = 6;
const SIGNAL_SECONDS = 0.47;

function firedAt(node: number, step: number): boolean {
  if (Math.floor(hash(step, 3) * NODES.length) === node) return true;
  return hash(step, 4) > 0.55 && Math.floor(hash(step, 5) * NODES.length) === node;
}

function nodeAge(node: number, t: number): number {
  const now = Math.floor(t / FIRE_STEP);
  for (let k = now; k > now - FIRE_MEMORY; k--) {
    if (firedAt(node, k)) return t - k * FIRE_STEP;
  }
  return Infinity;
}

const LENS = bitmap([".##.", "#..#", "#..#", ".##."]);
const LENS_INSIDE: Cell[] = [[1, 1], [2, 1], [1, 2], [2, 2]];
const HANDLE: Cell[] = [[3, 3], [4, 4]];

const GLYPH_A = bitmap([
  "...##...",
  "..#..#..",
  ".#....#.",
  ".#....#.",
  ".######.",
  ".#....#.",
  ".#....#.",
  ".#....#.",
]);
const GLYPH_WEN = bitmap([
  "...##...",
  "########",
  ".#....#.",
  "..#..#..",
  "...##...",
  "..#..#..",
  ".##..##.",
  "##....##",
]);
const GLYPH_HOLD = 1.6;
const GLYPH_SWEEP = 0.95;
const GLYPH_PERIOD = 2 * (GLYPH_HOLD + GLYPH_SWEEP);

function glyphMask(cells: readonly Cell[]): Uint8Array {
  const m = new Uint8Array(64);
  for (const [x, y] of cells) m[at(x, y)] = 1;
  return m;
}
const MASK_A = glyphMask(GLYPH_A);
const MASK_WEN = glyphMask(GLYPH_WEN);

const SORT_STEP = 0.16;
const SORT_SLOTS = 40;

function shuffled(seed: number): number[] {
  const bars = [1, 2, 3, 4, 5, 6, 7, 8];
  for (let i = bars.length - 1; i > 0; i--) {
    const j = Math.floor(hash(seed * 8 + i, 9) * (i + 1));
    [bars[i], bars[j]] = [bars[j], bars[i]];
  }
  return bars;
}

interface SortFrame {
  bars: number[];
  hot: number;
  cmp: number;
  doneFor: number;
}

function insertionSortAt(bars: number[], step: number): SortFrame {
  let count = 0;
  for (let i = 1; i < bars.length; i++) {
    for (let j = i; j > 0 && bars[j - 1] > bars[j]; j--) {
      if (count === step) return { bars, hot: j, cmp: j - 1, doneFor: -1 };
      [bars[j - 1], bars[j]] = [bars[j], bars[j - 1]];
      count++;
    }
  }
  return { bars, hot: -1, cmp: -1, doneFor: step - count };
}

const ROCKET_PERIOD = 2.6;
const ROCKET_IGNITE = 0.75;
const ROCKET_FLIGHT = 1.15;

const CHECK: Cell[] = [[1, 4], [2, 5], [3, 6], [4, 5], [5, 4], [6, 3], [7, 2]];
const RING_PERIOD = 1.45;

export const ICON_PATTERNS: Record<IconScene, Pattern> = {
  neural(t, o) {
    o.fill(0);
    EDGE_CELLS.forEach((cells) => fillCells(o, cells, 0.52));
    const ages = NODES.map((_, n) => nodeAge(n, t));
    EDGES.forEach(([a, b], e) => {
      const cells = EDGE_CELLS[e];
      for (const [from, path] of [[a, cells], [b, [...cells].reverse()]] as const) {
        const age = ages[from];
        if (age >= SIGNAL_SECONDS) continue;
        const k = Math.floor((age / SIGNAL_SECONDS) * path.length);
        const [x, y] = path[Math.min(path.length - 1, k)];
        light(o, x, y, 1.15);
      }
    });
    NODES.forEach(([x, y], n) => {
      o[at(x, y)] = 0.84 + 0.66 * Math.exp(-ages[n] * 3.2);
    });
  },

  magnifier(t, o) {
    for (let i = 0; i < 64; i++) o[i] = hash(i, 11) > 0.8 ? 0.2 : 0;
    const lx = Math.round(1.6 + 1.6 * Math.sin(t * 0.83));
    const ly = Math.round(1.5 + 1.5 * Math.sin(t * 1.21 + 1.3));
    for (const [x, y] of LENS_INSIDE) {
      const i = at(lx + x, ly + y);
      o[i] = hash(i, 11) > 0.8 ? 1.45 : 0.1;
    }
    for (const [x, y] of LENS) o[at(lx + x, ly + y)] = 1;
    for (const [x, y] of HANDLE) o[at(lx + x, ly + y)] = 0.78;
    o[at(lx + 1, ly)] = 1.3;
  },

  glyph(t, o) {
    const u = mod(t, GLYPH_PERIOD);
    const second = u >= GLYPH_HOLD + GLYPH_SWEEP;
    const local = second ? u - GLYPH_HOLD - GLYPH_SWEEP : u;
    const from = second ? MASK_WEN : MASK_A;
    const to = second ? MASK_A : MASK_WEN;
    const sweeping = local >= GLYPH_HOLD;
    const col = sweeping ? Math.floor(((local - GLYPH_HOLD) / GLYPH_SWEEP) * 10) - 1 : -2;
    for (let i = 0; i < 64; i++) {
      const x = i % 8;
      const y = Math.floor(i / 8);
      const on = x < col ? to[i] : from[i];
      const shimmer = 0.92 + 0.08 * Math.sin(t * 3.1 - x * 0.7 + y * 0.4);
      o[i] = on ? shimmer : 0;
      if (x === col) o[i] = from[i] || to[i] ? 1.5 : 1.05;
    }
  },

  sort(t, o) {
    o.fill(0);
    const step = Math.floor(t / SORT_STEP);
    const round = Math.floor(step / SORT_SLOTS);
    const frame = insertionSortAt(shuffled(round), mod(step, SORT_SLOTS));
    const sweep = frame.doneFor >= 0 && frame.doneFor < 9 ? frame.doneFor : -1;
    frame.bars.forEach((h, x) => {
      const hot = x === frame.hot;
      const v = hot ? 1.45 : x === frame.cmp ? 1.05 : x === sweep ? 1.3 : 0.78;
      for (let y = 8 - h; y < 8; y++) o[at(x, y)] = v;
    });
  },

  rocket(t, o) {
    o.fill(0);
    const launch = Math.floor(t / ROCKET_PERIOD);
    const u = t - launch * ROCKET_PERIOD;
    const x = 3 + (launch % 2);
    const charge = u < ROCKET_IGNITE ? u / ROCKET_IGNITE : 1 - (u - ROCKET_IGNITE) / (ROCKET_PERIOD - ROCKET_IGNITE);
    const flying = u >= ROCKET_IGNITE && u < ROCKET_IGNITE + ROCKET_FLIGHT;
    const s = (u - ROCKET_IGNITE) / ROCKET_FLIGHT;
    for (let px = x - 2; px <= x + 2; px++) {
      const near = Math.abs(px - x);
      const blast = flying && s < 0.25 && near <= 1 ? 1.3 : 0;
      light(o, px, 7, Math.max(blast, 0.5 + 0.35 * charge - near * 0.06));
    }
    if (u < ROCKET_IGNITE) {
      const flicker = Math.sin(t * 31) > 0 ? 1 : 0.6;
      light(o, x, 6, 0.6 + 0.85 * charge * flicker);
      return;
    }
    if (!flying) return;
    const head = Math.floor(6 - s * s * 10);
    light(o, x, head, 1.5);
    light(o, x, head + 1, 1.15);
    for (let k = 2; k < 5; k++) light(o, x, head + k, 0.85 * Math.pow(0.6, k - 1));
  },

  verified(t, o) {
    const r = 1.2 + (mod(t, RING_PERIOD) / RING_PERIOD) * 3.6;
    const fade = 1 - mod(t, RING_PERIOD) / RING_PERIOD;
    for (let i = 0; i < 64; i++) {
      const d = Math.hypot((i % 8) - C, Math.floor(i / 8) - C);
      const ring = Math.exp(-((d - r) ** 2) / 0.35) * 0.55 * fade;
      o[i] = ring > 0.06 ? ring + 0.08 : hash(i, 13) > 0.7 ? 0.12 : 0;
    }
    const drawn = t * 11;
    CHECK.forEach(([x, y], k) => {
      if (k < drawn) o[at(x, y)] = k + 1 > drawn ? 1.5 : 1.25 + 0.15 * Math.sin(t * 2.4 - k * 0.5);
    });
  },
};

export const ICON_COLORS: Record<IconScene, RGB> = {
  neural: [150, 104, 255],
  magnifier: [64, 196, 236],
  glyph: [255, 214, 64],
  sort: [255, 120, 32],
  rocket: [236, 72, 196],
  verified: [64, 214, 140],
};
