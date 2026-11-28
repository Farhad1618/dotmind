import { BlurStyle, Skia, type SkCanvas, type SkMaskFilter, type SkPaint, type SkPicture, type SkRect } from "@shopify/react-native-skia";
import type { RGB } from "dotmind";
import { createDotLook, GLOW_LEVELS, glowLevel, glowRadius, lookAt } from "./dotLook.ts";
import { cellBox, CELLS, createCellBox, type MatrixGeometry } from "./geometry.ts";
import type { MatrixPainter } from "./painter.ts";

function antialiased(): SkPaint {
  const paint = Skia.Paint();
  paint.setAntiAlias(true);
  return paint;
}

function glowFilters(half: number): SkMaskFilter[] {
  const filters: SkMaskFilter[] = [];
  for (let level = 0; level <= GLOW_LEVELS; level++) {
    filters.push(Skia.MaskFilter.MakeBlur(BlurStyle.Normal, glowRadius(half, level / GLOW_LEVELS) / 2, true));
  }
  return filters;
}

export class SkiaPainter implements MatrixPainter {
  private readonly geometry: MatrixGeometry;
  private readonly publish: (picture: SkPicture) => void;
  private readonly recorder = Skia.PictureRecorder();
  private readonly bounds: SkRect;
  private readonly basePaint = antialiased();
  private readonly glowPaint = antialiased();
  private readonly dotPaint = antialiased();
  private readonly ink = new Float32Array(4);
  private readonly look = createDotLook();
  private readonly box = createCellBox();
  private readonly glows: SkMaskFilter[];

  constructor(geometry: MatrixGeometry, publish: (picture: SkPicture) => void) {
    this.geometry = geometry;
    this.publish = publish;
    this.bounds = Skia.XYWHRect(0, 0, geometry.size, geometry.size);
    this.glows = glowFilters(geometry.half);
  }

  paint(values: Float32Array, color: RGB): void {
    const { xs, ys, half, base } = this.geometry;
    const look = this.look;
    const canvas = this.recorder.beginRecording(this.bounds);
    this.tint(this.basePaint, color[0] | 0, color[1] | 0, color[2] | 0, base);
    for (let i = 0; i < CELLS; i++) this.cell(canvas, xs[i], ys[i], half, this.basePaint);
    for (let i = 0; i < CELLS; i++) {
      if (!lookAt(values[i], color, half, look)) continue;
      const h = half * look.radiusScale;
      this.tint(this.glowPaint, color[0] | 0, color[1] | 0, color[2] | 0, look.alpha);
      this.glowPaint.setMaskFilter(this.glows[glowLevel(look.heat)]);
      this.cell(canvas, xs[i], ys[i], h, this.glowPaint);
      this.tint(this.dotPaint, look.red, look.green, look.blue, look.alpha);
      this.cell(canvas, xs[i], ys[i], h, this.dotPaint);
    }
    this.publish(this.recorder.finishRecordingAsPicture());
  }

  dispose(): void {
    for (const filter of this.glows) filter.dispose();
    this.basePaint.dispose();
    this.glowPaint.dispose();
    this.dotPaint.dispose();
    this.recorder.dispose();
  }

  private cell(canvas: SkCanvas, x: number, y: number, half: number, paint: SkPaint): void {
    if (this.geometry.shape === "square") canvas.drawRRect(cellBox(x, y, half, this.geometry.corner, this.box), paint);
    else canvas.drawCircle(x, y, half, paint);
  }

  private tint(paint: SkPaint, red: number, green: number, blue: number, alpha: number): void {
    this.ink[0] = red / 255;
    this.ink[1] = green / 255;
    this.ink[2] = blue / 255;
    this.ink[3] = alpha;
    paint.setColor(this.ink);
  }
}
