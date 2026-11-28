import 'dart:math' as math;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../core/cell_shape.dart';
import 'dot_matrix_controller.dart';
import 'dot_matrix_painter.dart';
import 'viewport_visibility.dart';

const double _maxFrameSeconds = 0.05;

BorderRadius wellRadius(CellShape shape, double side) =>
    BorderRadius.circular(side * (shape == CellShape.square ? 0.14 : 0.24));

bool _isForeground(AppLifecycleState? state) => switch (state) {
  null || AppLifecycleState.resumed || AppLifecycleState.inactive => true,
  AppLifecycleState.hidden || AppLifecycleState.paused || AppLifecycleState.detached => false,
};

class DotMatrix extends StatefulWidget {
  const DotMatrix({
    super.key,
    required this.controller,
    required this.size,
    required this.well,
    this.shape = CellShape.dot,
    this.still = false,
  });

  final DotMatrixController controller;
  final double size;
  final Color well;
  final CellShape shape;
  final bool still;

  @override
  State<DotMatrix> createState() => _DotMatrixState();
}

class _DotMatrixState extends State<DotMatrix> with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_onTick);
  late final AppLifecycleListener _lifecycle;
  late DotMatrixPainter _painter;
  final ViewportVisibility _visibility = ViewportVisibility();
  bool _foreground = true;
  Duration _last = Duration.zero;

  @override
  void initState() {
    super.initState();
    _foreground = _isForeground(WidgetsBinding.instance.lifecycleState);
    _lifecycle = AppLifecycleListener(onStateChange: _onLifecycle);
    _painter = DotMatrixPainter(widget.controller, shape: widget.shape);
    widget.controller.attach(_isLive);
    _visibility.addListener(_sync);
    _sync();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _visibility.track(context);
  }

  @override
  void didUpdateWidget(DotMatrix oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.detach();
      widget.controller.attach(_isLive);
    }
    if (oldWidget.controller != widget.controller || oldWidget.shape != widget.shape) {
      _painter = DotMatrixPainter(widget.controller, shape: widget.shape);
    }
    _sync();
  }

  @override
  void dispose() {
    widget.controller.detach();
    _visibility.dispose();
    _lifecycle.dispose();
    _ticker.dispose();
    super.dispose();
  }

  bool _isLive() => _ticker.isTicking;

  void _onLifecycle(AppLifecycleState state) {
    final foreground = _isForeground(state);
    if (foreground == _foreground) return;
    _foreground = foreground;
    _sync();
  }

  void _sync() {
    final run = _foreground && _visibility.visible && !widget.still;
    if (run && !_ticker.isActive) {
      _last = Duration.zero;
      _ticker.start();
    } else if (!run && _ticker.isActive) {
      _ticker.stop();
    }
  }

  void _onTick(Duration elapsed) {
    final dt = math.min(_maxFrameSeconds, (elapsed - _last).inMicroseconds / 1e6);
    _last = elapsed;
    widget.controller.advance(dt);
  }

  @override
  Widget build(BuildContext context) {
    _visibility.scheduleCheck(context);
    final side = widget.size;
    return ClipRRect(
      borderRadius: wellRadius(widget.shape, side),
      child: ColoredBox(
        color: widget.well,
        child: RepaintBoundary(
          child: CustomPaint(size: Size.square(side), painter: _painter),
        ),
      ),
    );
  }
}
