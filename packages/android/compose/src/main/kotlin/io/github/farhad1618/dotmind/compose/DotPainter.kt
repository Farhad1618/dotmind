package io.github.farhad1618.dotmind.compose

import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.drawscope.DrawScope
import io.github.farhad1618.dotmind.DotGeometry
import io.github.farhad1618.dotmind.DotRenderer
import io.github.farhad1618.dotmind.pattern.CELLS
import io.github.farhad1618.dotmind.pattern.GRID
import kotlin.math.min

private const val GLOW_RINGS = 3
private const val GLOW_STRENGTH = 0.22f

internal fun DrawScope.drawDots(renderer: DotRenderer, values: FloatArray, color: DoubleArray) {
    renderer.sample(values)
    renderer.colorInto(color)
    val side = min(size.width, size.height).toDouble()
    val pad = DotGeometry.padding(side).toFloat()
    val step = DotGeometry.step(side).toFloat()
    val radius = DotGeometry.radius(side)
    val r = color[0]
    val g = color[1]
    val b = color[2]
    val base = rgba(r, g, b, DotGeometry.BASE_ALPHA)
    for (i in 0 until CELLS) {
        drawCircle(base, radius.toFloat(), Offset(pad + (i % GRID) * step, pad + (i / GRID) * step))
    }
    for (i in 0 until CELLS) {
        val v = values[i].toDouble().coerceIn(0.0, DotGeometry.MAX_VALUE)
        if (v < DotGeometry.MIN_LIT) continue
        val center = Offset(pad + (i % GRID) * step, pad + (i / GRID) * step)
        val w = DotGeometry.whiteness(v)
        val a = DotGeometry.alpha(v)
        val lit = DotGeometry.litRadius(radius, w)
        val glow = DotGeometry.glowRadius(radius, w)
        for (ring in GLOW_RINGS downTo 1) {
            val reach = ring.toDouble() / GLOW_RINGS
            val ringAlpha = a * GLOW_STRENGTH * (1 - reach * 0.6)
            drawCircle(rgba(r, g, b, ringAlpha), (lit + (glow - lit) * reach).toFloat(), center)
        }
        val core = rgba(DotGeometry.toward(r, w), DotGeometry.toward(g, w), DotGeometry.toward(b, w), a)
        drawCircle(core, lit.toFloat(), center)
    }
}

private fun rgba(r: Double, g: Double, b: Double, a: Double): Color = Color(
    red = channel(r),
    green = channel(g),
    blue = channel(b),
    alpha = a.toFloat().coerceIn(0f, 1f),
)

private fun channel(value: Double): Float = (value / 255.0).toFloat().coerceIn(0f, 1f)
