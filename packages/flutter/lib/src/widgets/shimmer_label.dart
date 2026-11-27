import 'package:flutter/widgets.dart';

import 'shimmer_colors.dart';
import 'shimmer_driver.dart';
import 'shimmer_render_box.dart';

export 'shimmer_render_box.dart' show ShimmerMode;

class ShimmerLabel extends LeafRenderObjectWidget {
  const ShimmerLabel({
    super.key,
    required this.text,
    required this.style,
    required this.ink,
    required this.peak,
    required this.glow,
    required this.period,
    required this.driver,
    this.mode = ShimmerMode.moving,
  });

  final String text;
  final TextStyle style;
  final Color ink;
  final Color peak;
  final Color glow;
  final Duration period;
  final ShimmerDriver driver;
  final ShimmerMode mode;

  TextStyle _resolve(BuildContext context) {
    final merged = DefaultTextStyle.of(context).style.merge(style);
    return merged.copyWith(color: mode == ShimmerMode.off ? ink : const Color(0xFFFFFFFF));
  }

  @override
  ShimmerRenderBox createRenderObject(BuildContext context) => ShimmerRenderBox(
    text: text,
    style: _resolve(context),
    textDirection: Directionality.of(context),
    textScaler: MediaQuery.maybeTextScalerOf(context) ?? TextScaler.noScaling,
    colors: ShimmerColors(ink, peak, glow),
    period: period,
    driver: driver,
    mode: mode,
  );

  @override
  void updateRenderObject(BuildContext context, ShimmerRenderBox renderObject) {
    renderObject
      ..text = text
      ..style = _resolve(context)
      ..textDirection = Directionality.of(context)
      ..textScaler = MediaQuery.maybeTextScalerOf(context) ?? TextScaler.noScaling
      ..colors = ShimmerColors(ink, peak, glow)
      ..period = period
      ..driver = driver
      ..mode = mode;
  }
}
