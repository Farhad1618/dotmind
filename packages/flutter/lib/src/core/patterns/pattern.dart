import 'dart:typed_data';

final class PatternContext {
  PatternContext({this.energy = 0, this.progress = 0});

  double energy;
  double progress;
}

typedef Pattern = void Function(double t, Float32List out, PatternContext ctx);
