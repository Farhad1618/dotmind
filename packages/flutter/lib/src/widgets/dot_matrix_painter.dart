import 'dart:math' as math;

import 'package:flutter/rendering.dart';

import '../core/patterns/grid.dart';
import 'dot_matrix_controller.dart';
import 'dot_paint_table.dart';

const double _padding = 0.12;
const double _radiusRatio = 0.34;
const double _visible = 0.03;

class DotMatrixPainter extends CustomPainter {
  DotMatrixPainter(this.controller) : super(repaint: controller.repaint);

  final DotMatrixController controller;
  final DotPaintTable _table = DotPaintTable();
  final List<Offset> _centers = List<Offset>.filled(cellCount, Offset.zero);
  final Paint _base = Paint()..isAntiAlias = true;
  final Paint _glow = Paint()..isAntiAlias = true;
  final Paint _dot = Paint()..isAntiAlias = true;
  double _side = -1;
  double _radius = 0;

  void _layout(double side) {
    _side = side;
    final pad = side * _padding;
    final step = (side - pad * 2) / (gridSize - 1);
    _radius = step * _radiusRatio;
    for (var i = 0; i < cellCount; i++) {
      _centers[i] = Offset(pad + cellX(i) * step, pad + cellY(i) * step);
    }
    _table.layout(_radius);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final side = math.min(size.width, size.height);
    if (side <= 0) return;
    if (side != _side) _layout(side);
    final renderer = controller.renderer;
    final values = renderer.sample(controller.values);
    final rgb = controller.rgb;
    renderer.writeColor(rgb);
    _table.useColor(rgb[0].toInt(), rgb[1].toInt(), rgb[2].toInt());
    _base.color = _table.baseColor;
    for (var i = 0; i < cellCount; i++) {
      canvas.drawCircle(_centers[i], _radius, _base);
    }
    for (var i = 0; i < cellCount; i++) {
      final v = clampTo(values[i], 0, 1.5);
      if (v < _visible) continue;
      final level = _table.levelFor(v);
      final radius = _radius * _table.scale(level);
      _glow
        ..color = _table.glowColor(level)
        ..maskFilter = _table.blur(level);
      canvas.drawCircle(_centers[i], radius, _glow);
      _dot.color = _table.dotColor(level);
      canvas.drawCircle(_centers[i], radius, _dot);
    }
    controller.drawn = true;
  }

  @override
  bool shouldRepaint(DotMatrixPainter oldDelegate) => oldDelegate.controller != controller;
}
