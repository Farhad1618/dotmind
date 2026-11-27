import type { Activity, Phase } from "dotmind";
import type { MatrixDriver } from "./matrixDriver.ts";
import { present, samePresentation, toActivity, type Presentation, type PresentationOptions } from "./presentation.ts";

export type PresentationListener = (presentation: Presentation) => void;

export class DotMindController {
  readonly driver: MatrixDriver;
  private activity: Activity;
  private options: PresentationOptions;
  private presentation: Presentation;
  private readonly listeners = new Set<PresentationListener>();

  constructor(driver: MatrixDriver, activity?: Activity | Phase, options: PresentationOptions = {}) {
    this.driver = driver;
    this.activity = toActivity(activity);
    this.options = options;
    this.presentation = present(this.activity, options);
    this.driver.show(this.presentation.scene, this.presentation.color, this.activity.progress);
  }

  readonly snapshot = (): Presentation => this.presentation;

  readonly subscribe = (listener: PresentationListener): (() => void) => {
    this.listeners.add(listener);
    return () => {
      this.listeners.delete(listener);
    };
  };

  update(activity: Activity | Phase | undefined): void {
    this.activity = toActivity(activity);
    this.render();
  }

  setOptions(options: PresentationOptions): void {
    this.options = options;
    this.render();
  }

  private render(): void {
    const next = present(this.activity, this.options);
    this.driver.show(next.scene, next.color, this.activity.progress);
    if (samePresentation(this.presentation, next)) return;
    this.presentation = next;
    for (const listener of this.listeners) listener(next);
  }
}
