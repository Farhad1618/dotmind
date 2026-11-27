import type { RGB } from "dotmind";

export interface MatrixPainter {
  paint(values: Float32Array, color: RGB): void;
}
