import { writeFile } from "node:fs/promises";
import { resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { PATTERNS, SCENE_NAMES, LOOK_NAMES, classifyTool, sceneFor, labelFor, DotRenderer } from "../packages/dotmind/dist/index.js";

const target = process.argv[2] ? resolve(process.argv[2]) : fileURLToPath(new URL("../spec/golden.json", import.meta.url));

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
  "translate_text", "localizeStrings", "i18n_sync", "deploy_service", "kubectl_apply", "helm_upgrade", "publish_release",
  "shipIt", "debugger_step", "set_breakpoint", "parse_traceback", "inspect_element", "inspect_page", "i18n_lookup",
];
const tools = toolNames.map((name) => ({ name, kind: classifyTool(name) }));

const activities = [
  { phase: "idle" }, { phase: "thinking" }, { phase: "writing" }, { phase: "waiting", tool: "deploy_config", kind: "generic" },
  { phase: "error" }, { phase: "done" },
  ...["search", "browse", "code", "file", "database", "compute", "generic"].map((kind) => ({ phase: "tool", kind })),
  { phase: "tool", tool: "get_weather", kind: "generic" },
  ...["translate", "deploy", "debug"].map((kind) => ({ phase: "tool", kind })),
];
const scenes = activities.map((activity) => ({ activity, scene: sceneFor(activity), label: labelFor(activity) }));

const lookActivities = [
  { phase: "idle" }, { phase: "thinking" }, { phase: "writing" }, { phase: "waiting" }, { phase: "error" }, { phase: "done" },
  ...["search", "browse", "code", "file", "database", "compute", "translate", "deploy", "debug", "generic"].map((kind) => ({ phase: "tool", kind })),
];
const looks = LOOK_NAMES.flatMap((look) =>
  lookActivities.map((activity) => ({ activity, look, scene: sceneFor(activity, look), label: labelFor(activity) })),
);

const r = new DotRenderer("type");
const energy = [];
let p = 0;
r.feed(p);
for (let i = 0; i < 240; i++) {
  r.step(1 / 60);
  if (i < 120) r.feed((p += i < 60 ? 1 : 8));
  if (i % 20 === 19) energy.push({ frame: i + 1, energy: round(r.level), values: [...r.sample()].map(round) });
}

await writeFile(target, JSON.stringify({ tolerance: 0.002, frames, tools, scenes, looks, energy }, null, 0) + "\n");
console.log(`${target}: frames=${frames.length} tools=${tools.length} scenes=${scenes.length} looks=${looks.length} energy=${energy.length}`);
