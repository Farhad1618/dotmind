import { test } from "node:test";
import assert from "node:assert/strict";
import { FrameLoop, type FrameClient } from "../src/frameLoop.ts";
import { createAppStateGate, isForeground, type AppStatus } from "../src/appLifecycle.ts";
import { ManualScheduler } from "./fakes.ts";

class Client implements FrameClient {
  animating = true;
  foreground: boolean | null = null;
  readonly steps: number[] = [];
  tick(dt: number): void {
    this.steps.push(dt);
  }
  setForeground(foreground: boolean): void {
    this.foreground = foreground;
  }
}

test("one frame drives every animating client with a capped step", () => {
  const scheduler = new ManualScheduler();
  const loop = new FrameLoop(scheduler);
  const a = new Client();
  const b = new Client();
  loop.add(a);
  loop.add(b);
  assert.equal(scheduler.pending.size, 1);
  scheduler.flush(1000);
  scheduler.flush(1016);
  scheduler.flush(1500);
  assert.deepEqual(a.steps, [0, 0.016, 0.05]);
  assert.deepEqual(b.steps, a.steps);
});

test("the loop sleeps when nothing animates and wakes on demand", () => {
  const scheduler = new ManualScheduler();
  const loop = new FrameLoop(scheduler);
  const client = new Client();
  loop.add(client);
  client.animating = false;
  scheduler.flush(0);
  assert.equal(loop.running, false);
  client.animating = true;
  loop.wake();
  assert.equal(loop.running, true);
  scheduler.flush(5000);
  assert.deepEqual(client.steps, [0]);
});

test("pausing cancels the pending frame and resuming restarts the clock", () => {
  const scheduler = new ManualScheduler();
  const loop = new FrameLoop(scheduler);
  const client = new Client();
  loop.add(client);
  scheduler.flush(0);
  scheduler.flush(16);
  loop.setActive(false);
  assert.equal(scheduler.pending.size, 0);
  loop.wake();
  assert.equal(scheduler.pending.size, 0);
  loop.setActive(true);
  scheduler.flush(60000);
  assert.equal(client.steps.at(-1), 0);
});

test("clients learn whether the app is in the foreground, including late joiners", () => {
  const loop = new FrameLoop(new ManualScheduler());
  const early = new Client();
  loop.add(early);
  assert.equal(early.foreground, true);
  loop.setActive(false);
  assert.equal(early.foreground, false);
  const late = new Client();
  loop.add(late);
  assert.equal(late.foreground, false);
  loop.setActive(true);
  assert.equal(early.foreground, true);
  assert.equal(late.foreground, true);
});

test("removing the last client stops the loop", () => {
  const scheduler = new ManualScheduler();
  const loop = new FrameLoop(scheduler);
  const leave = loop.add(new Client());
  leave();
  assert.equal(loop.size, 0);
  assert.equal(scheduler.pending.size, 0);
});

test("only background and inactive count as away", () => {
  assert.equal(isForeground("active"), true);
  assert.equal(isForeground("unknown"), true);
  assert.equal(isForeground(null), true);
  assert.equal(isForeground("background"), false);
  assert.equal(isForeground("inactive"), false);
});

test("the app state gate shares one subscription and pauses the loop in the background", () => {
  let listener: ((status: AppStatus | string) => void) | null = null;
  let subscriptions = 0;
  const source = {
    currentState: "active" as AppStatus,
    addEventListener(_type: "change", next: (status: AppStatus | string) => void) {
      subscriptions++;
      listener = next;
      return { remove: () => (listener = null) };
    },
  };
  const states: boolean[] = [];
  const hold = createAppStateGate(source, { setActive: (active) => states.push(active) });
  const first = hold();
  const second = hold();
  assert.equal(subscriptions, 1);
  listener!("background");
  listener!("active");
  first();
  first();
  assert.notEqual(listener, null);
  second();
  assert.equal(listener, null);
  assert.deepEqual(states, [true, false, true, true]);
});
