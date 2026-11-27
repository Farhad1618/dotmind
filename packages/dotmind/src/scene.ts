import type { Activity, SceneName, ToolKind } from "./types.ts";

const TOOL_SCENES: Record<ToolKind, SceneName> = {
  search: "radar",
  browse: "globe",
  code: "code",
  file: "pages",
  database: "stack",
  compute: "prism",
  generic: "circuit",
};

export function sceneFor(activity: Activity): SceneName {
  switch (activity.phase) {
    case "idle":
      return "breathe";
    case "thinking":
      return "comet";
    case "tool":
      return TOOL_SCENES[activity.kind ?? "generic"];
    case "writing":
      return "type";
    case "waiting":
      return "halo";
    case "error":
      return "cross";
    case "done":
      return "check";
  }
}
