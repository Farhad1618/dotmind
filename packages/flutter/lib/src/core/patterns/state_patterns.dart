import 'dart:math' as math;
import 'dart:typed_data';

import 'grid.dart';
import 'pattern.dart';
import 'shapes.dart';

void breathe(double t, Float32List o, PatternContext ctx) {
  clear(o);
  final p = 0.5 + 0.5 * math.sin(t * 1.6);
  fillCells(o, centerCells, 0.18 + p * 0.5);
}

void comet(double t, Float32List o, PatternContext ctx) {
  clear(o);
  for (var k = 0; k < 14; k++) {
    final a = t * 2.6 - k * 0.17;
    final x = roundHalfUp(gridCenter + 3.2 * math.sin(a));
    final y = roundHalfUp(gridCenter + 3.1 * math.sin(2 * a));
    final i = cellAt(clampIndex(x, 0, 7), clampIndex(y, 0, 7));
    final v = k == 0 ? 1.45 : powInt(0.8, k);
    if (o[i] < v) o[i] = v;
  }
}

int _lineLength(int k) => 3 + (hash(k, 7) * 5).floor();

void type(double t, Float32List o, PatternContext ctx) {
  clear(o);
  final total = (ctx.progress / 4).floor();
  var line = 0;
  var used = 0;
  while (used + _lineLength(line) <= total) {
    used += _lineLength(line);
    line++;
  }
  final pos = total - used;
  final first = math.max(0, line - 7);
  final caretOn = math.sin(t * 10) > -0.2;
  for (var k = first; k <= line; k++) {
    final row = k - first;
    final current = k == line;
    final n = current ? pos : _lineLength(k);
    for (var x = 0; x < n; x++) {
      o[cellAt(x, row)] = current ? 0.85 : 0.5;
    }
    if (current && pos < 8) o[cellAt(pos, row)] = caretOn ? 1.45 : 0.25;
  }
}

void halo(double t, Float32List o, PatternContext ctx) {
  clear(o);
  trail(o, ring12, t * 10, 6, 0.68);
  fillCells(o, centerCells, 0.15 + (0.5 + 0.5 * math.sin(t * 2.2)) * 0.35);
}

void cross(double t, Float32List o, PatternContext ctx) {
  clear(o);
  final flash = t < 0.9 ? (math.sin(t * 22) > 0 ? 1.4 : 0.35) : 0.85 + 0.15 * math.sin(t * 2);
  fillCells(o, crossMark, flash);
}

void check(double t, Float32List o, PatternContext ctx) {
  clear(o);
  final drawn = t * 14;
  final settled = t > 1.2 ? 0.8 + 0.1 * math.sin(t * 2) : 1.1;
  for (var k = 0; k < checkStroke.length; k++) {
    if (k < drawn) o[checkStroke[k]] = k + 1 > drawn ? 1.45 : settled;
  }
}
