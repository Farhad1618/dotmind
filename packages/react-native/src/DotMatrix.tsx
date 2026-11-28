import { Canvas, Picture, Skia, type SkPicture } from "@shopify/react-native-skia";
import type { Shape } from "dotmind";
import { useEffect, useMemo } from "react";
import { View } from "react-native";
import { useSharedValue } from "react-native-reanimated";
import { matrixGeometry } from "./geometry.ts";
import { wellStyle } from "./layout.ts";
import type { MatrixDriver } from "./matrixDriver.ts";
import { sharedFrameLoop } from "./sharedLoop.ts";
import { SkiaPainter } from "./skiaPainter.ts";
import type { DotMindTheme } from "./theme.ts";
import { useAppStatePause } from "./useAppStatePause.ts";

let blank: SkPicture | null = null;

function blankPicture(): SkPicture {
  if (!blank) {
    const recorder = Skia.PictureRecorder();
    recorder.beginRecording(Skia.XYWHRect(0, 0, 1, 1));
    blank = recorder.finishRecordingAsPicture();
  }
  return blank;
}

export interface DotMatrixProps {
  driver: MatrixDriver;
  size: number;
  shape: Shape;
  still: boolean;
  paused: boolean;
  theme: DotMindTheme;
}

export function DotMatrix({ driver, size, shape, still, paused, theme }: DotMatrixProps) {
  const picture = useSharedValue<SkPicture>(blankPicture());
  const well = useMemo(() => wellStyle(size, theme, shape), [size, theme, shape]);
  const canvas = useMemo(() => ({ width: size, height: size }), [size]);

  useAppStatePause();

  useEffect(() => {
    const painter = new SkiaPainter(matrixGeometry(size, shape), (next) => {
      picture.value = next;
    });
    driver.attach(painter);
    const leave = sharedFrameLoop.add(driver);
    return () => {
      leave();
      driver.detach();
      painter.dispose();
    };
  }, [driver, size, shape, picture]);

  useEffect(() => {
    driver.setVisible(!paused);
    sharedFrameLoop.wake();
  }, [driver, paused]);

  useEffect(() => {
    driver.setStill(still);
    sharedFrameLoop.wake();
  }, [driver, still]);

  return (
    <View style={well} importantForAccessibility="no-hide-descendants" accessibilityElementsHidden>
      <Canvas style={canvas}>
        <Picture picture={picture} />
      </Canvas>
    </View>
  );
}
