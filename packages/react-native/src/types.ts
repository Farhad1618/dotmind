import type { Activity, ActivityTracker, DotMindOptions, Phase } from "dotmind";
import type { ViewProps } from "react-native";
import type { DotMindTheme } from "./theme.ts";

export interface DotMindProps extends DotMindOptions, Omit<ViewProps, "children"> {
  activity?: Activity | Phase;
  tracker?: ActivityTracker;
  theme?: Partial<DotMindTheme>;
  paused?: boolean;
}
