import { test } from "node:test";
import assert from "node:assert/strict";
import { SHAPES, type Shape } from "dotmind";
import { createDotLook, GLOW_LEVELS, glowLevel, heatOf, lookAt } from "../src/dotLook.ts";
import { cellBox, createCellBox, matrixGeometry } from "../src/geometry.ts";
import { auraLayerStyle, auraShadow, containerStyle, labelHeight, wellStyle } from "../src/layout.ts";
import { DEFAULT_THEME, resolveTheme } from "../src/theme.ts";

const close = (a: number, b: number) => Math.abs(a - b) < 1e-4;

test("the grid keeps 12% padding and 34% dot radius", () => {
  const g = matrixGeometry(28);
  assert.equal(g.shape, "dot");
  assert.ok(close(g.padding, 3.36));
  assert.ok(close(g.step, (28 - 6.72) / 7));
  assert.ok(close(g.half, g.step * 0.34));
  assert.equal(g.base, 0.14);
  assert.ok(close(g.xs[0], g.padding) && close(g.ys[0], g.padding));
  assert.ok(close(g.xs[63], 28 - g.padding) && close(g.ys[63], 28 - g.padding));
  assert.ok(close(g.xs[9], g.padding + g.step) && close(g.ys[9], g.padding + g.step));
});

test("dim dots stay unlit and bright dots glow toward white", () => {
  const look = createDotLook();
  assert.equal(lookAt(0.02, [255, 140, 60], 2, look), false);
  assert.equal(lookAt(0.5, [255, 140, 60], 2, look), true);
  assert.deepEqual([look.red, look.green, look.blue, look.alpha, look.heat], [255, 140, 60, 0.5, 0]);
  assert.ok(close(look.glowRadius, 3));
  assert.equal(look.radiusScale, 1);
  lookAt(1.5, [255, 140, 60], 2, look);
  assert.deepEqual([look.red, look.green, look.blue, look.alpha, look.heat], [255, 255, 255, 1, 1]);
  assert.ok(close(look.glowRadius, 8));
  assert.ok(close(look.radiusScale, 1.12));
  lookAt(1.125, [0, 0, 0], 2, look);
  assert.equal(look.red, 127);
});

test("heat clamps and maps onto the precomputed glow levels", () => {
  assert.equal(heatOf(0.85), 0);
  assert.equal(heatOf(9), 1);
  assert.equal(glowLevel(0), 0);
  assert.equal(glowLevel(1), GLOW_LEVELS);
  assert.equal(glowLevel(0.5), GLOW_LEVELS / 2);
});

test("the pill matches the web defaults", () => {
  const pill = containerStyle("pill", DEFAULT_THEME, 15);
  assert.equal(pill.backgroundColor, "#0b0b0c");
  assert.equal(pill.borderColor, "#26262a");
  assert.equal(pill.borderRadius, 999);
  assert.ok(close(pill.paddingLeft as number, 5.25));
  assert.ok(close(pill.paddingRight as number, 17.25));
  assert.ok(close(pill.gap as number, 9));
  const bare = containerStyle("bare", DEFAULT_THEME, 15);
  assert.equal(bare.backgroundColor, undefined);
  assert.equal(bare.paddingLeft, undefined);
  const well = wellStyle(28, DEFAULT_THEME);
  assert.equal(well.backgroundColor, "#050506");
  assert.ok(close(well.borderRadius as number, 6.72));
  assert.ok(close(wellStyle(28, DEFAULT_THEME, "square").borderRadius as number, 3.92));
  assert.equal(labelHeight(15), 18);
});

test("theme overrides merge over the defaults", () => {
  assert.equal(resolveTheme(undefined), DEFAULT_THEME);
  const custom = resolveTheme({ background: "#fff", fontSize: 13 });
  assert.equal(custom.background, "#fff");
  assert.equal(custom.fontSize, 13);
  assert.equal(custom.ink, DEFAULT_THEME.ink);
});

test("square cells use the core shape geometry", () => {
  const g = matrixGeometry(28, "square");
  assert.equal(g.shape, "square");
  assert.equal(g.base, SHAPES.square.base);
  assert.equal(g.corner, SHAPES.square.corner);
  assert.ok(close(g.half * 2, g.step * 0.8));
  assert.ok(close(g.xs[9], g.padding + g.step) && close(g.ys[9], g.padding + g.step));
  const box = cellBox(g.xs[9], g.ys[9], g.half, g.corner, createCellBox());
  assert.ok(close(box.rect.x, g.xs[9] - g.half) && close(box.rect.y, g.ys[9] - g.half));
  assert.ok(close(box.rect.width, g.step * 0.8) && close(box.rect.height, g.step * 0.8));
  assert.ok(close(box.rx, g.step * 0.8 * 0.22) && box.rx === box.ry);
  assert.equal(g.base, 0.2);
});

test("an unknown shape draws dots", () => {
  const g = matrixGeometry(28, "hexagon" as Shape);
  assert.equal(g.shape, "dot");
  assert.ok(close(g.half, g.step * 0.34));
});

test("the aura glows in the scene colour around the pill or the bare well", () => {
  assert.equal(
    auraShadow("pill", [255, 140, 60], DEFAULT_THEME),
    "0px 0px 24px -6px rgba(255,140,60,0.55), 0px 0px 72px 8px rgba(255,140,60,0.2)",
  );
  assert.equal(auraShadow("bare", [10, 20, 30], DEFAULT_THEME), "0px 0px 18px 2px rgba(10,20,30,0.55)");
  assert.equal(auraShadow("bare", [10, 20, 30], resolveTheme({ auraNear: 0.3 })), "0px 0px 18px 2px rgba(10,20,30,0.3)");
  const pill = auraLayerStyle("pill", 28, "dot");
  assert.deepEqual([pill.position, pill.top, pill.left, pill.right, pill.bottom, pill.borderRadius], ["absolute", -1, -1, -1, -1, 999]);
  const bare = auraLayerStyle("bare", 28, "square");
  assert.deepEqual([bare.top, bare.left, bare.right, bare.bottom], [0, 0, 0, 0]);
  assert.ok(close(bare.borderRadius as number, 3.92));
});
