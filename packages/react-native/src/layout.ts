import type { RGB, Shape } from "dotmind";
import type { ViewStyle } from "react-native";
import type { DotMindTheme } from "./theme.ts";

export type Variant = "pill" | "bare";

const PILL_SHADOW = "0px 10px 30px -14px rgba(0,0,0,0.8), inset 0px 1px 0px rgba(255,255,255,0.04)";

export function containerStyle(variant: Variant, theme: DotMindTheme, fontSize: number): ViewStyle {
  const row: ViewStyle = { flexDirection: "row", alignItems: "center", alignSelf: "flex-start", gap: fontSize * 0.6, maxWidth: "100%" };
  if (variant === "bare") return row;
  const inset = fontSize * 0.35;
  return {
    ...row,
    paddingTop: inset,
    paddingBottom: inset,
    paddingLeft: inset,
    paddingRight: fontSize * 1.15,
    borderRadius: 999,
    borderWidth: PILL_EDGE,
    borderColor: theme.edge,
    backgroundColor: theme.background,
    boxShadow: PILL_SHADOW,
  };
}

export const WELL_CORNER: Record<Shape, number> = { dot: 0.24, square: 0.14 };

export const PILL_EDGE = 1;

export function wellRadius(size: number, shape: Shape): number {
  return size * (shape === "square" ? WELL_CORNER.square : WELL_CORNER.dot);
}

export function wellStyle(size: number, theme: DotMindTheme, shape: Shape = "dot"): ViewStyle {
  return {
    width: size,
    height: size,
    borderRadius: wellRadius(size, shape),
    backgroundColor: theme.well,
    overflow: "hidden",
    flexShrink: 0,
  };
}

export function wellFrameStyle(size: number): ViewStyle {
  return { width: size, height: size, flexShrink: 0 };
}

function rgba(color: RGB, alpha: number): string {
  return `rgba(${color[0] | 0},${color[1] | 0},${color[2] | 0},${alpha})`;
}

export function auraShadow(variant: Variant, color: RGB, theme: DotMindTheme): string {
  if (variant === "bare") return `0px 0px 18px 2px ${rgba(color, theme.auraNear)}`;
  return `0px 0px 24px -6px ${rgba(color, theme.auraNear)}, 0px 0px 72px 8px ${rgba(color, theme.auraFar)}`;
}

export function auraLayerStyle(variant: Variant, size: number, shape: Shape): ViewStyle {
  if (variant === "bare") return { position: "absolute", top: 0, left: 0, right: 0, bottom: 0, borderRadius: wellRadius(size, shape) };
  return { position: "absolute", top: -PILL_EDGE, left: -PILL_EDGE, right: -PILL_EDGE, bottom: -PILL_EDGE, borderRadius: 999 };
}

export function labelHeight(fontSize: number): number {
  return Math.ceil(fontSize * 1.2);
}
