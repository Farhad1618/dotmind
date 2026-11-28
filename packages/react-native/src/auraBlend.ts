import type { RGB } from "dotmind";

export const AURA_SECONDS = 0.35;

export const AURA_EASING = [0.25, 0.1, 0.25, 1] as const;

export interface AuraLayer {
  readonly color: RGB;
  readonly opacity: number;
}

export interface AuraBlend {
  readonly layers: readonly [AuraLayer, AuraLayer];
  readonly active: 0 | 1;
}

const sameColor = (a: RGB, b: RGB) => a[0] === b[0] && a[1] === b[1] && a[2] === b[2];

export function startAura(color: RGB, on: boolean): AuraBlend {
  return { layers: [{ color, opacity: on ? 1 : 0 }, { color, opacity: 0 }], active: 0 };
}

export function blendAura(blend: AuraBlend, color: RGB, on: boolean): AuraBlend {
  const lit = on ? 1 : 0;
  const current = blend.layers[blend.active];
  const other = blend.layers[blend.active === 0 ? 1 : 0];
  if (sameColor(current.color, color)) {
    if (current.opacity === lit && other.opacity === 0) return blend;
    return blend.active === 0
      ? { layers: [{ color: current.color, opacity: lit }, { color: other.color, opacity: 0 }], active: 0 }
      : { layers: [{ color: other.color, opacity: 0 }, { color: current.color, opacity: lit }], active: 1 };
  }
  return blend.active === 0
    ? { layers: [{ color: current.color, opacity: 0 }, { color, opacity: lit }], active: 1 }
    : { layers: [{ color, opacity: lit }, { color: current.color, opacity: 0 }], active: 0 };
}
