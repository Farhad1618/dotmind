import { test } from "node:test";
import assert from "node:assert/strict";
import { ActivityTracker } from "../src/tracker.ts";
import { classifyTool } from "../src/tools.ts";
import { labelFor } from "../src/labels.ts";
import { sceneFor } from "../src/scene.ts";
import { PATTERNS, SCENE_NAMES } from "../src/patterns.ts";
import { DotRenderer } from "../src/renderer.ts";

test("tool names map to the kind of work they do", () => {
  const cases: Record<string, string> = {
    web_search: "search",
    file_search: "search",
    searchDocs: "search",
    run_sql: "database",
    query_clickhouse: "database",
    web_fetch: "browse",
    navigate: "browse",
    bash: "code",
    code_interpreter: "code",
    str_replace_based_edit_tool: "file",
    read_file: "file",
    calculate_margin: "compute",
    get_weather: "generic",
  };
  for (const [name, kind] of Object.entries(cases)) assert.equal(classifyTool(name), kind, name);
  assert.equal(classifyTool("get_weather", { get_weather: "browse" }), "browse");
});

test("labels follow the activity", () => {
  assert.equal(labelFor({ phase: "thinking" }), "Thinking");
  assert.equal(labelFor({ phase: "tool", kind: "search" }), "Searching");
  assert.equal(labelFor({ phase: "tool", tool: "get_weather", kind: "generic" }), "Using get weather");
  assert.equal(labelFor({ phase: "tool", kind: "search" }, { "tool:search": "Buscando" }), "Buscando");
  assert.equal(labelFor({ phase: "writing", label: "Drafting reply" }), "Drafting reply");
});

test("each phase picks a scene", () => {
  assert.equal(sceneFor({ phase: "thinking" }), "comet");
  assert.equal(sceneFor({ phase: "tool", kind: "search" }), "radar");
  assert.equal(sceneFor({ phase: "tool", kind: "database" }), "stack");
  assert.equal(sceneFor({ phase: "writing" }), "type");
  assert.equal(sceneFor({ phase: "done" }), "check");
});

test("every pattern fills 64 finite values in range", () => {
  const out = new Float32Array(64);
  for (const name of SCENE_NAMES) {
    for (const t of [0, 0.3, 1.7, 12.5, 400]) {
      PATTERNS[name](t, out, { energy: 0.8, progress: 137 });
      for (const v of out) assert.ok(Number.isFinite(v) && v >= 0 && v <= 1.6, `${name}@${t}: ${v}`);
    }
  }
});

test("the writing scene lights more dots as text arrives", () => {
  const lit = (progress: number) => {
    const out = new Float32Array(64);
    PATTERNS.type(0.1, out, { energy: 0.5, progress });
    return out.filter((v) => v > 0.3).length;
  };
  assert.ok(lit(0) < lit(40));
  assert.ok(lit(40) < lit(120));
});

test("the tracker follows a tool-using turn", () => {
  const t = new ActivityTracker();
  const phases: string[] = [];
  t.subscribe((a) => phases.push(a.phase === "tool" ? `tool:${a.kind}` : a.phase));
  t.pushAll([
    { type: "start" },
    { type: "thinking", chars: 120 },
    { type: "tool", name: "web_search", id: "a" },
    { type: "tool-result", id: "a" },
    { type: "text", chars: 40 },
    { type: "text", chars: 40 },
    { type: "finish" },
  ]);
  assert.deepEqual([...new Set(phases)], ["idle", "thinking", "tool:search", "writing", "done"]);
  assert.equal(t.activity.progress, 200);
});

test("a turn that stops to run a client tool stays on that tool", () => {
  const t = new ActivityTracker();
  t.pushAll([{ type: "start" }, { type: "tool", name: "run_sql", id: "x" }, { type: "finish", pendingTools: true }]);
  assert.equal(t.activity.phase, "tool");
  assert.equal(t.activity.kind, "database");
});

test("faster text makes the renderer livelier", () => {
  const r = new DotRenderer("type");
  let p = 0;
  r.feed(p);
  for (let i = 0; i < 60; i++) {
    r.step(1 / 60);
    r.feed((p += 1));
  }
  const slow = r.level;
  for (let i = 0; i < 60; i++) {
    r.step(1 / 60);
    r.feed((p += 8));
  }
  assert.ok(r.level > slow, `${r.level} > ${slow}`);
  for (let i = 0; i < 180; i++) r.step(1 / 60);
  assert.ok(r.level < 0.5, `calms down when text stops: ${r.level}`);
});

test("switching scenes cross-fades instead of cutting", () => {
  const r = new DotRenderer("check");
  r.step(2);
  const before = r.sample().slice();
  r.show("cross");
  r.step(0.1);
  const mid = r.sample();
  const target = new Float32Array(64);
  PATTERNS.cross(0.1 * (0.6 + 0.6 * r.level), target, { energy: r.level, progress: 0 });
  const differsFromBoth = [...mid].some((v, i) => Math.abs(v - before[i]) > 0.05 && Math.abs(v - target[i]) > 0.05);
  assert.ok(differsFromBoth);
});
