package io.github.farhad1618.dotmind.pattern

import kotlin.math.floor
import kotlin.math.max

internal object Type : Pattern {
    override fun render(t: Double, out: FloatArray, context: PatternContext) {
        out.fill(0f)
        val total = floor(context.progress / 4).toInt()
        var line = 0
        var used = 0
        while (used + lineLength(line) <= total) {
            used += lineLength(line)
            line++
        }
        val pos = total - used
        val first = max(0, line - 7)
        for (k in first..line) {
            val row = k - first
            val n = if (k < line) lineLength(k) else pos
            val value = if (k == line) 0.85f else 0.5f
            for (x in 0 until n) out[cellAt(x, row)] = value
            if (k == line && pos < GRID) out[cellAt(pos, row)] = if (sin(t * 10) > -0.2) 1.45f else 0.25f
        }
    }

    private fun lineLength(k: Int): Int = 3 + floor(hash(k, 7.0) * 5).toInt()
}

internal object Halo : Pattern {
    override fun render(t: Double, out: FloatArray, context: PatternContext) {
        out.fill(0f)
        out.trail(Cells.RING12, t * 10, 6, 0.68)
        out.raiseAll(Cells.CENTER, 0.15 + (0.5 + 0.5 * sin(t * 2.2)) * 0.35)
    }
}

internal object Cross : Pattern {
    override fun render(t: Double, out: FloatArray, context: PatternContext) {
        out.fill(0f)
        val flash = if (t < 0.9) {
            if (sin(t * 22) > 0) 1.4 else 0.35
        } else {
            0.85 + 0.15 * sin(t * 2)
        }
        out.raiseAll(Cells.CROSS, flash)
    }
}

internal object Check : Pattern {
    override fun render(t: Double, out: FloatArray, context: PatternContext) {
        out.fill(0f)
        val drawn = t * 14
        val settled = if (t > 1.2) 0.8 + 0.1 * sin(t * 2) else 1.1
        for (k in Cells.CHECK_STROKE.indices) {
            if (k < drawn) out[Cells.CHECK_STROKE[k]] = (if (k + 1 > drawn) 1.45 else settled).toFloat()
        }
    }
}
