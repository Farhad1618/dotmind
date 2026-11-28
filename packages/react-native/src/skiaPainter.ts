import { BlurStyle, Skia, type SkMaskFilter, type SkPaint, type SkPicture, type SkRect } from "@shopify/react-native-skia";
import type { RGB } from "dotmind";
import { BASE_ALPHA, createDotLook, GLOW_LEVELS, glowLevel, glowRadius, lookAt } from "./dotLook.ts";
import { CELLS, type MatrixGeometry } from "./geometry.ts";
import type { MatrixPainter } from "./painter.ts";

function antialiased(): SkPaint {
  const paint = Skia.Paint();
  paint.setAntiAlias(true);
  return paint;
}

function glowFilters(radius: number): SkMaskFilter[] {
  const filters: SkMaskFilter[] = [];
  for (let level = 0; level <= GLOW_LEVELS; level++) {
    filters.push(Skia.MaskFilter.MakeBlur(BlurStyle.Normal, glowRadius(radius, level / GLOW_LEVELS) / 2, true));
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
  private readonly glows: SkMaskFilter[];

  constructor(geometry: MatrixGeometry, publish: (picture: SkPicture) => void) {
    this.geometry = geometry;
    this.publish = publish;
    this.bounds = Skia.XYWHRect(0, 0, geometry.size, geometry.size);
    this.glows = glowFilters(geometry.radius);
  }

  paint(values: Float32Array, color: RGB): void {
    const { xs, ys, radius } = this.geometry;
    const look = this.look;
    const canvas = this.recorder.beginRecording(this.bounds);
    this.tint(this.basePaint, color[0] | 0, color[1] | 0, color[2] | 0, BASE_ALPHA);
    for (let i = 0; i < CELLS; i++) canvas.drawCircle(xs[i], ys[i], radius, this.basePaint);
    for (let i = 0; i < CELLS; i++) {
      if (!lookAt(values[i], color, radius, look)) continue;
      const r = radius * look.radiusScale;
      this.tint(this.glowPaint, color[0] | 0, color[1] | 0, color[2] | 0, look.alpha);
      this.glowPaint.setMaskFilter(this.glows[glowLevel(look.heat)]);
      canvas.drawCircle(xs[i], ys[i], r, this.glowPaint);
      this.tint(this.dotPaint, look.red, look.green, look.blue, look.alpha);
      canvas.drawCircle(xs[i], ys[i], r, this.dotPaint);
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

  private tint(paint: SkPaint, red: number, green: number, blue: number, alpha: number): void {
    this.ink[0] = red / 255;
    this.ink[1] = green / 255;
    this.ink[2] = blue / 255;
    this.ink[3] = alpha;
    paint.setColor(this.ink);
  }
}
