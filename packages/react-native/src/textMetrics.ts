import type { SkFont } from "@shopify/react-native-skia";

export function advanceWidth(font: SkFont, text: string): number {
  const widths = font.getGlyphWidths(font.getGlyphIDs(text));
  let total = 0;
  for (let i = 0; i < widths.length; i++) total += widths[i];
  return Math.ceil(total);
}

export function centeredBaseline(font: SkFont, height: number): number {
  const { ascent, descent } = font.getMetrics();
  return (height - descent - ascent) / 2;
}
