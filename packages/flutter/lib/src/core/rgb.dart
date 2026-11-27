final class Rgb {
  const Rgb(this.r, this.g, this.b);

  final double r;
  final double g;
  final double b;

  Rgb mix(Rgb other, double k) => Rgb(r + (other.r - r) * k, g + (other.g - g) * k, b + (other.b - b) * k);

  @override
  bool operator ==(Object other) => other is Rgb && other.r == r && other.g == g && other.b == b;

  @override
  int get hashCode => Object.hash(r, g, b);

  @override
  String toString() => 'Rgb($r, $g, $b)';
}
