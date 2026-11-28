package io.github.farhad1618.dotmind.compose

import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.drawscope.DrawScope
import io.github.farhad1618.dotmind.DotGeometry
import io.github.farhad1618.dotmind.DotRenderer
import io.github.farhad1618.dotmind.DotShape
import io.github.farhad1618.dotmind.pattern.CELLS
import io.github.farhad1618.dotmind.pattern.GRID
import kotlin.math.min

private const val GLOW_RINGS = 3
private const val GLOW_STRENGTH = 0.22f

internal fun DrawScope.drawDots(renderer: DotRenderer, values: FloatArray, color: DoubleArray, shape: DotShape = DotShape.DOT) {
    renderer.sample(values)
    renderer.colorInto(color)
    val side = min(size.width, size.height).toDouble()
    val pad = DotGeometry.padding(side).toFloat()
    val step = DotGeometry.step(side).toFloat()
    val half = DotGeometry.half(side, shape)
    val r = color[0]
    val g = color[1]
    val b = color[2]
    val base = rgba(r, g, b, shape.baseAlpha)
    for (i in 0 until CELLS) {
        drawCell(base, Offset(pad + (i % GRID) * step, pad + (i / GRID) * step), half, shape)
    }
    for (i in 0 until CELLS) {
        val v = values[i].toDouble().coerceIn(0.0, DotGeometry.MAX_VALUE)
        if (v < DotGeometry.MIN_LIT) continue
        val center = Offset(pad + (i % GRID) * step, pad + (i / GRID) * step)
        val w = DotGeometry.whiteness(v)
        val a = DotGeometry.alpha(v)
        val lit = DotGeometry.litRadius(half, w)
        val glow = DotGeometry.glowRadius(half, w)
        for (ring in GLOW_RINGS downTo 1) {
            val reach = ring.toDouble() / GLOW_RINGS
            val ringAlpha = a * GLOW_STRENGTH * (1 - reach * 0.6)
            drawCell(rgba(r, g, b, ringAlpha), center, lit + (glow - lit) * reach, shape)
        }
        val core = rgba(DotGeometry.toward(r, w), DotGeometry.toward(g, w), DotGeometry.toward(b, w), a)
        drawCell(core, center, lit, shape)
    }
}

private fun DrawScope.drawCell(color: Color, center: Offset, half: Double, shape: DotShape) {
    val h = half.toFloat()
    when (shape) {
        DotShape.DOT -> drawCircle(color, h, center)
        DotShape.SQUARE -> {
            val corner = DotGeometry.cornerRadius(half, shape).toFloat()
            drawRoundRect(
                color = color,
                topLeft = Offset(center.x - h, center.y - h),
                size = Size(h * 2, h * 2),
                cornerRadius = CornerRadius(corner, corner),
            )
        }
    }
}

internal fun rgba(r: Double, g: Double, b: Double, a: Double): Color = Color(
    red = channel(r),
    green = channel(g),
    blue = channel(b),
    alpha = a.toFloat().coerceIn(0f, 1f),
)

private fun channel(value: Double): Float = (value / 255.0).toFloat().coerceIn(0f, 1f)
