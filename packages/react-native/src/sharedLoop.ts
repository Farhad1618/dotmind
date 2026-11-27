import { FrameLoop, type FrameScheduler } from "./frameLoop.ts";

const animationFrames: FrameScheduler = {
  request: (callback) => requestAnimationFrame(callback),
  cancel: (handle) => cancelAnimationFrame(handle),
};

export const sharedFrameLoop = new FrameLoop(animationFrames);
