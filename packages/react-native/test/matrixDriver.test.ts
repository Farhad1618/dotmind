import { test } from "node:test";
import assert from "node:assert/strict";
import { DotRenderer, PATTERNS, SCENE_COLORS } from "dotmind";
import { DotMindController } from "../src/controller.ts";
import { MatrixDriver } from "../src/matrixDriver.ts";
import { loadGolden, RecordingPainter } from "./fakes.ts";

const golden = loadGolden();

test("nothing is drawn until a painter is attached, then the scene appears without a fade", () => {
  const driver = new MatrixDriver();
  driver.show("check", SCENE_COLORS.check, undefined);
  assert.equal(driver.animating, false);
  const painter = new RecordingPainter();
  driver.attach(painter);
  assert.equal(painter.count, 1);
  const expected = new Float32Array(64);
  PATTERNS.check(0, expected, { energy: 0.3, progress: 0 });
  assert.deepEqual([...painter.last], [...expected]);
  assert.deepEqual(painter.colors[0], SCENE_COLORS.check);
});

test("every frame reuses one buffer", () => {
  const driver = new MatrixDriver();
  const painter = new RecordingPainter();
  driver.attach(painter);
  for (let i = 0; i < 30; i++) driver.tick(1 / 60);
  assert.equal(painter.count, 31);
  assert.ok(painter.buffers.every((b) => b === driver.frame));
});

test("frames match a reference renderer stepped the same way", () => {
  const driver = new MatrixDriver();
  const painter = new RecordingPainter();
  driver.attach(painter);
  driver.show("radar", SCENE_COLORS.radar, undefined);
  const reference = new DotRenderer();
  reference.show("radar", SCENE_COLORS.radar, true);
  for (let i = 0; i < 100; i++) {
    driver.tick(1 / 60);
    reference.step(1 / 60);
  }
  assert.deepEqual([...painter.last], [...reference.sample()]);
  assert.equal(driver.level, reference.level);
});

test("the writing scene follows the golden energy curve at every recorded frame", () => {
  const driver = new MatrixDriver();
  const controller = new DotMindController(driver, { phase: "writing", progress: 0 });
  driver.attach(new RecordingPainter());
  const sampled = new Float32Array(64);
  let progress = 0;
  let checked = 0;
  for (let i = 0; i < 240; i++) {
    driver.tick(1 / 60);
    if (i < 120) controller.update({ phase: "writing", progress: (progress += i < 60 ? 1 : 8) });
    const frame = i + 1;
    const expected = golden.energy.find((e) => e.frame === frame);
    if (!expected) continue;
    checked++;
    assert.ok(Math.abs(driver.level - expected.energy) <= golden.tolerance, `energy at ${frame}`);
    driver.sample(sampled).forEach((v, k) => assert.ok(Math.abs(v - expected.values[k]) <= golden.tolerance, `dot ${k} at ${frame}`));
  }
  assert.equal(checked, golden.energy.length);
});

test("a hidden driver stops animating and switches scenes instantly with one paint", () => {
  const driver = new MatrixDriver();
  const painter = new RecordingPainter();
  driver.attach(painter);
  for (let i = 0; i < 10; i++) driver.tick(1 / 60);
  driver.setVisible(false);
  assert.equal(driver.animating, false);
  const before = painter.count;
  driver.tick(1 / 60);
  assert.equal(painter.count, before);
  driver.show("radar", SCENE_COLORS.radar, undefined);
  assert.equal(painter.count, before + 1);
  assert.deepEqual(painter.colors.at(-1), SCENE_COLORS.radar);
  driver.show("radar", SCENE_COLORS.radar, 5);
  assert.equal(painter.count, before + 1);
  const reference = new DotRenderer("radar");
  assert.deepEqual([...painter.last], [...reference.sample()]);
  driver.setVisible(true);
  assert.equal(driver.animating, true);
});

test("a scene change while the app is in the background is instant", () => {
  const driver = new MatrixDriver();
  const painter = new RecordingPainter();
  driver.attach(painter);
  for (let i = 0; i < 10; i++) driver.tick(1 / 60);
  driver.setForeground(false);
  assert.equal(driver.animating, false);
  driver.show("cross", SCENE_COLORS.cross, undefined);
  driver.setForeground(true);
  driver.tick(1 / 60);
  const reference = new DotRenderer("cross");
  reference.step(1 / 60);
  assert.deepEqual([...painter.last], [...reference.sample()]);
  assert.deepEqual(painter.colors.at(-1), SCENE_COLORS.cross);
});

test("reduced motion paints one settled frame per change and never animates", () => {
  const driver = new MatrixDriver();
  const painter = new RecordingPainter();
  driver.attach(painter);
  driver.setStill(true);
  assert.equal(driver.animating, false);
  const afterSettle = painter.count;
  driver.tick(1 / 60);
  assert.equal(painter.count, afterSettle);
  driver.show("cross", SCENE_COLORS.cross, undefined);
  assert.equal(painter.count, afterSettle + 1);
  assert.deepEqual(painter.colors.at(-1), SCENE_COLORS.cross);
  driver.setStill(false);
  assert.equal(driver.animating, true);
});

test("a detached driver stops painting", () => {
  const driver = new MatrixDriver();
  const painter = new RecordingPainter();
  driver.attach(painter);
  driver.detach();
  driver.tick(1 / 60);
  assert.equal(painter.count, 1);
  assert.equal(driver.animating, false);
});
