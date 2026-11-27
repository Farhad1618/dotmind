import { mount, type DotMindController } from "./mount.ts";
import type { ActivityTracker } from "./tracker.ts";
import type { Activity, Phase, SceneName, ToolKind } from "./types.ts";
import { classifyTool } from "./tools.ts";

const Base: typeof HTMLElement = typeof HTMLElement === "undefined" ? (class {} as typeof HTMLElement) : HTMLElement;

export class DotMindElement extends Base {
  static observedAttributes = ["phase", "tool", "kind", "label", "variant", "size", "scene"];

  private controller: DotMindController | null = null;
  private explicit: Activity | null = null;
  private unsubscribe: (() => void) | null = null;

  get activity(): Activity {
    return this.explicit ?? this.fromAttributes();
  }

  set activity(value: Activity | Phase) {
    this.explicit = typeof value === "string" ? { phase: value } : value;
    this.controller?.update(this.explicit);
  }

  connect(tracker: ActivityTracker): () => void {
    this.unsubscribe?.();
    this.unsubscribe = tracker.subscribe((a) => {
      this.activity = a;
    });
    return () => {
      this.unsubscribe?.();
      this.unsubscribe = null;
    };
  }

  connectedCallback(): void {
    const shadow = this.shadowRoot ?? this.attachShadow({ mode: "open" });
    this.controller = mount(shadow as unknown as HTMLElement, this.options(), shadow);
    this.controller.update(this.activity);
  }

  disconnectedCallback(): void {
    this.controller?.destroy();
    this.controller = null;
  }

  attributeChangedCallback(): void {
    if (!this.controller) return;
    this.controller.setOptions(this.options());
    if (!this.explicit) this.controller.update(this.fromAttributes());
  }

  private options() {
    const label = this.getAttribute("label");
    const size = Number(this.getAttribute("size"));
    return {
      variant: this.getAttribute("variant") === "bare" ? ("bare" as const) : ("pill" as const),
      size: Number.isFinite(size) && size > 0 ? size : 28,
      label: label === null ? undefined : label === "" ? (false as const) : label,
      scene: (this.getAttribute("scene") as SceneName | null) ?? undefined,
    };
  }

  private fromAttributes(): Activity {
    const tool = this.getAttribute("tool") ?? undefined;
    const kind = (this.getAttribute("kind") as ToolKind | null) ?? (tool ? classifyTool(tool) : undefined);
    return { phase: (this.getAttribute("phase") as Phase | null) ?? "thinking", tool, kind };
  }
}

export function defineDotMind(tag = "dot-mind"): void {
  if (typeof customElements === "undefined" || customElements.get(tag)) return;
  customElements.define(tag, class extends DotMindElement {});
}
