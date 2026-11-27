import { test } from "node:test";
import assert from "node:assert/strict";
import { SHIMMER_FROM, SHIMMER_REST, SHIMMER_STILL, SHIMMER_TO, shimmerMode, shimmerPoint } from "../src/shimmer.ts";

const W = 100;
const H = 18;

function fractionAt(x: number, position: number): number {
  const a = shimmerPoint(position, W, H, -1, { x: 0, y: 0 });
  const b = shimmerPoint(position, W, H, 1, { x: 0, y: 0 });
  const dx = b.x - a.x;
  const dy = b.y - a.y;
  return ((x - a.x) * dx + (H / 2 - a.y) * dy) / (dx * dx + dy * dy);
}

test("the highlight enters from the left and leaves on the right", () => {
  assert.ok(fractionAt(0, SHIMMER_FROM) > 0.62, "highlight starts left of the text");
  assert.ok(fractionAt(W, SHIMMER_TO) < 0.38, "highlight ends right of the text");
  assert.ok(Math.abs(fractionAt(W / 2, SHIMMER_STILL) - 0.5) < 0.01, "still frame centres it");
});

test("at rest the label is plain ink", () => {
  assert.ok(fractionAt(0, SHIMMER_REST) > 0.6);
  assert.ok(fractionAt(W, SHIMMER_REST) <= 1.0001);
});

test("the gradient tilts like the 100 degree CSS gradient", () => {
  const a = shimmerPoint(0.5, W, H, -1, { x: 0, y: 0 });
  const b = shimmerPoint(0.5, W, H, 1, { x: 0, y: 0 });
  assert.ok(b.x > a.x && b.y > a.y);
  assert.ok(Math.abs(Math.atan2(b.y - a.y, b.x - a.x) - (10 * Math.PI) / 180) < 1e-9);
});

test("busy phases sweep unless motion is reduced", () => {
  assert.equal(shimmerMode(true, false), "sweep");
  assert.equal(shimmerMode(true, true), "still");
  assert.equal(shimmerMode(false, false), "rest");
  assert.equal(shimmerMode(false, true), "rest");
});

test("a shimmer point is written into the point it is given", () => {
  const out = { x: 0, y: 0 };
  assert.equal(shimmerPoint(0.25, W, H, 1, out), out);
  const again = shimmerPoint(0.25, W, H, 1, { x: 0, y: 0 });
  assert.deepEqual(out, again);
});
