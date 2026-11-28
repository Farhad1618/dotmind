import { test } from "node:test";
import assert from "node:assert/strict";
import { SCENE_COLORS, type Look } from "dotmind";
import { lookStyle } from "../src/lookStyle.ts";
import { present } from "../src/presentation.ts";

test("each look brings its shape and aura", () => {
  assert.deepEqual(lookStyle({}), { shape: "dot", aura: false });
  assert.deepEqual(lookStyle({ look: "classic" }), { shape: "dot", aura: false });
  assert.deepEqual(lookStyle({ look: "icons" }), { shape: "dot", aura: true });
  assert.deepEqual(lookStyle({ look: "pixel" }), { shape: "square", aura: false });
});

test("shape and aura options override the look", () => {
  assert.deepEqual(lookStyle({ look: "pixel", shape: "dot", aura: true }), { shape: "dot", aura: true });
  assert.deepEqual(lookStyle({ look: "icons", aura: false }), { shape: "dot", aura: false });
  assert.deepEqual(lookStyle({ shape: "square" }), { shape: "square", aura: false });
});

test("an unknown look falls back to classic", () => {
  assert.deepEqual(lookStyle({ look: "neon" as Look }), { shape: "dot", aura: false });
  assert.deepEqual(lookStyle({ look: "toString" as Look }), { shape: "dot", aura: false });
  assert.equal(present({ phase: "thinking" }, { look: "neon" as Look }).scene, "comet");
  assert.equal(present({ phase: "thinking" }, { look: "toString" as Look }).scene, "comet");
});

test("scene precedence is scene, then overrides, then the look, then classic", () => {
  const thinking = { phase: "thinking" } as const;
  assert.equal(present(thinking, { look: "icons" }).scene, "neural");
  assert.equal(present(thinking, { look: "icons", scenes: { thinking: "orbit" } }).scene, "orbit");
  assert.equal(present(thinking, { look: "icons", scenes: { thinking: "orbit" }, scene: "ember" }).scene, "ember");
  assert.equal(present({ phase: "writing" }, { look: "icons" }).scene, "type");
  assert.equal(present({ phase: "tool" }, { look: "pixel", scenes: { "tool:generic": "scan" } }).scene, "scan");
});

test("new scenes take their own colour and the palette still wins", () => {
  const debug = present({ phase: "tool", kind: "debug" }, { look: "pixel" });
  assert.equal(debug.scene, "bug");
  assert.equal(debug.text, "Debugging");
  assert.deepEqual(debug.color, SCENE_COLORS.bug);
  assert.deepEqual(present({ phase: "tool", kind: "debug" }, { palette: { bug: [1, 2, 3] } }).color, [1, 2, 3]);
});
