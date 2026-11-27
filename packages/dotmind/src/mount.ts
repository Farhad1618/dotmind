import { labelFor, type LabelMap } from "./labels.ts";
import { SCENE_COLORS } from "./patterns.ts";
import { DotRenderer } from "./renderer.ts";
import { sceneFor } from "./scene.ts";
import { GRID } from "./patterns.ts";
import type { Activity, DotMindOptions, Phase, RGB } from "./types.ts";


export type { DotMindOptions };

export interface DotMindController {
  readonly element: HTMLElement;
  update(activity: Activity | Phase): void;
  setOptions(options: Partial<DotMindOptions>): void;
  destroy(): void;
}

export const DOTMIND_CSS = `
.dm{display:inline-flex;align-items:center;gap:.6em;font:500 var(--dm-font-size,15px)/1.2 var(--dm-font,ui-sans-serif,system-ui,-apple-system,"Segoe UI",sans-serif);vertical-align:middle;max-width:100%}
.dm--pill{padding:.35em 1.15em .35em .35em;border-radius:999px;background:var(--dm-bg,#0b0b0c);box-shadow:inset 0 0 0 1px var(--dm-edge,#26262a),0 10px 30px -14px rgba(0,0,0,.8),inset 0 1px 0 rgba(255,255,255,.04)}
.dm-well{display:block;flex:none;border-radius:24%;background:var(--dm-well,#050506)}
.dm-label{min-width:0;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;background:linear-gradient(100deg,var(--dm-ink,#8a8a92) 0%,var(--dm-ink,#8a8a92) 38%,var(--dm-peak,#fff) 47%,var(--dm-glow,#fff) 52%,var(--dm-ink,#8a8a92) 62%,var(--dm-ink,#8a8a92) 100%);background-size:260% 100%;-webkit-background-clip:text;background-clip:text;color:transparent;animation:dm-shimmer var(--dm-shimmer,2.4s) linear infinite;transition:opacity .2s}
.dm[data-phase=idle] .dm-label,.dm[data-phase=done] .dm-label,.dm[data-phase=error] .dm-label{animation:none;background-position:100% 0}
.dm-label[hidden]{display:none}
@keyframes dm-shimmer{from{background-position:130% 0}to{background-position:-30% 0}}
@media (prefers-reduced-motion:reduce){.dm-label{animation:none;background-position:50% 0}}
`;

const styled = new WeakSet<Document | ShadowRoot>();

export function injectStyles(root: Document | ShadowRoot): void {
  if (styled.has(root)) return;
  styled.add(root);
  const style = document.createElement("style");
  style.setAttribute("data-dotmind", "");
  style.textContent = DOTMIND_CSS;
  if (root instanceof Document) root.head.appendChild(style);
  else root.appendChild(style);
}

const CELLS = GRID * GRID;
const clamp = (v: number, a: number, b: number) => (v < a ? a : v > b ? b : v);

export function drawMatrix(
  renderer: DotRenderer,
  ctx: CanvasRenderingContext2D,
  px: number,
  values: Float32Array,
  rgb: [number, number, number],
  base = 0.14,
): void {
  renderer.sample(values);
  const [r, g, b] = renderer.color(rgb);
  const pad = px * 0.12;
  const step = (px - pad * 2) / (GRID - 1);
  const rad = step * 0.34;
  ctx.clearRect(0, 0, px, px);
  ctx.shadowBlur = 0;
  ctx.fillStyle = `rgba(${r | 0},${g | 0},${b | 0},${base})`;
  ctx.beginPath();
  for (let i = 0; i < CELLS; i++) {
    const x = pad + (i % GRID) * step;
    const y = pad + Math.floor(i / GRID) * step;
    ctx.moveTo(x + rad, y);
    ctx.arc(x, y, rad, 0, Math.PI * 2);
  }
  ctx.fill();
  for (let i = 0; i < CELLS; i++) {
    const v = clamp(values[i], 0, 1.5);
    if (v < 0.03) continue;
    const x = pad + (i % GRID) * step;
    const y = pad + Math.floor(i / GRID) * step;
    const w = clamp((v - 0.85) / 0.55, 0, 1);
    const a = clamp(v, 0, 1);
    ctx.shadowColor = `rgba(${r | 0},${g | 0},${b | 0},${a})`;
    ctx.shadowBlur = rad * (1.5 + w * 2.5);
    ctx.fillStyle = `rgba(${(r + (255 - r) * w) | 0},${(g + (255 - g) * w) | 0},${(b + (255 - b) * w) | 0},${a})`;
    ctx.beginPath();
    ctx.arc(x, y, rad * (1 + w * 0.12), 0, Math.PI * 2);
    ctx.fill();
  }
}

interface Instance {
  renderer: DotRenderer;
  ctx: CanvasRenderingContext2D;
  px: number;
  visible: boolean;
  still: boolean;
  values: Float32Array;
  rgb: [number, number, number];
}

const live = new Set<Instance>();
let frame = 0;
let last = 0;

function loop(now: number) {
  const dt = last ? Math.min(0.05, (now - last) / 1000) : 0;
  last = now;
  let any = false;
  for (const inst of live) {
    if (!inst.visible || inst.still) continue;
    any = true;
    inst.renderer.step(dt);
    drawMatrix(inst.renderer, inst.ctx, inst.px, inst.values, inst.rgb);
  }
  frame = any || live.size ? requestAnimationFrame(loop) : 0;
  if (!frame) last = 0;
}

function ensureLoop() {
  if (!frame && typeof requestAnimationFrame === "function") frame = requestAnimationFrame(loop);
}

const toActivity = (a: Activity | Phase): Activity => (typeof a === "string" ? { phase: a } : a);

export function mount(host: HTMLElement, options: DotMindOptions = {}, styleRoot?: Document | ShadowRoot): DotMindController {
  let opts: DotMindOptions = { variant: "pill", size: 28, ...options };
  injectStyles(styleRoot ?? host.ownerDocument);

  const root = host.ownerDocument.createElement("span");
  root.setAttribute("role", "status");
  root.setAttribute("aria-live", "polite");
  const canvas = host.ownerDocument.createElement("canvas");
  canvas.className = "dm-well";
  canvas.setAttribute("aria-hidden", "true");
  const label = host.ownerDocument.createElement("span");
  label.className = "dm-label";
  root.append(canvas, label);
  host.appendChild(root);

  const ctx = canvas.getContext("2d");
  if (!ctx) throw new Error("dotmind needs a 2D canvas context");
  const reduce =
    opts.reducedMotion ?? (typeof matchMedia === "function" && matchMedia("(prefers-reduced-motion: reduce)").matches);
  const inst: Instance = { renderer: new DotRenderer(), ctx, px: 0, visible: true, still: reduce, values: new Float32Array(CELLS), rgb: [0, 0, 0] };
  let activity: Activity = { phase: "idle" };
  let drawn = false;

  const io =
    typeof IntersectionObserver === "function"
      ? new IntersectionObserver((entries) => {
          inst.visible = entries.some((e) => e.isIntersecting);
        })
      : null;
  io?.observe(canvas);

  function layout() {
    const size = opts.size ?? 28;
    const dpr = Math.min(2, (typeof devicePixelRatio === "number" && devicePixelRatio) || 1);
    inst.px = Math.round(size * dpr);
    canvas.width = inst.px;
    canvas.height = inst.px;
    canvas.style.width = `${size}px`;
    canvas.style.height = `${size}px`;
    drawn = false;
    root.className = opts.variant === "bare" ? "dm dm--bare" : "dm dm--pill";
  }

  function render() {
    const scene = opts.scene ?? sceneFor(activity);
    const color = opts.palette?.[scene] ?? SCENE_COLORS[scene];
    inst.renderer.feed(activity.progress);
    inst.renderer.show(scene, color, !inst.visible || !drawn);
    root.dataset.phase = activity.phase;
    root.dataset.scene = scene;
    if (activity.tool) root.dataset.tool = activity.tool;
    else delete root.dataset.tool;
    const [r, g, b] = color;
    root.style.setProperty("--dm-glow", `rgb(${(r + 510) / 3 | 0},${(g + 510) / 3 | 0},${(b + 510) / 3 | 0})`);
    const text = opts.label === false ? "" : opts.label ?? labelFor(activity, opts.labels);
    label.hidden = !text;
    if (label.textContent !== text) label.textContent = text;
    root.setAttribute("aria-label", text || labelFor(activity, opts.labels));
    if (inst.still) {
      inst.renderer.step(1.2);
      inst.renderer.step(0.5);
    }
    if (inst.still || !drawn || !inst.visible) drawMatrix(inst.renderer, ctx!, inst.px, inst.values, inst.rgb);
    drawn = true;
  }

  layout();
  render();
  live.add(inst);
  ensureLoop();

  return {
    element: root,
    update(next) {
      activity = toActivity(next);
      render();
    },
    setOptions(next) {
      opts = { ...opts, ...next };
      layout();
      render();
    },
    destroy() {
      live.delete(inst);
      io?.disconnect();
      root.remove();
    },
  };
}
