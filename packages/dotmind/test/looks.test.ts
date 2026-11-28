import { test } from "node:test";
import assert from "node:assert/strict";
import { classifyTool } from "../src/tools.ts";
import { labelFor } from "../src/labels.ts";
import { sceneFor, sceneKey } from "../src/scene.ts";
import { CLASSIC_SCENES, LOOKS, LOOK_NAMES } from "../src/looks.ts";
import { PATTERNS, SCENE_COLORS, SCENE_NAMES } from "../src/patterns.ts";
import { SHAPES, traceCell } from "../src/shapes.ts";
import { drawMatrix } from "../src/mount.ts";
import { DotRenderer } from "../src/renderer.ts";
import type { Activity, SceneName } from "../src/types.ts";

const NEW_SCENES: SceneName[] = ["neural", "magnifier", "glyph", "sort", "rocket", "verified", "bug", "blocks", "scan"];

test("new tool kinds are recognised without changing older ones", () => {
  const cases: Record<string, string> = {
    translate_text: "translate",
    localizeStrings: "translate",
    i18n_sync: "translate",
    set_locale: "translate",
    deploy_service: "deploy",
    kubectl_apply: "deploy",
    helm_upgrade: "deploy",
    publish_release: "deploy",
    rollout_canary: "deploy",
    debugger_step: "debug",
    set_breakpoint: "debug",
    parse_traceback: "debug",
    inspect_element: "debug",
    inspect_page: "browse",
    i18n_lookup: "search",
    run_deploy_script: "code",
    get_weather: "generic",
  };
  for (const [name, kind] of Object.entries(cases)) assert.equal(classifyTool(name), kind, name);
});

test("new kinds have default labels", () => {
  assert.equal(labelFor({ phase: "tool", kind: "translate" }), "Translating");
  assert.equal(labelFor({ phase: "tool", kind: "deploy" }), "Deploying");
  assert.equal(labelFor({ phase: "tool", kind: "debug" }), "Debugging");
});

test("every new pattern fills 64 finite values in range and changes over time", () => {
  const out = new Float32Array(64);
  for (const name of NEW_SCENES) {
    assert.ok(SCENE_NAMES.includes(name), name);
    assert.equal(SCENE_COLORS[name].length, 3);
    const seen = new Set<string>();
    let lit = 0;
    for (const t of [0, 0.3, 0.5, 1.7, 2.9, 4.1, 12.5, 400]) {
      for (const progress of [0, 137]) {
        PATTERNS[name](t, out, { energy: 0.8, progress });
        for (const v of out) assert.ok(Number.isFinite(v) && v >= 0 && v <= 1.5, `${name}@${t}: ${v}`);
        if (out.some((v) => v > 0.5)) lit++;
        seen.add([...out].map((v) => v.toFixed(2)).join());
      }
    }
    assert.ok(seen.size > 3, `${name} animates`);
    assert.ok(lit >= 12, `${name} lights something most of the time: ${lit}`);
  }
});

test("new patterns are deterministic", () => {
  const a = new Float32Array(64);
  const b = new Float32Array(64);
  for (const name of NEW_SCENES) {
    PATTERNS[name](7.77, a, { energy: 0.8, progress: 0 });
    PATTERNS[name](7.77, b, { energy: 0.8, progress: 0 });
    assert.deepEqual([...a], [...b], name);
  }
});

test("the sort scene ends on an ascending staircase", () => {
  const out = new Float32Array(64);
  PATTERNS.sort(0.16 * 38 + 0.05, out, { energy: 0.8, progress: 0 });
  const heights = Array.from({ length: 8 }, (_, x) => Array.from({ length: 8 }, (_, y) => out[y * 8 + x]).filter((v) => v > 0).length);
  assert.deepEqual(heights, [1, 2, 3, 4, 5, 6, 7, 8]);
});

test("sceneKey names the state", () => {
  assert.equal(sceneKey({ phase: "thinking" }), "thinking");
  assert.equal(sceneKey({ phase: "tool" }), "tool:generic");
  assert.equal(sceneKey({ phase: "tool", kind: "debug" }), "tool:debug");
});

test("looks map states to scenes", () => {
  const tool = (kind: Activity["kind"]): Activity => ({ phase: "tool", kind });
  assert.equal(sceneFor({ phase: "thinking" }), "comet");
  assert.equal(sceneFor(tool("translate")), "glyph");
  assert.equal(sceneFor(tool("deploy")), "rocket");
  assert.equal(sceneFor(tool("debug")), "bug");

  assert.equal(sceneFor({ phase: "thinking" }, "icons"), "neural");
  assert.equal(sceneFor(tool("search"), "icons"), "magnifier");
  assert.equal(sceneFor(tool("translate"), "icons"), "glyph");
  assert.equal(sceneFor(tool("compute"), "icons"), "sort");
  assert.equal(sceneFor(tool("deploy"), "icons"), "rocket");
  assert.equal(sceneFor({ phase: "done" }, "icons"), "verified");
  assert.equal(sceneFor({ phase: "writing" }, "icons"), "type");
  assert.equal(sceneFor(tool("database"), "icons"), "stack");

  assert.equal(sceneFor(tool("debug"), "pixel"), "bug");
  assert.equal(sceneFor(tool("code"), "pixel"), "blocks");
  assert.equal(sceneFor(tool("search"), "pixel"), "scan");
  assert.equal(sceneFor({ phase: "thinking" }, "pixel"), "comet");
});

test("every look covers every state with a real scene", () => {
  for (const look of LOOK_NAMES) {
    for (const key of Object.keys(CLASSIC_SCENES) as (keyof typeof CLASSIC_SCENES)[]) {
      const activity: Activity = key.startsWith("tool:")
        ? { phase: "tool", kind: key.slice(5) as Activity["kind"] }
        : { phase: key as Activity["phase"] };
      assert.ok(SCENE_NAMES.includes(sceneFor(activity, look)), `${look} ${key}`);
    }
  }
  assert.equal(LOOKS.pixel.shape, "square");
  assert.equal(LOOKS.icons.shape, "dot");
  assert.equal(LOOKS.icons.aura, true);
  assert.equal(LOOKS.classic.aura, false);
});

test("scene overrides beat the look table", () => {
  assert.equal(sceneFor({ phase: "thinking" }, "icons", { thinking: "ember" }), "ember");
  assert.equal(sceneFor({ phase: "tool", kind: "search" }, "pixel", { "tool:search": "magnifier" }), "magnifier");
  assert.equal(sceneFor({ phase: "tool", kind: "file" }, "classic", { "tool:file": "sort" }), "sort");
  assert.equal(sceneFor({ phase: "tool", kind: "search" }, "pixel", { thinking: "ember" }), "scan");
  assert.equal(sceneFor({ phase: "thinking" }, "nope" as never), "comet");
});

test("shape geometry matches the spec", () => {
  assert.deepEqual(SHAPES.dot, { size: 0.68, corner: 0.5, base: 0.14 });
  assert.deepEqual(SHAPES.square, { size: 0.8, corner: 0.22, base: 0.2 });
});

function recordingContext() {
  const calls: string[] = [];
  const fills: string[] = [];
  const ctx = {
    fillStyle: "",
    shadowColor: "",
    shadowBlur: 0,
    clearRect: () => calls.push("clear"),
    beginPath: () => calls.push("begin"),
    moveTo: () => calls.push("move"),
    arc: () => calls.push("arc"),
    arcTo: () => calls.push("arcTo"),
    closePath: () => calls.push("close"),
    fill() {
      fills.push(String(this.fillStyle));
    },
  };
  return { ctx: ctx as unknown as CanvasRenderingContext2D, calls, fills };
}

test("drawMatrix draws dots as arcs and squares as rounded rectangles", () => {
  for (const shape of ["dot", "square"] as const) {
    const { ctx, calls, fills } = recordingContext();
    const r = new DotRenderer("verified");
    r.step(1);
    drawMatrix(r, ctx, 56, new Float32Array(64), [0, 0, 0], undefined, shape);
    assert.ok(fills.length > 1, `${shape} draws lit cells`);
    assert.ok(fills[0].endsWith(`,${SHAPES[shape].base})`), fills[0]);
    if (shape === "dot") assert.equal(calls.filter((c) => c === "arcTo").length, 0);
    else assert.ok(calls.filter((c) => c === "arcTo").length >= 64 * 4);
  }
  const { ctx, calls } = recordingContext();
  traceCell(ctx, 10, 10, 4, "square");
  assert.deepEqual(calls, ["move", "arcTo", "arcTo", "arcTo", "arcTo", "close"]);
});
