import 'dart:typed_data';
import 'dart:ui';

import '../core/patterns/grid.dart';

const int _levels = 128;
const double _maxValue = 1.5;
const double _baseAlpha = 0.14;

double _whiteness(double v) => clampTo((v - 0.85) / 0.55, 0, 1);

double _levelValue(int level) => level * _maxValue / (_levels - 1);

final class DotPaintTable {
  DotPaintTable() {
    for (var q = 0; q < _levels; q++) {
      _scale[q] = 1 + _whiteness(_levelValue(q)) * 0.12;
    }
  }

  final Float64List _scale = Float64List(_levels);
  final List<MaskFilter?> _blur = List<MaskFilter?>.filled(_levels, null);
  final List<Color?> _glow = List<Color?>.filled(_levels, null);
  final List<Color?> _dot = List<Color?>.filled(_levels, null);
  final Int32List _stamp = Int32List(_levels);
  int _generation = 0;
  int _r = -1;
  int _g = -1;
  int _b = -1;
  Color _base = const Color(0x00000000);

  Color get baseColor => _base;

  void layout(double radius) {
    for (var q = 0; q < _levels; q++) {
      final sigma = radius * (1.5 + 2.5 * _whiteness(_levelValue(q))) / 2;
      _blur[q] = MaskFilter.blur(BlurStyle.normal, sigma);
    }
  }

  void useColor(int r, int g, int b) {
    if (r == _r && g == _g && b == _b) return;
    _r = r;
    _g = g;
    _b = b;
    _generation++;
    _base = Color.fromARGB((_baseAlpha * 255 + 0.5).floor(), r, g, b);
  }

  int levelFor(double v) =>
      clampIndex((clampTo(v, 0, _maxValue) * (_levels - 1) / _maxValue + 0.5).floor(), 0, _levels - 1);

  double scale(int level) => _scale[level];

  MaskFilter blur(int level) => _blur[level]!;

  Color glowColor(int level) {
    _ensure(level);
    return _glow[level]!;
  }

  Color dotColor(int level) {
    _ensure(level);
    return _dot[level]!;
  }

  void _ensure(int level) {
    if (_stamp[level] == _generation) return;
    final v = _levelValue(level);
    final w = _whiteness(v);
    final alpha = (clampTo(v, 0, 1) * 255 + 0.5).floor();
    _glow[level] = Color.fromARGB(alpha, _r, _g, _b);
    _dot[level] = Color.fromARGB(
      alpha,
      (_r + (255 - _r) * w).toInt(),
      (_g + (255 - _g) * w).toInt(),
      (_b + (255 - _b) * w).toInt(),
    );
    _stamp[level] = _generation;
  }
}
