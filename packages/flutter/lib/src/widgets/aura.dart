import 'package:flutter/widgets.dart';

import '../core/rgb.dart';

const Duration auraFade = Duration(milliseconds: 350);

typedef AuraBuilder = Widget Function(BuildContext context, Color aura, Widget? child);

Color auraColor(Rgb color, {required bool on}) =>
    Color.fromARGB(on ? 255 : 0, color.r.toInt(), color.g.toInt(), color.b.toInt());

List<BoxShadow> pillAura(Color aura) => aura.a == 0
    ? const []
    : [
        BoxShadow(color: aura.withValues(alpha: aura.a * 0.55), blurRadius: 24, spreadRadius: -6),
        BoxShadow(color: aura.withValues(alpha: aura.a * 0.2), blurRadius: 72, spreadRadius: 8),
      ];

List<BoxShadow> wellAura(Color aura) =>
    aura.a == 0 ? const [] : [BoxShadow(color: aura.withValues(alpha: aura.a * 0.55), blurRadius: 18, spreadRadius: 2)];

class AuraTransition extends StatelessWidget {
  const AuraTransition({super.key, required this.color, required this.animate, required this.builder, this.child});

  final Color color;
  final bool animate;
  final AuraBuilder builder;
  final Widget? child;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<Color?>(
    tween: ColorTween(end: color),
    duration: animate ? auraFade : Duration.zero,
    curve: Curves.ease,
    builder: (context, value, child) => builder(context, value ?? color, child),
    child: child,
  );
}
