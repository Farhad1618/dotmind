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
    borderWidth: 1,
    borderColor: theme.edge,
    backgroundColor: theme.background,
    boxShadow: PILL_SHADOW,
  };
}

export function wellStyle(size: number, theme: DotMindTheme): ViewStyle {
  return { width: size, height: size, borderRadius: size * 0.24, backgroundColor: theme.well, overflow: "hidden", flexShrink: 0 };
}

export function labelHeight(fontSize: number): number {
  return Math.ceil(fontSize * 1.2);
}
