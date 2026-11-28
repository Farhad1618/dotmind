import 'dart:math' as math;
import 'dart:typed_data';

import 'grid.dart';
import 'pattern.dart';

const List<Cell> _nodes = [(1, 0), (6, 1), (3, 3), (0, 5), (7, 4), (5, 6), (2, 7)];
const List<(int, int)> _edges = [(0, 2), (1, 2), (1, 4), (2, 3), (2, 4), (2, 5), (3, 6), (4, 5), (5, 6)];
final List<List<Cell>> _edgeCells = List.unmodifiable([for (final (a, b) in _edges) line(_nodes[a], _nodes[b])]);
final List<List<Cell>> _edgeCellsReversed = List.unmodifiable([
  for (final cells in _edgeCells) List<Cell>.unmodifiable(cells.reversed),
]);
const double _fireStep = 0.35;
const int _fireMemory = 6;
const double _signalSeconds = 0.47;

bool _firedAt(int node, int step) {
  if ((hash(step, 3) * _nodes.length).floor() == node) return true;
  return hash(step, 4) > 0.55 && (hash(step, 5) * _nodes.length).floor() == node;
}

double _nodeAge(int node, double t) {
  final now = (t / _fireStep).floor();
  for (var k = now; k > now - _fireMemory; k--) {
    if (_firedAt(node, k)) return t - k * _fireStep;
  }
  return double.infinity;
}

final List<Cell> _lens = bitmap(const ['.##.', '#..#', '#..#', '.##.']);
const List<Cell> _lensInside = [(1, 1), (2, 1), (1, 2), (2, 2)];
const List<Cell> _handle = [(3, 3), (4, 4)];

Uint8List _glyphMask(List<String> rows) {
  final mask = Uint8List(cellCount);
  for (final (x, y) in bitmap(rows)) {
    mask[cellAt(x, y)] = 1;
  }
  return mask;
}

final Uint8List _glyphA = _glyphMask(const [
  '...##...',
  '..#..#..',
  '.#....#.',
  '.#....#.',
  '.######.',
  '.#....#.',
  '.#....#.',
  '.#....#.',
]);
final Uint8List _glyphWen = _glyphMask(const [
  '...##...',
  '########',
  '.#....#.',
  '..#..#..',
  '...##...',
  '..#..#..',
  '.##..##.',
  '##....##',
]);
const double _glyphHold = 1.6;
const double _glyphSweep = 0.95;
const double _glyphPeriod = 2 * (_glyphHold + _glyphSweep);

const double _sortStep = 0.16;
const int _sortSlots = 40;

List<int> _shuffled(int seed) {
  final bars = [1, 2, 3, 4, 5, 6, 7, 8];
  for (var i = bars.length - 1; i > 0; i--) {
    final j = (hash(seed * 8 + i, 9) * (i + 1)).floor();
    final swap = bars[i];
    bars[i] = bars[j];
    bars[j] = swap;
  }
  return bars;
}

typedef _SortFrame = ({List<int> bars, int hot, int cmp, int doneFor});

_SortFrame _insertionSortAt(List<int> bars, int step) {
  var count = 0;
  for (var i = 1; i < bars.length; i++) {
    for (var j = i; j > 0 && bars[j - 1] > bars[j]; j--) {
      if (count == step) return (bars: bars, hot: j, cmp: j - 1, doneFor: -1);
      final swap = bars[j - 1];
      bars[j - 1] = bars[j];
      bars[j] = swap;
      count++;
    }
  }
  return (bars: bars, hot: -1, cmp: -1, doneFor: step - count);
}

const double _rocketPeriod = 2.6;
const double _rocketIgnite = 0.75;
const double _rocketFlight = 1.15;

const List<Cell> _check = [(1, 4), (2, 5), (3, 6), (4, 5), (5, 4), (6, 3), (7, 2)];
const double _ringPeriod = 1.45;

void neural(double t, Float32List o, PatternContext ctx) {
  clear(o);
  for (final cells in _edgeCells) {
    lightCells(o, cells, 0.52);
  }
  final ages = [for (var n = 0; n < _nodes.length; n++) _nodeAge(n, t)];
  for (var e = 0; e < _edges.length; e++) {
    final (a, b) = _edges[e];
    for (final (from, path) in [(a, _edgeCells[e]), (b, _edgeCellsReversed[e])]) {
      final age = ages[from];
      if (age >= _signalSeconds) continue;
      final k = (age / _signalSeconds * path.length).floor();
      final (x, y) = path[math.min(path.length - 1, k)];
      light(o, x, y, 1.15);
    }
  }
  for (var n = 0; n < _nodes.length; n++) {
    final (x, y) = _nodes[n];
    o[cellAt(x, y)] = 0.84 + 0.66 * math.exp(-ages[n] * 3.2);
  }
}

void magnifier(double t, Float32List o, PatternContext ctx) {
  for (var i = 0; i < cellCount; i++) {
    o[i] = hash(i, 11) > 0.8 ? 0.2 : 0;
  }
  final lx = roundHalfUp(1.6 + 1.6 * math.sin(t * 0.83));
  final ly = roundHalfUp(1.5 + 1.5 * math.sin(t * 1.21 + 1.3));
  for (final (x, y) in _lensInside) {
    final i = cellAt(lx + x, ly + y);
    o[i] = hash(i, 11) > 0.8 ? 1.45 : 0.1;
  }
  for (final (x, y) in _lens) {
    o[cellAt(lx + x, ly + y)] = 1;
  }
  for (final (x, y) in _handle) {
    o[cellAt(lx + x, ly + y)] = 0.78;
  }
  o[cellAt(lx + 1, ly)] = 1.3;
}

void glyph(double t, Float32List o, PatternContext ctx) {
  final u = mod(t, _glyphPeriod);
  final second = u >= _glyphHold + _glyphSweep;
  final local = second ? u - _glyphHold - _glyphSweep : u;
  final from = second ? _glyphWen : _glyphA;
  final to = second ? _glyphA : _glyphWen;
  final sweeping = local >= _glyphHold;
  final col = sweeping ? ((local - _glyphHold) / _glyphSweep * 10).floor() - 1 : -2;
  for (var i = 0; i < cellCount; i++) {
    final x = cellX(i);
    final y = cellY(i);
    final on = x < col ? to[i] : from[i];
    final shimmer = 0.92 + 0.08 * math.sin(t * 3.1 - x * 0.7 + y * 0.4);
    o[i] = on != 0 ? shimmer : 0;
    if (x == col) o[i] = from[i] != 0 || to[i] != 0 ? 1.5 : 1.05;
  }
}

void sort(double t, Float32List o, PatternContext ctx) {
  clear(o);
  final step = (t / _sortStep).floor();
  final round = (step / _sortSlots).floor();
  final frame = _insertionSortAt(_shuffled(round), step % _sortSlots);
  final sweep = frame.doneFor >= 0 && frame.doneFor < 9 ? frame.doneFor : -1;
  for (var x = 0; x < frame.bars.length; x++) {
    final v = x == frame.hot
        ? 1.45
        : x == frame.cmp
        ? 1.05
        : x == sweep
        ? 1.3
        : 0.78;
    for (var y = gridSize - frame.bars[x]; y < gridSize; y++) {
      o[cellAt(x, y)] = v;
    }
  }
}

void rocket(double t, Float32List o, PatternContext ctx) {
  clear(o);
  final launch = (t / _rocketPeriod).floor();
  final u = t - launch * _rocketPeriod;
  final x = 3 + launch % 2;
  final charge = u < _rocketIgnite ? u / _rocketIgnite : 1 - (u - _rocketIgnite) / (_rocketPeriod - _rocketIgnite);
  final flying = u >= _rocketIgnite && u < _rocketIgnite + _rocketFlight;
  final s = (u - _rocketIgnite) / _rocketFlight;
  for (var px = x - 2; px <= x + 2; px++) {
    final near = (px - x).abs();
    final blast = flying && s < 0.25 && near <= 1 ? 1.3 : 0.0;
    light(o, px, 7, math.max(blast, 0.5 + 0.35 * charge - near * 0.06));
  }
  if (u < _rocketIgnite) {
    final flicker = math.sin(t * 31) > 0 ? 1.0 : 0.6;
    light(o, x, 6, 0.6 + 0.85 * charge * flicker);
    return;
  }
  if (!flying) return;
  final head = (6 - s * s * 10).floor();
  light(o, x, head, 1.5);
  light(o, x, head + 1, 1.15);
  for (var k = 2; k < 5; k++) {
    light(o, x, head + k, 0.85 * math.pow(0.6, k - 1));
  }
}

void verified(double t, Float32List o, PatternContext ctx) {
  final phase = mod(t, _ringPeriod) / _ringPeriod;
  final r = 1.2 + phase * 3.6;
  final fade = 1 - phase;
  for (var i = 0; i < cellCount; i++) {
    final d = hypot(cellX(i) - gridCenter, cellY(i) - gridCenter);
    final ring = math.exp(-((d - r) * (d - r)) / 0.35) * 0.55 * fade;
    o[i] = ring > 0.06 ? ring + 0.08 : (hash(i, 13) > 0.7 ? 0.12 : 0);
  }
  final drawn = t * 11;
  for (var k = 0; k < _check.length; k++) {
    if (k >= drawn) continue;
    final (x, y) = _check[k];
    o[cellAt(x, y)] = k + 1 > drawn ? 1.5 : 1.25 + 0.15 * math.sin(t * 2.4 - k * 0.5);
  }
}
