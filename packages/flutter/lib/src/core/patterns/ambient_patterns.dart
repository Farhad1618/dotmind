import 'dart:math' as math;
import 'dart:typed_data';

import 'grid.dart';
import 'pattern.dart';
import 'shapes.dart';

void ember(double t, Float32List o, PatternContext ctx) {
  final hx = gridCenter + 2.4 * math.sin(t * 1.3);
  final hy = gridCenter + 2.4 * math.sin(t * 1.9 + 1);
  for (var i = 0; i < cellCount; i++) {
    final dx = cellX(i) - hx;
    final dy = cellY(i) - hy;
    final wave = math.max(0.0, math.sin(t * (2 + hash(i, 1) * 3) + hash(i, 2) * tau));
    final flick = powInt(wave, 6) * 0.75;
    o[i] = math.min(1.5, 0.12 + flick + 1.35 * math.exp(-(dx * dx + dy * dy) / 1.1));
  }
}

void orbit(double t, Float32List o, PatternContext ctx) {
  final head = t * tau / 1.5;
  for (var i = 0; i < cellCount; i++) {
    final dx = cellX(i) - gridCenter;
    final dy = cellY(i) - gridCenter;
    if ((hypot(dx, dy) - 3.1).abs() > 0.75) {
      o[i] = 0;
      continue;
    }
    o[i] = 0.22 + 1.25 * math.exp(-wrapAngle(head - math.atan2(dy, dx)) * 1.1);
  }
}

void serpent(double t, Float32List o, PatternContext ctx) {
  clear(o);
  trail(o, serpentPath, t * 11, 9, 0.78);
}

void pulse(double t, Float32List o, PatternContext ctx) {
  for (var x = 0; x < gridSize; x++) {
    final h = 1 + 6.5 * (0.5 + 0.5 * math.sin(t * 3.1 + x * 0.8) * math.cos(t * 1.3 - x * 0.35));
    for (var y = 0; y < gridSize; y++) {
      final up = 7 - y;
      o[cellAt(x, y)] = up < h - 1 ? 0.7 : (up < h ? 1.4 : 0);
    }
  }
}
