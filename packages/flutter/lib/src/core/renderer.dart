import 'dart:math' as math;
import 'dart:typed_data';

import 'patterns/catalog.dart';
import 'patterns/grid.dart';
import 'patterns/pattern.dart';
import 'rgb.dart';
import 'scene.dart';

const double blendSeconds = 0.35;

final class _Layer {
  _Layer(this.scene, this.color);

  Scene scene;
  Rgb color;
  double t = 0;
  double origin = 0;
  final PatternContext context = PatternContext();

  void reset(Scene nextScene, Rgb nextColor, double nextOrigin) {
    scene = nextScene;
    color = nextColor;
    t = 0;
    origin = nextOrigin;
  }
}

final class DotRenderer {
  DotRenderer([Scene scene = Scene.breathe, Rgb? color])
    : _current = _Layer(scene, color ?? sceneColor(scene)),
      _previous = _Layer(scene, color ?? sceneColor(scene));

  _Layer _current;
  _Layer _previous;
  bool _blending = false;
  double _blend = 1;
  final Float32List _cur = Float32List(cellCount);
  final Float32List _prev = Float32List(cellCount);
  double _energy = 0.3;
  double _rate = 0;
  double? _lastProgress;
  double _lastProgressAt = 0;
  double _synthetic = 0;
  double _clock = 0;
  bool _hasProgress = false;

  Scene get scene => _current.scene;

  double get level => _energy;

  double get clock => _clock;

  bool get isBlending => _blending;

  void show(Scene scene, {Rgb? color, bool instant = false}) {
    final next = color ?? sceneColor(scene);
    if (scene == _current.scene) {
      _current.color = next;
      return;
    }
    final origin = _progressNow();
    final outgoing = _current;
    _current = _previous;
    _previous = outgoing;
    _current.reset(scene, next, origin);
    _blending = !instant;
    _blend = instant ? 1 : 0;
  }

  void feed(num? progress) {
    if (progress == null) {
      _hasProgress = false;
      return;
    }
    final p = progress.toDouble();
    _hasProgress = true;
    final last = _lastProgress;
    if (last == null || p < last) {
      _lastProgress = p;
      _lastProgressAt = _clock;
      _rate = 0;
      _current.origin = math.min(_current.origin, p);
      return;
    }
    if (p == last) return;
    final dt = math.max(1 / 60, _clock - _lastProgressAt);
    final inst = (p - last) / dt;
    _rate = _rate * 0.7 + inst * 0.3;
    _lastProgress = p;
    _lastProgressAt = _clock;
  }

  void step(double dt) {
    _clock += dt;
    if (_clock - _lastProgressAt > 0.45) _rate *= math.exp(-dt * 3);
    final target = clampTo(0.3 + _rate / 160, 0.3, 1.5);
    _energy += (target - _energy) * (1 - math.exp(-dt * 6));
    final speed = 0.6 + 0.6 * _energy;
    _current.t += dt * speed;
    if (_blending) _previous.t += dt * speed;
    _synthetic += dt * 40 * speed;
    if (_blending) {
      _blend = math.min(1, _blend + dt / blendSeconds);
      if (_blend >= 1) _blending = false;
    }
  }

  Float32List sample([Float32List? out]) {
    final target = out ?? Float32List(cellCount);
    final now = _progressNow();
    _render(_current, _cur, now);
    if (!_blending) {
      target.setAll(0, _cur);
      return target;
    }
    _render(_previous, _prev, now);
    final k = _easedBlend();
    for (var i = 0; i < cellCount; i++) {
      target[i] = _prev[i] * (1 - k) + _cur[i] * k;
    }
    return target;
  }

  Rgb color() => _blending ? _previous.color.mix(_current.color, _easedBlend()) : _current.color;

  void writeColor(Float64List out) {
    final to = _current.color;
    if (!_blending) {
      out[0] = to.r;
      out[1] = to.g;
      out[2] = to.b;
      return;
    }
    final from = _previous.color;
    final k = _easedBlend();
    out[0] = from.r + (to.r - from.r) * k;
    out[1] = from.g + (to.g - from.g) * k;
    out[2] = from.b + (to.b - from.b) * k;
  }

  void _render(_Layer layer, Float32List buffer, double now) {
    final ctx = layer.context
      ..energy = _energy
      ..progress = math.max(0, now - layer.origin);
    patternFor(layer.scene)(layer.t, buffer, ctx);
  }

  double _progressNow() => _hasProgress ? (_lastProgress ?? 0) : _synthetic;

  double _easedBlend() {
    final k = _blend;
    return k * k * (3 - 2 * k);
  }
}
