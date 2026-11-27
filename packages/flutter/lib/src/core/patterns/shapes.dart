import 'grid.dart';

List<int> _bitmap(List<String> rows) {
  final cells = <int>[];
  for (var y = 0; y < rows.length; y++) {
    for (var x = 0; x < rows[y].length; x++) {
      if (rows[y][x] == '#') cells.add(cellAt(x, y));
    }
  }
  return List.unmodifiable(cells);
}

List<int> _points(List<(int, int)> points) => List.unmodifiable(points.map((p) => cellAt(p.$1, p.$2)));

final List<int> ring12 = _points(const [
  (2, 2),
  (3, 2),
  (4, 2),
  (5, 2),
  (5, 3),
  (5, 4),
  (5, 5),
  (4, 5),
  (3, 5),
  (2, 5),
  (2, 4),
  (2, 3),
]);

final List<int> centerCells = _points(const [(3, 3), (4, 3), (3, 4), (4, 4)]);

final List<int> perimeter = () {
  final p = <(int, int)>[];
  for (var x = 0; x < 8; x++) {
    p.add((x, 0));
  }
  for (var y = 1; y < 8; y++) {
    p.add((7, y));
  }
  for (var x = 6; x >= 0; x--) {
    p.add((x, 7));
  }
  for (var y = 6; y > 0; y--) {
    p.add((0, y));
  }
  return _points(p);
}();

final List<int> serpentPath = () {
  final p = <(int, int)>[];
  for (var x = 1; x < 8; x++) {
    for (var k = 0; k < 8; k++) {
      p.add((x, x.isOdd ? k : 7 - k));
    }
  }
  for (var y = 7; y >= 0; y--) {
    p.add((0, y));
  }
  return _points(p);
}();

final List<int> codeBrackets = _bitmap(const [
  '........',
  '..#..#..',
  '.#....#.',
  '#......#',
  '.#....#.',
  '..#..#..',
  '........',
  '........',
]);

final List<int> pageOutline = _bitmap(const [
  '.####...',
  '.#..##..',
  '.#...##.',
  '.#....#.',
  '.#....#.',
  '.#....#.',
  '.#....#.',
  '.######.',
]);

final List<List<int>> pageLines = List.unmodifiable([
  _points(const [(2, 3), (3, 3), (4, 3), (5, 3)]),
  _points(const [(2, 4), (3, 4), (4, 4)]),
  _points(const [(2, 5), (3, 5), (4, 5), (5, 5)]),
  _points(const [(2, 6), (3, 6)]),
]);

final List<int> crossMark = _bitmap(const [
  '........',
  '.#....#.',
  '..#..#..',
  '...##...',
  '...##...',
  '..#..#..',
  '.#....#.',
  '........',
]);

final List<int> checkStroke = _points(const [(1, 4), (2, 5), (3, 6), (4, 5), (5, 4), (6, 3), (7, 2)]);

final List<List<int>> disks = List.unmodifiable([
  for (final y in const [0, 3, 6])
    _points([for (var x = 1; x <= 6; x++) (x, y), for (var x = 1; x <= 6; x++) (x, y + 1)]),
]);
