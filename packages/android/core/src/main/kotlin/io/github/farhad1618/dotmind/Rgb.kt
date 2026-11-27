package io.github.farhad1618.dotmind

public data class Rgb(val red: Double, val green: Double, val blue: Double) {
    public constructor(red: Int, green: Int, blue: Int) : this(red.toDouble(), green.toDouble(), blue.toDouble())

    public fun mix(other: Rgb, amount: Double): Rgb = Rgb(
        red + (other.red - red) * amount,
        green + (other.green - green) * amount,
        blue + (other.blue - blue) * amount,
    )
}
