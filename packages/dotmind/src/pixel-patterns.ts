import { at, bitmap, hash, light, mod, type Cell } from "./grid.ts";
import type { Pattern, PixelScene, RGB } from "./types.ts";

const BUG_HEAD = bitmap([
  "........",
  "........",
  "..####..",
  ".######.",
]);
const BUG_ABDOMEN = bitmap([
  "........",
  "........",
  "........",
  "........",
  ".######.",
  ".######.",
  "..####..",
]);
const BUG_ANTENNAE: Cell[] = [[1, 0], [2, 1], [6, 0], [5, 1]];
const BUG_EYES: Cell[] = [[2, 3], [5, 3]];
const BUG_LEGS: readonly Cell[][] = [
  [[0, 3], [7, 3], [0, 5], [7, 5], [1, 7], [6, 7]],
  [[0, 4], [7, 4], [0, 6], [7, 6], [2, 7], [5, 7]],
];
const BUG_BODY = [...BUG_HEAD, ...BUG_ABDOMEN];
const BUG_SPRITE = [...BUG_BODY, ...BUG_ANTENNAE, ...BUG_LEGS[0]];
const BUG_PERIOD = 6.3;
const BUG_SPARKLE = 0.9;
const BUG_SCAN = 1.6;
const BUG_FORM = 2.5;
const BUG_FADE = 5.2;

function sparkle(o: Float32Array, t: number, amount: number): void {
  const k = Math.floor(t / 0.35);
  for (let i = 0; i < 64; i++) {
    if (hash(i, k) > 1 - 0.14 * amount) o[i] = Math.max(o[i], 0.35 + 0.6 * hash(i, k + 0.5));
  }
}

interface Piece {
  cells: Cell[];
  start: number;
  land: number;
  y: number;
}

const BLOCK_DROPS: ReadonlyArray<readonly [readonly string[], number]> = [
  [["##", "##"], 0],
  [["####"], 4],
  [["##", "##"], 2],
  [["####"], 4],
  [["#..", "###"], 0],
  [["..#", "###"], 3],
  [["##", "##"], 6],
  [["####"], 1],
  [["##", "##"], 0],
  [["#", "#", "#"], 2],
  [["###"], 3],
  [["##", "##"], 6],
  [["###"], 3],
  [[".#.", "###"], 3],
];

const BLOCK_PIECES: Piece[] = (() => {
  const board = new Uint8Array(64);
  const pieces: Piece[] = [];
  let clock = 0;
  for (const [rows, x] of BLOCK_DROPS) {
    const shape = bitmap(rows);
    const fits = (y: number) =>
      shape.every(([cx, cy]) => y + cy < 8 && (y + cy < 0 || !board[at(x + cx, y + cy)]));
    let y = -rows.length;
    while (fits(y + 1)) y++;
    if (y < 0) break;
    for (const [cx, cy] of shape) board[at(x + cx, y + cy)] = 1;
    const fall = y + rows.length;
    pieces.push({ cells: shape.map(([cx, cy]) => [x + cx, cy] as Cell), start: clock, land: clock + fall, y });
    clock += fall + 1;
  }
  return pieces;
})();
const BLOCK_STEP = 0.075;
const BLOCK_FILLED = BLOCK_PIECES[BLOCK_PIECES.length - 1].land + 1;
const BLOCK_FLASH = 4;
const BLOCK_CLEAR = 8;
const BLOCK_CYCLE = BLOCK_FILLED + BLOCK_FLASH + BLOCK_CLEAR;

const SCAN_ROW = 0.4;
const SCAN_PASS = SCAN_ROW * 8;

export const PIXEL_PATTERNS: Record<PixelScene, Pattern> = {
  bug(t, o) {
    o.fill(0);
    const u = mod(t, BUG_PERIOD);
    if (u < BUG_SPARKLE) {
      sparkle(o, t, 1);
      return;
    }
    if (u < BUG_SCAN) {
      sparkle(o, t, 0.6);
      const row = Math.floor(((u - BUG_SPARKLE) / (BUG_SCAN - BUG_SPARKLE)) * 8);
      for (let x = 0; x < 8; x++) {
        light(o, x, row, 1);
        light(o, x, row - 1, 0.45);
      }
      return;
    }
    const legs = BUG_LEGS[Math.floor(t / 0.3) % 2];
    if (u < BUG_FORM) {
      const s = (u - BUG_SCAN) / (BUG_FORM - BUG_SCAN);
      sparkle(o, t, 1 - s);
      for (const [x, y] of BUG_SPRITE) if (hash(at(x, y), 21) < s * 1.15) light(o, x, y, 0.85);
      return;
    }
    if (u >= BUG_FADE) {
      const s = (u - BUG_FADE) / (BUG_PERIOD - BUG_FADE);
      sparkle(o, t, s);
      for (const [x, y] of BUG_SPRITE) if (hash(at(x, y), 21) >= s) light(o, x, y, 0.85 * (1 - s * 0.5));
      return;
    }
    for (const [x, y] of BUG_HEAD) light(o, x, y, 0.95);
    for (const [x, y] of BUG_ABDOMEN) light(o, x, y, x === 3 || x === 4 ? 0.6 : 0.85);
    for (const [x, y] of BUG_ANTENNAE) light(o, x, y, 0.8);
    for (const [x, y] of legs) light(o, x, y, 0.8);
    const blink = u > 3.9 && u < 4.08;
    for (const [x, y] of BUG_EYES) o[at(x, y)] = blink ? 0.95 : 1.5;
    const [px, py] = BUG_ABDOMEN[Math.floor(hash(Math.floor(t / 0.35), 23) * BUG_ABDOMEN.length)];
    light(o, px, py, 1.3);
  },

  blocks(t, o) {
    o.fill(0);
    const step = mod(Math.floor(t / BLOCK_STEP), BLOCK_CYCLE);
    const flashing = step >= BLOCK_FILLED && step < BLOCK_FILLED + BLOCK_FLASH;
    const cleared = step - BLOCK_FILLED - BLOCK_FLASH;
    for (const piece of BLOCK_PIECES) {
      if (step < piece.start) break;
      const landed = step >= piece.land;
      const y = landed ? piece.y : piece.y - (piece.land - step);
      const fresh = landed && step - piece.land < 2;
      let v = !landed ? 1.1 : fresh ? 1.35 : 0.72;
      if (flashing) v = step % 2 ? 1.4 : 0.9;
      for (const [x, cy] of piece.cells) {
        if (cleared >= 0 && y + cy >= 8 - cleared) continue;
        light(o, x, y + cy, cleared >= 0 ? 0.72 * (1 - cleared / BLOCK_CLEAR) + 0.1 : v);
      }
    }
  },

  scan(t, o) {
    const pass = Math.floor(t / SCAN_PASS);
    const u = t - pass * SCAN_PASS;
    const row = Math.floor(u / SCAN_ROW);
    const cursor = Math.floor(((u - row * SCAN_ROW) / SCAN_ROW) * 9) - 1;
    const noise = Math.floor(t / 1.3);
    for (let i = 0; i < 64; i++) {
      const x = i % 8;
      const y = Math.floor(i / 8);
      const h = hash(i, noise + pass * 17);
      let v = h > 0.62 ? 0.06 + 0.22 * h : 0;
      if (y < row) v = hash(i, pass + 31) > 0.5 ? 0.42 + (y === row - 1 ? 0.22 : 0) : 0;
      if (y === row) v = x < cursor ? 0.98 : x === cursor ? 1.5 : v;
      o[i] = v;
    }
  },
};

export const PIXEL_COLORS: Record<PixelScene, RGB> = {
  bug: [72, 164, 255],
  blocks: [255, 150, 40],
  scan: [255, 82, 72],
};
