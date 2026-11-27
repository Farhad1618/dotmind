import 'package:flutter/foundation.dart';

import '../core/patterns/grid.dart';
import '../core/renderer.dart';
import '../core/rgb.dart';
import '../core/scene.dart';
import 'repaint_signal.dart';
import 'shimmer_driver.dart';

bool _never() => false;

final class DotMatrixController implements ShimmerDriver {
  DotMatrixController([Scene scene = Scene.breathe]) : renderer = DotRenderer(scene);

  final DotRenderer renderer;
  final RepaintSignal repaint = RepaintSignal();
  final Float32List values = Float32List(cellCount);
  final Float64List rgb = Float64List(3);
  bool drawn = false;
  bool still = false;
  @override
  double elapsed = 0;
  bool Function() _isLive = _never;
  bool _presented = false;
  Scene? _lastScene;
  Rgb? _lastColor;
  int? _lastProgress;
  bool _lastStill = false;

  @override
  Listenable get tick => repaint;

  bool get isLive => _isLive();

  void attach(bool Function() isLive) => _isLive = isLive;

  void detach() => _isLive = _never;

  void present(Scene scene, Rgb color, int? progress) {
    if (_presented &&
        scene == _lastScene &&
        color == _lastColor &&
        progress == _lastProgress &&
        still == _lastStill) {
      return;
    }
    _presented = true;
    _lastScene = scene;
    _lastColor = color;
    _lastProgress = progress;
    _lastStill = still;
    renderer.feed(progress);
    renderer.show(scene, color: color, instant: !drawn || !_isLive());
    if (still) settle();
    repaint.ping();
  }

  void settle() {
    renderer.step(1.2);
    renderer.step(0.5);
  }

  void advance(double dt) {
    renderer.step(dt);
    elapsed += dt;
    repaint.ping();
  }

  void dispose() => repaint.dispose();
}
