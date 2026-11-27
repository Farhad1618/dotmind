package io.github.farhad1618.dotmind.pattern

import kotlin.math.abs
import kotlin.math.max
import kotlin.math.min

internal object Breathe : Pattern {
    override fun render(t: Double, out: FloatArray, context: PatternContext) {
        out.fill(0f)
        val p = 0.5 + 0.5 * sin(t * 1.6)
        out.raiseAll(Cells.CENTER, 0.18 + p * 0.5)
    }
}

internal object Comet : Pattern {
    override fun render(t: Double, out: FloatArray, context: PatternContext) {
        out.fill(0f)
        for (k in 0 until 14) {
            val a = t * 2.6 - k * 0.17
            val x = jsRound(CENTER_OFFSET + 3.2 * sin(a))
            val y = jsRound(CENTER_OFFSET + 3.1 * sin(2 * a))
            val cell = cellAt(clamp(x, 0.0, 7.0).toInt(), clamp(y, 0.0, 7.0).toInt())
            out.raise(cell, if (k == 0) 1.45 else pow(0.8, k))
        }
    }
}

internal object Ember : Pattern {
    override fun render(t: Double, out: FloatArray, context: PatternContext) {
        val hx = CENTER_OFFSET + 2.4 * sin(t * 1.3)
        val hy = CENTER_OFFSET + 2.4 * sin(t * 1.9 + 1)
        for (i in 0 until CELLS) {
            val x = (i % GRID).toDouble()
            val y = (i / GRID).toDouble()
            val flicker = pow(max(0.0, sin(t * (2 + hash(i, 1.0) * 3) + hash(i, 2.0) * TAU)), 6) * 0.75
            val glow = 1.35 * exp(-((x - hx) * (x - hx) + (y - hy) * (y - hy)) / 1.1)
            out[i] = min(1.5, 0.12 + flicker + glow).toFloat()
        }
    }
}

internal object Orbit : Pattern {
    override fun render(t: Double, out: FloatArray, context: PatternContext) {
        val head = t * TAU / 1.5
        for (i in 0 until CELLS) {
            val dx = (i % GRID) - CENTER_OFFSET
            val dy = (i / GRID) - CENTER_OFFSET
            out[i] = if (abs(hypot(dx, dy) - 3.1) > 0.75) {
                0f
            } else {
                (0.22 + 1.25 * exp(-wrapAngle(head - atan2(dy, dx)) * 1.1)).toFloat()
            }
        }
    }
}

internal object Serpent : Pattern {
    override fun render(t: Double, out: FloatArray, context: PatternContext) {
        out.fill(0f)
        out.trail(Cells.SERPENT, t * 11, 9, 0.78)
    }
}

internal object Pulse : Pattern {
    override fun render(t: Double, out: FloatArray, context: PatternContext) {
        for (x in 0 until GRID) {
            val h = 1 + 6.5 * (0.5 + 0.5 * sin(t * 3.1 + x * 0.8) * cos(t * 1.3 - x * 0.35))
            for (y in 0 until GRID) {
                val up = (GRID - 1 - y).toDouble()
                out[cellAt(x, y)] = if (up < h - 1) 0.7f else if (up < h) 1.4f else 0f
            }
        }
    }
}

