import { useEffect } from "react";
import { AppState } from "react-native";
import { createAppStateGate } from "./appLifecycle.ts";
import { sharedFrameLoop } from "./sharedLoop.ts";

const holdAppState = createAppStateGate(AppState, sharedFrameLoop);

export function useAppStatePause(): void {
  useEffect(() => holdAppState(), []);
}
