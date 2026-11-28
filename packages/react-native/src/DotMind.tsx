import { useEffect, useMemo, useState, useSyncExternalStore } from "react";
import { useWindowDimensions, View } from "react-native";
import { Aura } from "./Aura.tsx";
import { DotMatrix } from "./DotMatrix.tsx";
import { DotMindController } from "./controller.ts";
import { containerStyle, wellFrameStyle } from "./layout.ts";
import { lookStyle } from "./lookStyle.ts";
import { MatrixDriver } from "./matrixDriver.ts";
import { ShimmerLabel } from "./ShimmerLabel.tsx";
import { shimmerMode } from "./shimmer.ts";
import { resolveTheme } from "./theme.ts";
import type { DotMindProps } from "./types.ts";
import { useAnnouncement } from "./useAnnouncement.ts";
import { useSystemReducedMotion } from "./useSystemReducedMotion.ts";

export function DotMind({
  activity,
  tracker,
  variant = "pill",
  size = 28,
  label,
  labels,
  palette,
  scene,
  look,
  shape,
  scenes,
  aura,
  reducedMotion,
  theme,
  paused = false,
  style,
  ...rest
}: DotMindProps) {
  const [controller] = useState(
    () =>
      new DotMindController(new MatrixDriver(), tracker ? tracker.activity : activity, {
        label,
        labels,
        palette,
        scene,
        look,
        scenes,
      }),
  );
  const presentation = useSyncExternalStore(controller.subscribe, controller.snapshot);
  const optionsKey = JSON.stringify({ label, labels, palette, scene, look, scenes });
  const themeKey = JSON.stringify(theme ?? null);
  const resolved = useMemo(() => resolveTheme(theme), [themeKey]);
  const styled = useMemo(() => lookStyle({ look, shape, aura }), [look, shape, aura]);
  const { fontScale } = useWindowDimensions();
  const fontSize = resolved.fontSize * fontScale;
  const systemReduced = useSystemReducedMotion();
  const still = reducedMotion ?? systemReduced;
  const container = useMemo(() => containerStyle(variant, resolved, fontSize), [variant, resolved, fontSize]);
  const frame = useMemo(() => wellFrameStyle(size), [size]);

  useEffect(() => {
    controller.setOptions({ label, labels, palette, scene, look, scenes });
  }, [controller, optionsKey]);

  useEffect(() => {
    if (!tracker) controller.update(activity);
  }, [controller, tracker, activity]);

  useEffect(() => {
    if (!tracker) return;
    return tracker.subscribe((next) => controller.update(next));
  }, [controller, tracker]);

  useAnnouncement(presentation.accessibilityLabel);

  const glow = (
    <Aura
      color={presentation.color}
      on={styled.aura}
      variant={variant}
      size={size}
      shape={styled.shape}
      still={still}
      theme={resolved}
    />
  );
  const matrix = <DotMatrix driver={controller.driver} size={size} shape={styled.shape} still={still} paused={paused} theme={resolved} />;

  return (
    <View
      accessible
      accessibilityRole={presentation.accessibilityRole}
      accessibilityLabel={presentation.accessibilityLabel}
      accessibilityLiveRegion="polite"
      {...rest}
      style={[container, style]}
    >
      {variant === "bare" ? null : glow}
      <View style={frame}>
        {variant === "bare" ? glow : null}
        {matrix}
      </View>
      {presentation.text ? (
        <ShimmerLabel
          text={presentation.text}
          mode={shimmerMode(presentation.busy, still || paused)}
          glow={presentation.glow}
          theme={resolved}
          fontSize={fontSize}
        />
      ) : null}
    </View>
  );
}
