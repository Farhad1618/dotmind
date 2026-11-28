package io.github.farhad1618.dotmind

import io.github.farhad1618.dotmind.pattern.GRID

public object DotGeometry {
    public const val PADDING: Double = 0.12
    public const val RADIUS: Double = 0.34
    public const val BASE_ALPHA: Double = 0.14
    public const val MIN_LIT: Double = 0.03
    public const val MAX_VALUE: Double = 1.5

    public fun padding(side: Double): Double = side * PADDING

    public fun step(side: Double): Double = (side - padding(side) * 2) / (GRID - 1)

    public fun radius(side: Double): Double = step(side) * RADIUS

    public fun half(side: Double, shape: DotShape): Double = step(side) * shape.size / 2

    public fun cornerRadius(half: Double, shape: DotShape): Double = half * 2 * shape.corner

    public fun whiteness(value: Double): Double = ((value - 0.85) / 0.55).coerceIn(0.0, 1.0)

    public fun alpha(value: Double): Double = value.coerceIn(0.0, 1.0)

    public fun glowRadius(half: Double, whiteness: Double): Double = half * (1.5 + 2.5 * whiteness)

    public fun litRadius(half: Double, whiteness: Double): Double = half * (1 + 0.12 * whiteness)

    public fun toward(channel: Double, whiteness: Double): Double = channel + (255 - channel) * whiteness

    public fun glow(color: Rgb): Rgb = Rgb((color.red + 510) / 3, (color.green + 510) / 3, (color.blue + 510) / 3)
}
