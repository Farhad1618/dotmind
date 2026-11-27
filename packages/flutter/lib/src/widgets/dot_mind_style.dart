import 'package:flutter/widgets.dart';

@immutable
class DotMindStyle {
  const DotMindStyle({
    this.background = const Color(0xFF0B0B0C),
    this.edge = const Color(0xFF26262A),
    this.well = const Color(0xFF050506),
    this.ink = const Color(0xFF8A8A92),
    this.peak = const Color(0xFFFFFFFF),
    this.textStyle = const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, height: 1.2),
    this.shimmerPeriod = const Duration(milliseconds: 2400),
    this.elevated = true,
  });

  final Color background;
  final Color edge;
  final Color well;
  final Color ink;
  final Color peak;
  final TextStyle textStyle;
  final Duration shimmerPeriod;
  final bool elevated;

  double get fontSize => textStyle.fontSize ?? 15;

  DotMindStyle copyWith({
    Color? background,
    Color? edge,
    Color? well,
    Color? ink,
    Color? peak,
    TextStyle? textStyle,
    Duration? shimmerPeriod,
    bool? elevated,
  }) => DotMindStyle(
    background: background ?? this.background,
    edge: edge ?? this.edge,
    well: well ?? this.well,
    ink: ink ?? this.ink,
    peak: peak ?? this.peak,
    textStyle: textStyle ?? this.textStyle,
    shimmerPeriod: shimmerPeriod ?? this.shimmerPeriod,
    elevated: elevated ?? this.elevated,
  );

  @override
  bool operator ==(Object other) =>
      other is DotMindStyle &&
      other.background == background &&
      other.edge == edge &&
      other.well == well &&
      other.ink == ink &&
      other.peak == peak &&
      other.textStyle == textStyle &&
      other.shimmerPeriod == shimmerPeriod &&
      other.elevated == elevated;

  @override
  int get hashCode => Object.hash(background, edge, well, ink, peak, textStyle, shimmerPeriod, elevated);
}
