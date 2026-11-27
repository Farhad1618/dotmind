package io.github.farhad1618.dotmind.pattern

import kotlin.math.abs
import kotlin.math.floor
import kotlin.math.max
import kotlin.math.min
import kotlin.math.sqrt

internal object Radar : Pattern {
    override fun render(t: Double, out: FloatArray, context: PatternContext) {
        val sweep = t * TAU / 1.6
        val turn = floor(sweep / TAU)
        for (i in 0 until CELLS) {
            val dx = (i % GRID) - CENTER_OFFSET
            val dy = (i / GRID) - CENTER_OFFSET
            val r = hypot(dx, dy)
            if (r > 4) {
                out[i] = 0f
                continue
            }
            val behind = wrapAngle(sweep - atan2(dy, dx))
            var v = 0.1 + 1.1 * exp(-behind * 2.4) * (0.4 + r / 6)
            if (hash(i, turn) > 0.9 && behind < 3) v = max(v, 1.4 * exp(-behind * 0.8))
            out[i] = v.toFloat()
        }
    }
}

internal object Globe : Pattern {
    private val HALVES = doubleArrayOf(0.0, Math.PI)

    override fun render(t: Double, out: FloatArray, context: PatternContext) {
        out.fill(0f)
        for (i in 0 until CELLS) {
            val y = i / GRID
            val r = hypot((i % GRID) - CENTER_OFFSET, y - CENTER_OFFSET)
            if (abs(r - 3.2) < 0.7) out[i] = 0.35f
            if (y == 3 || y == 4) out.raise(i, if (r < 3.6) 0.22 else 0.0)
        }
        for (offset in HALVES) {
            val s = sin(t * 1.8 + offset)
            val front = cos(t * 1.8 + offset) > 0
            for (y in 0 until GRID) {
                val dy = y - CENTER_OFFSET
                val w = sqrt(max(0.0, 12.25 - dy * dy))
                val x = jsRound(CENTER_OFFSET + w * s)
                if (x < 0 || x > 7) continue
                out.raise(cellAt(x.toInt(), y), if (front) 1.3 else 0.45)
            }
        }
    }
}

internal object Code : Pattern {
    override fun render(t: Double, out: FloatArray, context: PatternContext) {
        out.fill(0f)
        out.raiseAll(Cells.CODE, 0.7)
        val typed = floor((context.progress * 0.2 + t * 3) % 6).toInt()
        val shown = min(typed, 4)
        for (k in 0 until shown) out[cellAt(2 + k, 3)] = 0.85f
        val cursor = 2 + shown
        if (cursor <= 5) out[cellAt(cursor, 3)] = if (sin(t * 9) > 0) 1.45f else 0.3f
    }
}

internal object Pages : Pattern {
    override fun render(t: Double, out: FloatArray, context: PatternContext) {
        out.fill(0f)
        out.raiseAll(Cells.PAGE, 0.55)
        val beat = t * 1.8
        val line = (floor(beat) % (Cells.PAGE_LINES.size + 1)).toInt()
        for (k in Cells.PAGE_LINES.indices) {
            val cells = Cells.PAGE_LINES[k]
            if (k < line) out.raiseAll(cells, 0.75)
            if (k == line) {
                val head = (beat - floor(beat)) * cells.size
                val lead = floor(head).toInt()
                for (j in cells.indices) {
                    if (j <= head) out[cells[j]] = if (j == lead) 1.4f else 0.9f
                }
            }
        }
    }
}

internal object Stack : Pattern {
    override fun render(t: Double, out: FloatArray, context: PatternContext) {
        out.fill(0f)
        val beat = t * 2.2
        val active = (floor(beat) % 3).toInt()
        val frac = beat - floor(beat)
        for (k in Cells.DISKS.indices) {
            out.raiseAll(Cells.DISKS[k], if (k == active) 0.95 else 0.28)
            if (k == active) {
                val x = 1 + floor(frac * 6).toInt()
                out[cellAt(x, k * 3)] = 1.45f
                out[cellAt(7 - x, k * 3 + 1)] = 1.2f
            }
        }
    }
}

internal object Prism : Pattern {
    override fun render(t: Double, out: FloatArray, context: PatternContext) {
        val s = 0.5 + 0.5 * sin(t * 2.1)
        val r = 1 + 2.6 * s
        for (i in 0 until CELLS) {
            val dx = abs((i % GRID) - CENTER_OFFSET)
            val dy = abs((i / GRID) - CENTER_OFFSET)
            val m = dx + dy
            val on = exp(-((m - r) * (m - r)) / 0.18)
            val axis = if (dx < 1 || dy < 1) 0.45 else 0.0
            out[i] = (on * (0.75 + axis + (1 - s) * 0.3)).toFloat()
        }
    }
}

internal object Circuit : Pattern {
    override fun render(t: Double, out: FloatArray, context: PatternContext) {
        out.fill(0f)
        out.trail(Cells.PERIMETER, t * 13, 9, 0.8)
        out.raiseAll(Cells.CENTER, 0.25 + (0.5 + 0.5 * sin(t * 4)) * 0.9)
    }
}
