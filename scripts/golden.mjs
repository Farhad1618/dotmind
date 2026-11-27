import { writeFile } from "node:fs/promises";
import { PATTERNS, SCENE_NAMES, classifyTool, sceneFor, labelFor, DotRenderer } from "../packages/dotmind/dist/index.js";

const round = (v) => Math.round(v * 10000) / 10000;

const frames = [];
for (const scene of SCENE_NAMES) {
  for (const t of [0, 0.5, 1.7, 12.5]) {
    for (const progress of [0, 137]) {
      const out = new Float32Array(64);
      PATTERNS[scene](t, out, { energy: 0.8, progress });
      frames.push({ scene, t, progress, energy: 0.8, values: [...out].map(round) });
    }
  }
}

const toolNames = [
  "web_search", "file_search", "searchDocs", "grep", "run_sql", "query_clickhouse", "web_fetch", "navigate",
  "computer", "bash", "code_interpreter", "str_replace_based_edit_tool", "read_file", "text_editor",
  "calculate_margin", "plot_chart", "get_weather", "lookupCustomer", "",
];
const tools = toolNames.map((name) => ({ name, kind: classifyTool(name) }));

const activities = [
  { phase: "idle" }, { phase: "thinking" }, { phase: "writing" }, { phase: "waiting", tool: "deploy_config", kind: "generic" },
  { phase: "error" }, { phase: "done" },
  ...["search", "browse", "code", "file", "database", "compute", "generic"].map((kind) => ({ phase: "tool", kind })),
  { phase: "tool", tool: "get_weather", kind: "generic" },
];
const scenes = activities.map((activity) => ({ activity, scene: sceneFor(activity), label: labelFor(activity) }));

const r = new DotRenderer("type");
const energy = [];
let p = 0;
r.feed(p);
for (let i = 0; i < 240; i++) {
  r.step(1 / 60);
  if (i < 120) r.feed((p += i < 60 ? 1 : 8));
  if (i % 20 === 19) energy.push({ frame: i + 1, energy: round(r.level), values: [...r.sample()].map(round) });
}

await writeFile(
  new URL("../spec/golden.json", import.meta.url),
  JSON.stringify({ tolerance: 0.002, frames, tools, scenes, energy }, null, 0) + "\n",
);
console.log(`frames=${frames.length} tools=${tools.length} scenes=${scenes.length} energy=${energy.length}`);
