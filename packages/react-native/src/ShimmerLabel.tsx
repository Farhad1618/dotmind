import { Canvas, LinearGradient, matchFont, Text } from "@shopify/react-native-skia";
import type { RGB } from "dotmind";
import { useCallback, useEffect, useMemo, useState } from "react";
import { View, type LayoutChangeEvent, type ViewStyle } from "react-native";
import {
  cancelAnimation,
  Easing,
  useAnimatedReaction,
  useSharedValue,
  withRepeat,
  withTiming,
} from "react-native-reanimated";
import { ellipsize } from "./ellipsize.ts";
import { labelHeight } from "./layout.ts";
import {
  SHIMMER_FROM,
  SHIMMER_REST,
  SHIMMER_STILL,
  SHIMMER_STOPS,
  SHIMMER_TO,
  shimmerPoint,
  type Point,
  type ShimmerMode,
} from "./shimmer.ts";
import { advanceWidth, centeredBaseline } from "./textMetrics.ts";
import type { DotMindTheme } from "./theme.ts";

export interface ShimmerLabelProps {
  text: string;
  mode: ShimmerMode;
  glow: RGB;
  theme: DotMindTheme;
  fontSize: number;
}

const rgb = (color: RGB) => `rgb(${color[0]},${color[1]},${color[2]})`;

export function ShimmerLabel({ text, mode, glow, theme, fontSize }: ShimmerLabelProps) {
  const font = useMemo(() => matchFont({ fontFamily: theme.fontFamily, fontSize, fontWeight: "500" }), [theme.fontFamily, fontSize]);
  const full = useMemo(() => advanceWidth(font, text), [font, text]);
  const [available, setAvailable] = useState(Number.POSITIVE_INFINITY);
  const fits = available + 0.5 >= full;
  const width = fits ? full : Math.max(0, Math.floor(available));
  const shown = useMemo(
    () => (fits ? text : ellipsize(text, width, (part) => advanceWidth(font, part))),
    [fits, text, width, font],
  );
  const height = labelHeight(fontSize);
  const baseline = useMemo(() => centeredBaseline(font, height), [font, height]);
  const colors = useMemo(
    () => [theme.ink, theme.ink, theme.peak, rgb(glow), theme.ink, theme.ink],
    [theme.ink, theme.peak, glow[0], glow[1], glow[2]],
  );
  const frame = useMemo<ViewStyle>(() => ({ width: full, height, flexShrink: 1, minWidth: 0, overflow: "hidden" }), [full, height]);
  const size = useMemo(() => ({ width, height }), [width, height]);
  const onLayout = useCallback((event: LayoutChangeEvent) => setAvailable(event.nativeEvent.layout.width), []);
  const position = useSharedValue(mode === "rest" ? SHIMMER_REST : SHIMMER_STILL);
  const start = useSharedValue<Point>({ x: 0, y: 0 });
  const end = useSharedValue<Point>({ x: 0, y: 0 });

  useEffect(() => {
    cancelAnimation(position);
    if (mode !== "sweep") {
      position.value = mode === "rest" ? SHIMMER_REST : SHIMMER_STILL;
      return;
    }
    position.value = SHIMMER_FROM;
    position.value = withRepeat(withTiming(SHIMMER_TO, { duration: theme.shimmerSeconds * 1000, easing: Easing.linear }), -1, false);
    return () => cancelAnimation(position);
  }, [mode, theme.shimmerSeconds, position]);

  useAnimatedReaction(
    () => position.value,
    (at) => {
      start.modify((point) => {
        "worklet";
        return shimmerPoint(at, width, height, -1, point);
      }, true);
      end.modify((point) => {
        "worklet";
        return shimmerPoint(at, width, height, 1, point);
      }, true);
    },
  );

  return (
    <View style={frame} onLayout={onLayout}>
      <Canvas style={size}>
        <Text x={0} y={baseline} text={shown} font={font}>
          <LinearGradient start={start} end={end} colors={colors} positions={SHIMMER_STOPS} />
        </Text>
      </Canvas>
    </View>
  );
}
