import { labelFor, sceneFor, SCENE_COLORS, type Activity, type DotMindOptions, type Phase, type RGB, type SceneName } from "dotmind";
import { knownLook } from "./lookStyle.ts";

export type AccessibilityRoleName = "progressbar" | "text";

export interface Presentation {
  readonly phase: Phase;
  readonly scene: SceneName;
  readonly color: RGB;
  readonly glow: RGB;
  readonly text: string;
  readonly accessibilityLabel: string;
  readonly accessibilityRole: AccessibilityRoleName;
  readonly busy: boolean;
}

export type PresentationOptions = Pick<DotMindOptions, "label" | "labels" | "palette" | "scene" | "look" | "scenes">;

const RESTING: ReadonlySet<Phase> = new Set<Phase>(["idle", "done", "error"]);

export function toActivity(activity: Activity | Phase | undefined): Activity {
  if (activity === undefined) return { phase: "idle" };
  return typeof activity === "string" ? { phase: activity } : activity;
}

export function glowFor(color: RGB): RGB {
  return [((color[0] + 510) / 3) | 0, ((color[1] + 510) / 3) | 0, ((color[2] + 510) / 3) | 0];
}

export function present(activity: Activity, options: PresentationOptions = {}): Presentation {
  const scene = options.scene ?? sceneFor(activity, knownLook(options.look), options.scenes);
  const color = options.palette?.[scene] ?? SCENE_COLORS[scene];
  const derived = labelFor(activity, options.labels);
  const text = options.label === false ? "" : options.label ?? derived;
  const busy = !RESTING.has(activity.phase);
  return {
    phase: activity.phase,
    scene,
    color,
    glow: glowFor(color),
    text,
    accessibilityLabel: text || derived,
    accessibilityRole: busy ? "progressbar" : "text",
    busy,
  };
}

export function samePresentation(a: Presentation, b: Presentation): boolean {
  return (
    a.phase === b.phase &&
    a.scene === b.scene &&
    a.text === b.text &&
    a.accessibilityLabel === b.accessibilityLabel &&
    a.color[0] === b.color[0] &&
    a.color[1] === b.color[1] &&
    a.color[2] === b.color[2]
  );
}
