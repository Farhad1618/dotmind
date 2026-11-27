import { useState } from "react";
import { ActivityTracker, type TrackerOptions } from "dotmind";

export function useActivityTracker(options?: TrackerOptions): ActivityTracker {
  const [tracker] = useState(() => new ActivityTracker(options));
  return tracker;
}
