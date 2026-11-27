import { useEffect, useState } from "react";
import { AccessibilityInfo } from "react-native";

let lastKnown = false;

export function useSystemReducedMotion(): boolean {
  const [reduced, setReduced] = useState(lastKnown);
  useEffect(() => {
    let mounted = true;
    let heard = false;
    const apply = (value: boolean) => {
      lastKnown = value;
      if (mounted) setReduced(value);
    };
    const subscription = AccessibilityInfo.addEventListener("reduceMotionChanged", (value: boolean) => {
      heard = true;
      apply(value);
    });
    AccessibilityInfo.isReduceMotionEnabled().then(
      (value) => {
        if (!heard) apply(value);
      },
      () => undefined,
    );
    return () => {
      mounted = false;
      subscription.remove();
    };
  }, []);
  return reduced;
}
