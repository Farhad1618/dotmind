import 'dart:math' as math;
import 'dart:typed_data';

const int gridSize = 8;
const int cellCount = gridSize * gridSize;
const double gridCenter = 3.5;
const double tau = math.pi * 2;

double clampTo(double v, double lo, double hi) => v < lo ? lo : (v > hi ? hi : v);

int clampIndex(int v, int lo, int hi) => v < lo ? lo : (v > hi ? hi : v);

double fract(double x) => x - x.floorToDouble();

double hash(num i, num s) => fract(math.sin(i * 127.1 + s * 311.7) * 43758.5453);

int cellAt(int x, int y) => y * gridSize + x;

int cellX(int i) => i % gridSize;

int cellY(int i) => i ~/ gridSize;

double wrapAngle(double a) => ((a % tau) + tau) % tau;

int roundHalfUp(double x) => (x + 0.5).floor();

double powInt(double base, int exponent) {
  var result = 1.0;
  for (var k = 0; k < exponent; k++) {
    result *= base;
  }
  return result;
}

double hypot(double x, double y) => math.sqrt(x * x + y * y);

void clear(Float32List out) => out.fillRange(0, cellCount, 0);

void fillCells(Float32List out, List<int> cells, double v) {
  for (final i in cells) {
    if (out[i] < v) out[i] = v;
  }
}

void trail(Float32List out, List<int> path, double head, int length, double decay) {
  final n = path.length;
  final h = head.floor();
  for (var k = 0; k < length; k++) {
    final i = path[(((h - k) % n) + n) % n];
    final v = k == 0 ? 1.4 : powInt(decay, k) * 1.05;
    if (out[i] < v) out[i] = v;
  }
}

typedef Cell = (int, int);

double mod(double a, double n) => ((a % n) + n) % n;

List<Cell> bitmap(List<String> rows) => List.unmodifiable([
  for (var y = 0; y < rows.length; y++)
    for (var x = 0; x < rows[y].length; x++)
      if (rows[y][x] == '#') (x, y),
]);

void light(Float32List out, int x, int y, double v) {
  if (x < 0 || x >= gridSize || y < 0 || y >= gridSize) return;
  final i = cellAt(x, y);
  if (v > out[i]) out[i] = v;
}

void lightCells(Float32List out, List<Cell> cells, double v) {
  for (final (x, y) in cells) {
    light(out, x, y, v);
  }
}

List<Cell> line(Cell a, Cell b) {
  final cells = <Cell>[];
  var (x0, y0) = a;
  final (x1, y1) = b;
  final dx = (x1 - x0).abs();
  final dy = -(y1 - y0).abs();
  final sx = x0 < x1 ? 1 : -1;
  final sy = y0 < y1 ? 1 : -1;
  var err = dx + dy;
  while (true) {
    cells.add((x0, y0));
    if (x0 == x1 && y0 == y1) return List.unmodifiable(cells);
    final e2 = 2 * err;
    if (e2 >= dy) {
      err += dy;
      x0 += sx;
    }
    if (e2 <= dx) {
      err += dx;
      y0 += sy;
    }
  }
}
