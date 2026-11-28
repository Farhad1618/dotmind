import { test } from "node:test";
import assert from "node:assert/strict";
import type { RGB } from "dotmind";
import { AURA_SECONDS, blendAura, startAura } from "../src/auraBlend.ts";

const amber: RGB = [255, 140, 60];
const teal: RGB = [0, 200, 180];
const rose: RGB = [240, 80, 120];

test("the aura cross-fades over 0.35 s", () => {
  assert.equal(AURA_SECONDS, 0.35);
});

test("an aura starts lit or dark in the scene colour", () => {
  assert.deepEqual(startAura(amber, true).layers[0], { color: amber, opacity: 1 });
  assert.equal(startAura(amber, false).layers[0].opacity, 0);
  assert.equal(startAura(amber, true).layers[1].opacity, 0);
});

test("the same colour keeps the blend untouched", () => {
  const blend = startAura(amber, true);
  assert.equal(blendAura(blend, [255, 140, 60], true), blend);
});

test("a new colour fades in on the other layer while the old one fades out", () => {
  const next = blendAura(startAura(amber, true), teal, true);
  assert.equal(next.active, 1);
  assert.deepEqual(next.layers[0], { color: amber, opacity: 0 });
  assert.deepEqual(next.layers[1], { color: teal, opacity: 1 });
  const again = blendAura(next, rose, true);
  assert.equal(again.active, 0);
  assert.deepEqual(again.layers[0], { color: rose, opacity: 1 });
  assert.deepEqual(again.layers[1], { color: teal, opacity: 0 });
});

test("turning the aura off fades both layers out and back on fades in", () => {
  const off = blendAura(blendAura(startAura(amber, true), teal, true), teal, false);
  assert.deepEqual(off.layers.map((layer) => layer.opacity), [0, 0]);
  assert.equal(off.active, 1);
  const on = blendAura(off, teal, true);
  assert.deepEqual(on.layers[1], { color: teal, opacity: 1 });
  assert.equal(on.layers[0].opacity, 0);
  const dark = blendAura(startAura(amber, false), teal, false);
  assert.deepEqual(dark.layers.map((layer) => layer.opacity), [0, 0]);
  assert.deepEqual(dark.layers[dark.active].color, teal);
});
