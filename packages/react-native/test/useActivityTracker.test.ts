import { test } from "node:test";
import assert from "node:assert/strict";
import { createElement } from "react";
import TestRenderer, { act } from "react-test-renderer";
import { ActivityTracker } from "dotmind";
import { useActivityTracker } from "../src/useActivityTracker.ts";

Object.assign(globalThis, { IS_REACT_ACT_ENVIRONMENT: true, IS_REACT_NATIVE_TEST_ENVIRONMENT: true });

test("the hook keeps one tracker for the life of the component", () => {
  const seen: ActivityTracker[] = [];
  function Probe({ n }: { n: number }) {
    seen.push(useActivityTracker({ tools: { lookup_customer: "database" } }));
    return createElement("probe", { n });
  }
  let root: TestRenderer.ReactTestRenderer | undefined;
  act(() => {
    root = TestRenderer.create(createElement(Probe, { n: 1 }));
  });
  act(() => root!.update(createElement(Probe, { n: 2 })));
  act(() => root!.update(createElement(Probe, { n: 3 })));
  assert.ok(seen.length >= 3);
  assert.ok(seen.every((t) => t === seen[0]));
  assert.ok(seen[0] instanceof ActivityTracker);
  seen[0].push({ type: "tool", name: "lookup_customer", id: "1" });
  assert.equal(seen[0].activity.kind, "database");
  act(() => root!.unmount());
});
