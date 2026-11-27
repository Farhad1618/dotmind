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
