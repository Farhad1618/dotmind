import 'dart:math' as math;
import 'dart:typed_data';

import 'grid.dart';
import 'pattern.dart';

final List<Cell> _bugHead = bitmap(const ['........', '........', '..####..', '.######.']);
final List<Cell> _bugAbdomen = bitmap(const [
  '........',
  '........',
  '........',
  '........',
  '.######.',
  '.######.',
  '..####..',
]);
const List<Cell> _bugAntennae = [(1, 0), (2, 1), (6, 0), (5, 1)];
const List<Cell> _bugEyes = [(2, 3), (5, 3)];
const List<List<Cell>> _bugLegs = [
  [(0, 3), (7, 3), (0, 5), (7, 5), (1, 7), (6, 7)],
  [(0, 4), (7, 4), (0, 6), (7, 6), (2, 7), (5, 7)],
];
final List<Cell> _bugSprite = List.unmodifiable([..._bugHead, ..._bugAbdomen, ..._bugAntennae, ..._bugLegs[0]]);
const double _bugPeriod = 6.3;
const double _bugSparkle = 0.9;
const double _bugScan = 1.6;
const double _bugForm = 2.5;
const double _bugFade = 5.2;

void _sparkle(Float32List o, double t, double amount) {
  final k = (t / 0.35).floor();
  for (var i = 0; i < cellCount; i++) {
    if (hash(i, k) > 1 - 0.14 * amount) o[i] = math.max(o[i], 0.35 + 0.6 * hash(i, k + 0.5));
  }
}

typedef _Piece = ({List<Cell> cells, int start, int land, int y});

const List<(List<String>, int)> _blockDrops = [
  (['##', '##'], 0),
  (['####'], 4),
  (['##', '##'], 2),
  (['####'], 4),
  (['#..', '###'], 0),
  (['..#', '###'], 3),
  (['##', '##'], 6),
  (['####'], 1),
  (['##', '##'], 0),
  (['#', '#', '#'], 2),
  (['###'], 3),
  (['##', '##'], 6),
  (['###'], 3),
  (['.#.', '###'], 3),
];

final List<_Piece> _blockPieces = () {
  final board = Uint8List(cellCount);
  final pieces = <_Piece>[];
  var clock = 0;
  for (final (rows, x) in _blockDrops) {
    final shape = bitmap(rows);
    bool fits(int y) =>
        shape.every((c) => y + c.$2 < gridSize && (y + c.$2 < 0 || board[cellAt(x + c.$1, y + c.$2)] == 0));
    var y = -rows.length;
    while (fits(y + 1)) {
      y++;
    }
    if (y < 0) break;
    for (final (cx, cy) in shape) {
      board[cellAt(x + cx, y + cy)] = 1;
    }
    final fall = y + rows.length;
    pieces.add((
      cells: List<Cell>.unmodifiable([for (final (cx, cy) in shape) (x + cx, cy)]),
      start: clock,
      land: clock + fall,
      y: y,
    ));
    clock += fall + 1;
  }
  return List<_Piece>.unmodifiable(pieces);
}();
const double _blockStep = 0.075;
final int _blockFilled = _blockPieces.last.land + 1;
const int _blockFlash = 4;
const int _blockClear = 8;
final int _blockCycle = _blockFilled + _blockFlash + _blockClear;

const double _scanRow = 0.4;
const double _scanPass = _scanRow * 8;

void bug(double t, Float32List o, PatternContext ctx) {
  clear(o);
  final u = mod(t, _bugPeriod);
  if (u < _bugSparkle) {
    _sparkle(o, t, 1);
    return;
  }
  if (u < _bugScan) {
    _sparkle(o, t, 0.6);
    final row = ((u - _bugSparkle) / (_bugScan - _bugSparkle) * 8).floor();
    for (var x = 0; x < gridSize; x++) {
      light(o, x, row, 1);
      light(o, x, row - 1, 0.45);
    }
    return;
  }
  final legs = _bugLegs[(t / 0.3).floor() % 2];
  if (u < _bugForm) {
    final s = (u - _bugScan) / (_bugForm - _bugScan);
    _sparkle(o, t, 1 - s);
    for (final (x, y) in _bugSprite) {
      if (hash(cellAt(x, y), 21) < s * 1.15) light(o, x, y, 0.85);
    }
    return;
  }
  if (u >= _bugFade) {
    final s = (u - _bugFade) / (_bugPeriod - _bugFade);
    _sparkle(o, t, s);
    for (final (x, y) in _bugSprite) {
      if (hash(cellAt(x, y), 21) >= s) light(o, x, y, 0.85 * (1 - s * 0.5));
    }
    return;
  }
  lightCells(o, _bugHead, 0.95);
  for (final (x, y) in _bugAbdomen) {
    light(o, x, y, x == 3 || x == 4 ? 0.6 : 0.85);
  }
  lightCells(o, _bugAntennae, 0.8);
  lightCells(o, legs, 0.8);
  final blink = u > 3.9 && u < 4.08;
  for (final (x, y) in _bugEyes) {
    o[cellAt(x, y)] = blink ? 0.95 : 1.5;
  }
  final (px, py) = _bugAbdomen[(hash((t / 0.35).floor(), 23) * _bugAbdomen.length).floor()];
  light(o, px, py, 1.3);
}

void blocks(double t, Float32List o, PatternContext ctx) {
  clear(o);
  final step = (t / _blockStep).floor() % _blockCycle;
  final flashing = step >= _blockFilled && step < _blockFilled + _blockFlash;
  final cleared = step - _blockFilled - _blockFlash;
  for (final piece in _blockPieces) {
    if (step < piece.start) break;
    final landed = step >= piece.land;
    final y = landed ? piece.y : piece.y - (piece.land - step);
    final fresh = landed && step - piece.land < 2;
    var v = !landed
        ? 1.1
        : fresh
        ? 1.35
        : 0.72;
    if (flashing) v = step.isOdd ? 1.4 : 0.9;
    for (final (x, cy) in piece.cells) {
      if (cleared >= 0 && y + cy >= gridSize - cleared) continue;
      light(o, x, y + cy, cleared >= 0 ? 0.72 * (1 - cleared / _blockClear) + 0.1 : v);
    }
  }
}

void scan(double t, Float32List o, PatternContext ctx) {
  final pass = (t / _scanPass).floor();
  final u = t - pass * _scanPass;
  final row = (u / _scanRow).floor();
  final cursor = ((u - row * _scanRow) / _scanRow * 9).floor() - 1;
  final noise = (t / 1.3).floor();
  for (var i = 0; i < cellCount; i++) {
    final x = cellX(i);
    final y = cellY(i);
    final h = hash(i, noise + pass * 17);
    var v = h > 0.62 ? 0.06 + 0.22 * h : 0.0;
    if (y < row) v = hash(i, pass + 31) > 0.5 ? 0.42 + (y == row - 1 ? 0.22 : 0) : 0;
    if (y == row) {
      v = x < cursor
          ? 0.98
          : x == cursor
          ? 1.5
          : v;
    }
    o[i] = v;
  }
}
