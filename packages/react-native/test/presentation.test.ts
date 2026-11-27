import { test } from "node:test";
import assert from "node:assert/strict";
import { SCENE_COLORS, type Activity } from "dotmind";
import { loadGolden } from "./fakes.ts";
import { glowFor, present, samePresentation, toActivity } from "../src/presentation.ts";

const golden = loadGolden();

test("every golden activity gets the reference scene and label", () => {
  for (const { activity, scene, label } of golden.scenes) {
    const shown = present(activity);
    assert.equal(shown.scene, scene, JSON.stringify(activity));
    assert.equal(shown.text, label, JSON.stringify(activity));
    assert.deepEqual(shown.color, SCENE_COLORS[shown.scene]);
  }
});

test("a phase string is shorthand for an activity", () => {
  assert.deepEqual(toActivity("thinking"), { phase: "thinking" });
  assert.deepEqual(toActivity(undefined), { phase: "idle" });
  const activity: Activity = { phase: "tool", tool: "web_search", kind: "search" };
  assert.equal(toActivity(activity), activity);
});

test("label overrides, hidden labels and fixed text", () => {
  const search: Activity = { phase: "tool", kind: "search" };
  assert.equal(present(search, { labels: { "tool:search": "Buscando" } }).text, "Buscando");
  assert.equal(present(search, { label: "Looking it up" }).text, "Looking it up");
  const hidden = present(search, { label: false });
  assert.equal(hidden.text, "");
  assert.equal(hidden.accessibilityLabel, "Searching");
});

test("palette and scene overrides recolour and force the scene", () => {
  const radar = present({ phase: "tool", kind: "search" }, { palette: { radar: [0, 200, 120] } });
  assert.deepEqual(radar.color, [0, 200, 120]);
  assert.deepEqual(radar.glow, [170, 236, 210]);
  const forced = present({ phase: "thinking" }, { scene: "ember" });
  assert.equal(forced.scene, "ember");
  assert.deepEqual(forced.color, SCENE_COLORS.ember);
  assert.equal(forced.text, "Thinking");
});

test("busy phases read as a progress bar, resting phases as text", () => {
  for (const phase of ["thinking", "tool", "writing", "waiting"] as const) {
    const shown = present({ phase });
    assert.equal(shown.accessibilityRole, "progressbar", phase);
    assert.equal(shown.busy, true, phase);
  }
  for (const phase of ["idle", "done", "error"] as const) {
    const shown = present({ phase });
    assert.equal(shown.accessibilityRole, "text", phase);
    assert.equal(shown.busy, false, phase);
  }
});

test("the shimmer glow is the scene colour two thirds of the way to white", () => {
  assert.deepEqual(glowFor([0, 0, 0]), [170, 170, 170]);
  assert.deepEqual(glowFor([255, 255, 255]), [255, 255, 255]);
});

test("progress alone does not change what is presented", () => {
  const a = present({ phase: "writing", progress: 10 });
  const b = present({ phase: "writing", progress: 400 });
  assert.ok(samePresentation(a, b));
  assert.ok(!samePresentation(a, present({ phase: "done" })));
});
