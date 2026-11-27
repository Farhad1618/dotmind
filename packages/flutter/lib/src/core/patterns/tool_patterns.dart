import 'dart:math' as math;
import 'dart:typed_data';

import 'grid.dart';
import 'pattern.dart';
import 'shapes.dart';

void radar(double t, Float32List o, PatternContext ctx) {
  final sweep = t * tau / 1.6;
  final turn = (sweep / tau).floor();
  for (var i = 0; i < cellCount; i++) {
    final dx = cellX(i) - gridCenter;
    final dy = cellY(i) - gridCenter;
    final r = hypot(dx, dy);
    if (r > 4) {
      o[i] = 0;
      continue;
    }
    final behind = wrapAngle(sweep - math.atan2(dy, dx));
    var v = 0.1 + 1.1 * math.exp(-behind * 2.4) * (0.4 + r / 6);
    if (hash(i, turn) > 0.9 && behind < 3) {
      v = math.max(v, 1.4 * math.exp(-behind * 0.8));
    }
    o[i] = v;
  }
}

void _meridian(Float32List o, double angle) {
  final s = math.sin(angle);
  final front = math.cos(angle) > 0;
  final v = front ? 1.3 : 0.45;
  for (var y = 0; y < gridSize; y++) {
    final dy = y - gridCenter;
    final w = math.sqrt(math.max(0, 12.25 - dy * dy));
    final x = roundHalfUp(gridCenter + w * s);
    if (x < 0 || x > 7) continue;
    final i = cellAt(x, y);
    if (o[i] < v) o[i] = v;
  }
}

void globe(double t, Float32List o, PatternContext ctx) {
  clear(o);
  for (var i = 0; i < cellCount; i++) {
    final y = cellY(i);
    final r = hypot(cellX(i) - gridCenter, y - gridCenter);
    if ((r - 3.2).abs() < 0.7) o[i] = 0.35;
    if (y == 3 || y == 4) {
      final band = r < 3.6 ? 0.22 : 0.0;
      if (o[i] < band) o[i] = band;
    }
  }
  _meridian(o, t * 1.8);
  _meridian(o, t * 1.8 + math.pi);
}

void code(double t, Float32List o, PatternContext ctx) {
  clear(o);
  fillCells(o, codeBrackets, 0.7);
  final typed = ((ctx.progress * 0.2 + t * 3) % 6).floor();
  for (var k = 0; k < typed && k < 4; k++) {
    o[cellAt(2 + k, 3)] = 0.85;
  }
  final cx = 2 + (typed < 4 ? typed : 4);
  if (cx <= 5) o[cellAt(cx, 3)] = math.sin(t * 9) > 0 ? 1.45 : 0.3;
}

void pages(double t, Float32List o, PatternContext ctx) {
  clear(o);
  fillCells(o, pageOutline, 0.55);
  final cycle = t * 1.8;
  final line = cycle.floor() % (pageLines.length + 1);
  for (var k = 0; k < pageLines.length; k++) {
    final cells = pageLines[k];
    if (k < line) fillCells(o, cells, 0.75);
    if (k == line) {
      final head = fract(cycle) * cells.length;
      final lead = head.floor();
      for (var j = 0; j < cells.length; j++) {
        if (j <= head) o[cells[j]] = j == lead ? 1.4 : 0.9;
      }
    }
  }
}

void stack(double t, Float32List o, PatternContext ctx) {
  clear(o);
  final cycle = t * 2.2;
  final active = cycle.floor() % 3;
  final frac = fract(cycle);
  for (var k = 0; k < disks.length; k++) {
    fillCells(o, disks[k], k == active ? 0.95 : 0.28);
    if (k == active) {
      final x = 1 + (frac * 6).floor();
      o[cellAt(x, k * 3)] = 1.45;
      o[cellAt(7 - x, k * 3 + 1)] = 1.2;
    }
  }
}

void prism(double t, Float32List o, PatternContext ctx) {
  final s = 0.5 + 0.5 * math.sin(t * 2.1);
  final r = 1 + 2.6 * s;
  for (var i = 0; i < cellCount; i++) {
    final ax = (cellX(i) - gridCenter).abs();
    final ay = (cellY(i) - gridCenter).abs();
    final d = ax + ay - r;
    final on = math.exp(-(d * d) / 0.18);
    final axis = ax < 1 || ay < 1 ? 0.45 : 0.0;
    o[i] = on * (0.75 + axis + (1 - s) * 0.3);
  }
}

void circuit(double t, Float32List o, PatternContext ctx) {
  clear(o);
  trail(o, perimeter, t * 13, 9, 0.8);
  fillCells(o, centerCells, 0.25 + (0.5 + 0.5 * math.sin(t * 4)) * 0.9);
}
