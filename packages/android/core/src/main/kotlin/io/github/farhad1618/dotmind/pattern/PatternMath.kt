package io.github.farhad1618.dotmind.pattern

import kotlin.math.floor

public const val GRID: Int = 8
public const val CELLS: Int = GRID * GRID

internal const val CENTER_OFFSET: Double = 3.5
internal const val TAU: Double = Math.PI * 2

internal fun clamp(value: Double, low: Double, high: Double): Double =
    if (value < low) low else if (value > high) high else value

internal fun jsRound(value: Double): Double = floor(value + 0.5)

internal fun positiveMod(value: Double, modulus: Double): Double = ((value % modulus) + modulus) % modulus

internal fun wrapAngle(angle: Double): Double = positiveMod(angle, TAU)

internal fun hash(index: Int, seed: Double): Double {
    val x = StrictMath.sin(index * 127.1 + seed * 311.7) * 43758.5453
    return x - floor(x)
}

internal fun sin(x: Double): Double = StrictMath.sin(x)

internal fun cos(x: Double): Double = StrictMath.cos(x)

internal fun exp(x: Double): Double = StrictMath.exp(x)

internal fun atan2(y: Double, x: Double): Double = StrictMath.atan2(y, x)

internal fun hypot(x: Double, y: Double): Double = StrictMath.hypot(x, y)

internal fun pow(base: Double, exponent: Int): Double {
    var result = 1.0
    repeat(exponent) { result *= base }
    return result
}

internal fun cellAt(x: Int, y: Int): Int = y * GRID + x

internal fun FloatArray.raise(index: Int, value: Double) {
    if (value > this[index]) this[index] = value.toFloat()
}

internal fun FloatArray.raiseAll(cells: IntArray, value: Double) {
    for (cell in cells) raise(cell, value)
}

internal fun FloatArray.trail(path: IntArray, head: Double, length: Int, decay: Double) {
    val n = path.size.toDouble()
    val start = floor(head)
    for (k in 0 until length) {
        val index = positiveMod(start - k, n).toInt()
        raise(path[index], if (k == 0) 1.4 else pow(decay, k) * 1.05)
    }
}
