export type AppStatus = "active" | "background" | "inactive" | "unknown" | "extension" | null | undefined;

export interface AppStateSource {
  readonly currentState: AppStatus | string;
  addEventListener(type: "change", listener: (status: AppStatus | string) => void): { remove(): void };
}

export interface Pausable {
  setActive(active: boolean): void;
}

export function isForeground(status: AppStatus | string): boolean {
  return status !== "background" && status !== "inactive";
}

export function createAppStateGate(source: AppStateSource, target: Pausable): () => () => void {
  let holders = 0;
  let subscription: { remove(): void } | null = null;
  return () => {
    holders++;
    if (!subscription) {
      target.setActive(isForeground(source.currentState));
      subscription = source.addEventListener("change", (status) => target.setActive(isForeground(status)));
    }
    let released = false;
    return () => {
      if (released) return;
      released = true;
      holders--;
      if (holders > 0 || !subscription) return;
      subscription.remove();
      subscription = null;
      target.setActive(true);
    };
  };
}
