import { test } from "node:test";
import assert from "node:assert/strict";
import { ActivityTracker } from "dotmind";
import { DotMindController } from "../src/controller.ts";
import { MatrixDriver } from "../src/matrixDriver.ts";
import type { Presentation } from "../src/presentation.ts";
import { RecordingPainter } from "./fakes.ts";

function setup(options = {}) {
  const driver = new MatrixDriver();
  const painter = new RecordingPainter();
  driver.attach(painter);
  const controller = new DotMindController(driver, undefined, options);
  const seen: Presentation[] = [];
  controller.subscribe((p) => seen.push(p));
  return { driver, painter, controller, seen };
}

test("a streamed turn notifies once per visible change, not once per delta", () => {
  const { controller, seen, driver } = setup();
  const tracker = new ActivityTracker();
  tracker.subscribe((a) => controller.update(a));
  tracker.push({ type: "start" });
  tracker.push({ type: "thinking", chars: 30 });
  tracker.push({ type: "thinking", chars: 30 });
  tracker.push({ type: "tool", name: "web_search", id: "a" });
  tracker.push({ type: "tool-input", chars: 12 });
  tracker.push({ type: "tool-result", id: "a" });
  for (let i = 0; i < 25; i++) tracker.push({ type: "text", chars: 8 });
  tracker.push({ type: "finish" });
  assert.deepEqual(
    seen.map((p) => p.text),
    ["Thinking", "Searching", "Thinking", "Writing", "Done"],
  );
  assert.equal(driver.scene, "check");
});

test("the snapshot is stable between changes", () => {
  const { controller } = setup();
  const first = controller.snapshot();
  controller.update({ phase: "idle", progress: 5 });
  assert.equal(controller.snapshot(), first);
  controller.update("thinking");
  assert.notEqual(controller.snapshot(), first);
  assert.equal(controller.snapshot().scene, "comet");
});

test("options re-present the current activity", () => {
  const { controller, seen } = setup();
  controller.update({ phase: "tool", tool: "get_weather", kind: "generic" });
  assert.equal(controller.snapshot().text, "Using get weather");
  controller.setOptions({ labels: { "tool:generic": "Working" } });
  assert.equal(controller.snapshot().text, "Working");
  controller.setOptions({ label: false });
  assert.equal(controller.snapshot().text, "");
  assert.equal(controller.snapshot().accessibilityLabel, "Using get weather");
  controller.setOptions({ scene: "orbit" });
  assert.equal(controller.driver.scene, "orbit");
  assert.equal(seen.length, 4);
});

test("unsubscribed listeners stop hearing updates", () => {
  const { controller } = setup();
  let calls = 0;
  const stop = controller.subscribe(() => calls++);
  controller.update("thinking");
  stop();
  controller.update("done");
  assert.equal(calls, 1);
});

test("progress reaches the renderer even though React is not told", () => {
  const { controller, driver, seen } = setup();
  let progress = 0;
  controller.update({ phase: "writing", progress });
  const before = seen.length;
  for (let i = 0; i < 90; i++) {
    driver.tick(1 / 60);
    controller.update({ phase: "writing", progress: (progress += 12) });
  }
  assert.equal(seen.length, before);
  assert.ok(driver.level > 0.6, `energy rose with the token rate: ${driver.level}`);
});
