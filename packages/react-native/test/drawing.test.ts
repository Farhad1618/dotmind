import { test } from "node:test";
import assert from "node:assert/strict";
import { BASE_ALPHA, createDotLook, GLOW_LEVELS, glowLevel, heatOf, lookAt } from "../src/dotLook.ts";
import { matrixGeometry } from "../src/geometry.ts";
import { containerStyle, labelHeight, wellStyle } from "../src/layout.ts";
import { DEFAULT_THEME, resolveTheme } from "../src/theme.ts";

const close = (a: number, b: number) => Math.abs(a - b) < 1e-4;

test("the grid keeps 12% padding and 34% dot radius", () => {
  const g = matrixGeometry(28);
  assert.ok(close(g.padding, 3.36));
  assert.ok(close(g.step, (28 - 6.72) / 7));
  assert.ok(close(g.radius, g.step * 0.34));
  assert.ok(close(g.xs[0], g.padding) && close(g.ys[0], g.padding));
  assert.ok(close(g.xs[63], 28 - g.padding) && close(g.ys[63], 28 - g.padding));
  assert.ok(close(g.xs[9], g.padding + g.step) && close(g.ys[9], g.padding + g.step));
});

test("dim dots stay unlit and bright dots glow toward white", () => {
  const look = createDotLook();
  assert.equal(BASE_ALPHA, 0.14);
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
  assert.equal(labelHeight(15), 18);
});

test("theme overrides merge over the defaults", () => {
  assert.equal(resolveTheme(undefined), DEFAULT_THEME);
  const custom = resolveTheme({ background: "#fff", fontSize: 13 });
  assert.equal(custom.background, "#fff");
  assert.equal(custom.fontSize, 13);
  assert.equal(custom.ink, DEFAULT_THEME.ink);
});
