import { LOOKS, type DotMindOptions, type Look, type LookDefinition, type Shape } from "dotmind";

export interface LookStyle {
  readonly shape: Shape;
  readonly aura: boolean;
}

export function knownLook(look: DotMindOptions["look"]): Look {
  return look !== undefined && Object.hasOwn(LOOKS, look) ? look : "classic";
}

export function lookDefinition(look: DotMindOptions["look"]): LookDefinition {
  return LOOKS[knownLook(look)];
}

export function lookStyle(options: Pick<DotMindOptions, "look" | "shape" | "aura">): LookStyle {
  const look = lookDefinition(options.look);
  return { shape: options.shape ?? look.shape, aura: options.aura ?? look.aura };
}
