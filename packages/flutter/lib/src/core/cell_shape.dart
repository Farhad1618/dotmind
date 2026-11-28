enum CellShape {
  dot(size: 0.68, corner: 0.5, base: 0.14),
  square(size: 0.8, corner: 0.22, base: 0.2);

  const CellShape({required this.size, required this.corner, required this.base});

  final double size;
  final double corner;
  final double base;
}
