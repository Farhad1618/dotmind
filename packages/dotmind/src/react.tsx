"use client";

import { useEffect, useMemo, useRef, type HTMLAttributes } from "react";
import { mount, type DotMindController, type DotMindOptions } from "./mount.ts";
import { ActivityTracker, type TrackerOptions } from "./tracker.ts";
import type { Activity, Phase } from "./types.ts";

export interface DotMindProps extends DotMindOptions, Omit<HTMLAttributes<HTMLSpanElement>, "children"> {
  activity?: Activity | Phase;
  tracker?: ActivityTracker;
}

export function DotMind({
  activity,
  tracker,
  variant,
  size,
  label,
  labels,
  palette,
  scene,
  look,
  shape,
  scenes,
  aura,
  reducedMotion,
  ...rest
}: DotMindProps) {
  const host = useRef<HTMLSpanElement>(null);
  const controller = useRef<DotMindController | null>(null);
  const options: DotMindOptions = { variant, size, label, labels, palette, scene, look, shape, scenes, aura, reducedMotion };
  const optionsKey = JSON.stringify(options);

  useEffect(() => {
    if (!host.current) return;
    const c = mount(host.current, options);
    controller.current = c;
    return () => {
      c.destroy();
      controller.current = null;
    };
  }, []);

  useEffect(() => {
    controller.current?.setOptions(options);
  }, [optionsKey]);

  useEffect(() => {
    if (!tracker && activity !== undefined) controller.current?.update(activity);
  }, [tracker, activity]);

  useEffect(() => {
    if (!tracker) return;
    return tracker.subscribe((a) => controller.current?.update(a));
  }, [tracker]);

  return <span ref={host} {...rest} />;
}

export function useActivityTracker(options?: TrackerOptions): ActivityTracker {
  return useMemo(() => new ActivityTracker(options), []);
}

export type { Activity, Phase } from "./types.ts";
