export type {
  Activity,
  AgentEvent,
  ClassicScene,
  DotMindOptions,
  IconScene,
  Look,
  Pattern,
  PatternContext,
  Phase,
  PixelScene,
  RGB,
  SceneKey,
  SceneMap,
  SceneName,
  Shape,
  ToolKind,
} from "./types.ts";
export { ActivityTracker, type ActivityListener, type TrackerOptions } from "./tracker.ts";
export { classifyTool, humanizeTool } from "./tools.ts";
export { DEFAULT_LABELS, labelFor, type LabelMap } from "./labels.ts";
export { sceneFor, sceneKey } from "./scene.ts";
export { CLASSIC_SCENES, LOOK_NAMES, LOOKS, type LookDefinition } from "./looks.ts";
export { SHAPES, type ShapeGeometry } from "./shapes.ts";
export { GRID, PATTERNS, SCENE_COLORS, SCENE_NAMES } from "./patterns.ts";
export { DotRenderer } from "./renderer.ts";
