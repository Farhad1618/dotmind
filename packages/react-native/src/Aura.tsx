import type { RGB, Shape } from "dotmind";
import { useEffect, useMemo, useState } from "react";
import type { ViewStyle } from "react-native";
import Animated, { Easing, useAnimatedStyle, useSharedValue, withTiming } from "react-native-reanimated";
import { AURA_EASING, AURA_SECONDS, blendAura, startAura, type AuraLayer } from "./auraBlend.ts";
import { auraLayerStyle, auraShadow, type Variant } from "./layout.ts";
import type { DotMindTheme } from "./theme.ts";

const TIMING = { duration: AURA_SECONDS * 1000, easing: Easing.bezier(...AURA_EASING) };

export interface AuraProps {
  color: RGB;
  on: boolean;
  variant: Variant;
  size: number;
  shape: Shape;
  still: boolean;
  theme: DotMindTheme;
}

interface AuraLayerViewProps {
  layer: AuraLayer;
  frame: ViewStyle;
  variant: Variant;
  still: boolean;
  theme: DotMindTheme;
}

function AuraLayerView({ layer, frame, variant, still, theme }: AuraLayerViewProps) {
  const opacity = useSharedValue(layer.opacity);
  const [red, green, blue] = layer.color;
  const style = useMemo<ViewStyle>(
    () => ({ ...frame, pointerEvents: "none", boxShadow: auraShadow(variant, [red, green, blue], theme) }),
    [frame, variant, red, green, blue, theme],
  );
  const animated = useAnimatedStyle(() => ({ opacity: opacity.value }));

  useEffect(() => {
    opacity.value = still ? layer.opacity : withTiming(layer.opacity, TIMING);
  }, [opacity, layer.opacity, still]);

  return <Animated.View style={[style, animated]} />;
}

export function Aura({ color, on, variant, size, shape, still, theme }: AuraProps) {
  const [blend, setBlend] = useState(() => startAura(color, on));
  const next = blendAura(blend, color, on);
  if (next !== blend) setBlend(next);
  const frame = useMemo(() => auraLayerStyle(variant, size, shape), [variant, size, shape]);

  return (
    <>
      <AuraLayerView layer={next.layers[0]} frame={frame} variant={variant} still={still} theme={theme} />
      <AuraLayerView layer={next.layers[1]} frame={frame} variant={variant} still={still} theme={theme} />
    </>
  );
}
