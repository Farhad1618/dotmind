import { CLASSIC_SCENES, lookDefinition } from "./looks.ts";
import type { Activity, Look, SceneKey, SceneMap, SceneName } from "./types.ts";

export function sceneKey(activity: Activity): SceneKey {
  return activity.phase === "tool" ? `tool:${activity.kind ?? "generic"}` : activity.phase;
}

export function sceneFor(activity: Activity, look: Look = "classic", overrides?: SceneMap): SceneName {
  const key = sceneKey(activity);
  return overrides?.[key] ?? lookDefinition(look).scenes[key] ?? CLASSIC_SCENES[key];
}
