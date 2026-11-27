import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';

import 'shimmer_colors.dart';
import 'shimmer_driver.dart';

enum ShimmerMode { off, still, moving }

const List<double> _stops = [0, 0.38, 0.47, 0.52, 0.62, 1];
const double _bandWidth = 2.6;
const double _startPosition = 1.3;
const double _travel = 1.6;
const double _stillPosition = 0.5;
const String _ellipsis = '…';

class ShimmerRenderBox extends RenderBox {
  ShimmerRenderBox({
    required String text,
    required TextStyle style,
    required TextDirection textDirection,
    required TextScaler textScaler,
    required this._colors,
    required this._period,
    required this._driver,
    required this._mode,
  }) : _painter = TextPainter(
         text: TextSpan(text: text, style: style),
         textDirection: textDirection,
         textScaler: textScaler,
         maxLines: 1,
         ellipsis: _ellipsis,
       );

  final TextPainter _painter;
  final Paint _layerPaint = Paint();
  final Paint _bandPaint = Paint()..blendMode = BlendMode.srcIn;
  ShimmerColors _colors;
  Duration _period;
  ShimmerDriver _driver;
  ShimmerMode _mode;
  Rect _bounds = Rect.zero;
  Size _shaderSize = Size.zero;
  ShimmerColors? _shaderColors;

  String get text => (_painter.text! as TextSpan).text!;

  set text(String value) {
    if (value == text) return;
    _painter.text = TextSpan(text: value, style: _painter.text!.style);
    markNeedsLayout();
  }

  set style(TextStyle value) {
    final span = _painter.text! as TextSpan;
    if (value == span.style) return;
    _painter.text = TextSpan(text: span.text, style: value);
    markNeedsLayout();
  }

  set textDirection(TextDirection value) {
    if (value == _painter.textDirection) return;
    _painter.textDirection = value;
    markNeedsLayout();
  }

  set textScaler(TextScaler value) {
    if (value == _painter.textScaler) return;
    _painter.textScaler = value;
    markNeedsLayout();
  }

  set colors(ShimmerColors value) {
    if (value == _colors) return;
    _colors = value;
    markNeedsPaint();
  }

  set period(Duration value) {
    if (value == _period) return;
    _period = value;
    markNeedsPaint();
  }

  set driver(ShimmerDriver value) {
    if (identical(value, _driver)) return;
    _unlisten();
    _driver = value;
    _listen();
    markNeedsPaint();
  }

  set mode(ShimmerMode value) {
    if (value == _mode) return;
    _unlisten();
    _mode = value;
    _listen();
    markNeedsPaint();
  }

  @override
  bool get isRepaintBoundary => true;

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _listen();
  }

  @override
  void detach() {
    _unlisten();
    super.detach();
  }

  @override
  void dispose() {
    _painter.dispose();
    super.dispose();
  }

  void _listen() {
    if (attached && _mode == ShimmerMode.moving) _driver.tick.addListener(markNeedsPaint);
  }

  void _unlisten() {
    if (_mode == ShimmerMode.moving) _driver.tick.removeListener(markNeedsPaint);
  }

  Size _measure(BoxConstraints constraints) {
    _painter.layout(maxWidth: constraints.maxWidth);
    return constraints.constrain(_painter.size);
  }

  @override
  double computeMinIntrinsicWidth(double height) => computeMaxIntrinsicWidth(height);

  @override
  double computeMaxIntrinsicWidth(double height) {
    _painter.layout();
    return _painter.maxIntrinsicWidth;
  }

  @override
  double computeMinIntrinsicHeight(double width) => computeMaxIntrinsicHeight(width);

  @override
  double computeMaxIntrinsicHeight(double width) {
    _painter.layout(maxWidth: width);
    return _painter.height;
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) => _measure(constraints);

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) {
    _painter.layout(maxWidth: constraints.maxWidth);
    return _painter.computeDistanceToActualBaseline(baseline);
  }

  @override
  void performLayout() {
    size = _measure(constraints);
    _bounds = Offset.zero & size;
  }

  void _prepareShader() {
    if (size == _shaderSize && _colors == _shaderColors) return;
    _shaderSize = size;
    _shaderColors = _colors;
    _bandPaint.shader = ui.Gradient.linear(Offset.zero, Offset(size.width * _bandWidth, 0), _colors.bands, _stops);
  }

  double _position() {
    if (_mode == ShimmerMode.still) return _stillPosition;
    final period = _period.inMicroseconds / 1e6;
    if (period <= 0) return _stillPosition;
    return _startPosition - _travel * ((_driver.elapsed % period) / period);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final canvas = context.canvas;
    if (_mode == ShimmerMode.off) {
      _painter.paint(canvas, offset);
      return;
    }
    if (size.isEmpty) return;
    _prepareShader();
    canvas
      ..save()
      ..translate(offset.dx, offset.dy)
      ..saveLayer(_bounds, _layerPaint);
    _painter.paint(canvas, Offset.zero);
    canvas
      ..translate(-size.width * _travel * _position(), 0)
      ..drawPaint(_bandPaint)
      ..restore()
      ..restore();
  }
}
