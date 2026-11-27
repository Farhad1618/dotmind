import { useEffect, useRef } from "react";
import { AccessibilityInfo, Platform } from "react-native";

export function useAnnouncement(message: string): void {
  const previous = useRef(message);
  useEffect(() => {
    if (previous.current === message) return;
    previous.current = message;
    if (Platform.OS === "ios" && message) AccessibilityInfo.announceForAccessibilityWithOptions(message, { queue: true });
  }, [message]);
}
