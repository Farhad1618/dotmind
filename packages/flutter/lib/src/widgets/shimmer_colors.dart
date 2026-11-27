import 'dart:ui';

import 'package:flutter/foundation.dart';

@immutable
final class ShimmerColors {
  const ShimmerColors(this.ink, this.peak, this.glow);

  final Color ink;
  final Color peak;
  final Color glow;

  List<Color> get bands => [ink, ink, peak, glow, ink, ink];

  @override
  bool operator ==(Object other) => other is ShimmerColors && other.ink == ink && other.peak == peak && other.glow == glow;

  @override
  int get hashCode => Object.hash(ink, peak, glow);
}
