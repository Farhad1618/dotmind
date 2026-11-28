import type { Look, SceneKey, SceneMap, SceneName, Shape } from "./types.ts";

export interface LookDefinition {
  scenes: SceneMap;
  shape: Shape;
  aura: boolean;
}

export const CLASSIC_SCENES: Record<SceneKey, SceneName> = {
  idle: "breathe",
  thinking: "comet",
  writing: "type",
  waiting: "halo",
  error: "cross",
  done: "check",
  "tool:search": "radar",
  "tool:browse": "globe",
  "tool:code": "code",
  "tool:file": "pages",
  "tool:database": "stack",
  "tool:compute": "prism",
  "tool:translate": "glyph",
  "tool:deploy": "rocket",
  "tool:debug": "bug",
  "tool:generic": "circuit",
};

export const LOOKS: Record<Look, LookDefinition> = {
  classic: { scenes: {}, shape: "dot", aura: false },
  icons: {
    scenes: {
      thinking: "neural",
      done: "verified",
      "tool:search": "magnifier",
      "tool:translate": "glyph",
      "tool:compute": "sort",
      "tool:deploy": "rocket",
    },
    shape: "dot",
    aura: true,
  },
  pixel: {
    scenes: {
      "tool:debug": "bug",
      "tool:code": "blocks",
      "tool:search": "scan",
    },
    shape: "square",
    aura: false,
  },
};

export const LOOK_NAMES = Object.keys(LOOKS) as Look[];

export function lookDefinition(look: Look | undefined): LookDefinition {
  return (look && LOOKS[look]) || LOOKS.classic;
}
