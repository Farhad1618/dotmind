import { test } from "node:test";
import assert from "node:assert/strict";
import { classifyTool, PATTERNS } from "dotmind";
import { present } from "../src/presentation.ts";
import { loadGolden } from "./fakes.ts";

const golden = loadGolden();

test("every golden pattern frame matches within tolerance", () => {
  assert.ok(golden.frames.length > 0);
  const out = new Float32Array(64);
  for (const { scene, t, progress, energy, values } of golden.frames) {
    out.fill(0);
    PATTERNS[scene](t, out, { energy, progress });
    for (let k = 0; k < 64; k++) {
      assert.ok(Math.abs(out[k] - values[k]) <= golden.tolerance, `${scene} t=${t} progress=${progress} dot ${k}`);
    }
  }
});

test("every golden tool name classifies to the reference kind", () => {
  assert.ok(golden.tools.length > 0);
  for (const { name, kind } of golden.tools) assert.equal(classifyTool(name), kind, name);
});

test("every golden scene key gets the reference scene and label in every look", () => {
  assert.ok(golden.looks.length > 0);
  for (const { activity, look, scene, label } of golden.looks) {
    const shown = present(activity, { look });
    assert.equal(shown.scene, scene, `${look} ${JSON.stringify(activity)}`);
    assert.equal(shown.text, label, `${look} ${JSON.stringify(activity)}`);
  }
});
