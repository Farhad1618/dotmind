export type { Activity, AgentEvent, Pattern, PatternContext, Phase, RGB, SceneName, ToolKind } from "./types.ts";
export { ActivityTracker, type ActivityListener, type TrackerOptions } from "./tracker.ts";
export { classifyTool, humanizeTool } from "./tools.ts";
export { DEFAULT_LABELS, labelFor, type LabelMap } from "./labels.ts";
export { sceneFor } from "./scene.ts";
export { GRID, PATTERNS, SCENE_COLORS, SCENE_NAMES } from "./patterns.ts";
export { DotRenderer } from "./renderer.ts";
export { DOTMIND_CSS, injectStyles, mount, type DotMindController, type DotMindOptions } from "./mount.ts";
