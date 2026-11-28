package io.github.farhad1618.dotmind.pattern

import kotlin.math.abs
import kotlin.math.floor
import kotlin.math.max
import kotlin.math.min

internal object Neural : Pattern {
    private val NODE_X = intArrayOf(1, 6, 3, 0, 7, 5, 2)
    private val NODE_Y = intArrayOf(0, 1, 3, 5, 4, 6, 7)
    private val EDGE_FROM = intArrayOf(0, 1, 1, 2, 2, 2, 3, 4, 5)
    private val EDGE_TO = intArrayOf(2, 2, 4, 3, 4, 5, 6, 5, 6)
    private val FORWARD: Array<IntArray> = Array(EDGE_FROM.size) { e ->
        line(NODE_X[EDGE_FROM[e]], NODE_Y[EDGE_FROM[e]], NODE_X[EDGE_TO[e]], NODE_Y[EDGE_TO[e]])
    }
    private val BACKWARD: Array<IntArray> = Array(FORWARD.size) { FORWARD[it].reversedArray() }
    private const val FIRE_STEP = 0.35
    private const val FIRE_MEMORY = 6
    private const val SIGNAL_SECONDS = 0.47

    override fun render(t: Double, out: FloatArray, context: PatternContext) {
        out.fill(0f)
        for (cells in FORWARD) out.raiseAll(cells, 0.52)
        for (e in FORWARD.indices) {
            signal(out, FORWARD[e], nodeAge(EDGE_FROM[e], t))
            signal(out, BACKWARD[e], nodeAge(EDGE_TO[e], t))
        }
        for (n in NODE_X.indices) {
            out[cellAt(NODE_X[n], NODE_Y[n])] = (0.84 + 0.66 * exp(-nodeAge(n, t) * 3.2)).toFloat()
        }
    }

    private fun signal(out: FloatArray, path: IntArray, age: Double) {
        if (age >= SIGNAL_SECONDS) return
        val k = floor((age / SIGNAL_SECONDS) * path.size).toInt()
        out.raise(path[min(path.size - 1, k)], 1.15)
    }

    private fun firedAt(node: Int, step: Int): Boolean {
        if (floor(hash(step, 3.0) * NODE_X.size).toInt() == node) return true
        return hash(step, 4.0) > 0.55 && floor(hash(step, 5.0) * NODE_X.size).toInt() == node
    }

    private fun nodeAge(node: Int, t: Double): Double {
        val now = floor(t / FIRE_STEP).toInt()
        for (k in now downTo now - FIRE_MEMORY + 1) {
            if (firedAt(node, k)) return t - k * FIRE_STEP
        }
        return Double.POSITIVE_INFINITY
    }
}

internal object Magnifier : Pattern {
    private val SPECKS = BooleanArray(CELLS) { hash(it, 11.0) > 0.8 }
    private val LENS = Cells.bitmap(".##.", "#..#", "#..#", ".##.")
    private val LENS_INSIDE = Cells.path(1 to 1, 2 to 1, 1 to 2, 2 to 2)
    private val HANDLE = Cells.path(3 to 3, 4 to 4)

    override fun render(t: Double, out: FloatArray, context: PatternContext) {
        for (i in 0 until CELLS) out[i] = if (SPECKS[i]) 0.2f else 0f
        val lx = jsRound(1.6 + 1.6 * sin(t * 0.83)).toInt()
        val ly = jsRound(1.5 + 1.5 * sin(t * 1.21 + 1.3)).toInt()
        val origin = cellAt(lx, ly)
        for (cell in LENS_INSIDE) {
            val i = origin + cell
            out[i] = if (SPECKS[i]) 1.45f else 0.1f
        }
        for (cell in LENS) out[origin + cell] = 1f
        for (cell in HANDLE) out[origin + cell] = 0.78f
        out[origin + 1] = 1.3f
    }
}

internal object Glyph : Pattern {
    private const val HOLD = 1.6
    private const val SWEEP = 0.95
    private const val PERIOD = 2 * (HOLD + SWEEP)
    private val LATIN = mask(
        "...##...",
        "..#..#..",
        ".#....#.",
        ".#....#.",
        ".######.",
        ".#....#.",
        ".#....#.",
        ".#....#.",
    )
    private val WEN = mask(
        "...##...",
        "########",
        ".#....#.",
        "..#..#..",
        "...##...",
        "..#..#..",
        ".##..##.",
        "##....##",
    )

    override fun render(t: Double, out: FloatArray, context: PatternContext) {
        val u = positiveMod(t, PERIOD)
        val second = u >= HOLD + SWEEP
        val local = if (second) u - HOLD - SWEEP else u
        val from = if (second) WEN else LATIN
        val to = if (second) LATIN else WEN
        val col = if (local >= HOLD) floor(((local - HOLD) / SWEEP) * 10).toInt() - 1 else -2
        for (i in 0 until CELLS) {
            val x = i % GRID
            val y = i / GRID
            val on = if (x < col) to[i] else from[i]
            val shimmer = 0.92 + 0.08 * sin(t * 3.1 - x * 0.7 + y * 0.4)
            out[i] = if (on) shimmer.toFloat() else 0f
            if (x == col) out[i] = if (from[i] || to[i]) 1.5f else 1.05f
        }
    }

    private fun mask(vararg rows: String): BooleanArray {
        val mask = BooleanArray(CELLS)
        for (cell in Cells.bitmap(*rows)) mask[cell] = true
        return mask
    }
}

internal object Sort : Pattern {
    private const val STEP = 0.16
    private const val SLOTS = 40
    private const val BARS = 8

    override fun render(t: Double, out: FloatArray, context: PatternContext) {
        out.fill(0f)
        val step = floor(t / STEP)
        val round = floor(step / SLOTS).toInt()
        val target = positiveMod(step, SLOTS.toDouble()).toInt()
        var bars = shuffled(round)
        var hot = -1
        var cmp = -1
        var count = 0
        sorting@ for (i in 1 until BARS) {
            var j = i
            while (j > 0 && bar(bars, j - 1) > bar(bars, j)) {
                if (count == target) {
                    hot = j
                    cmp = j - 1
                    break@sorting
                }
                bars = swap(bars, j - 1, j)
                count++
                j--
            }
        }
        val doneFor = if (hot < 0) target - count else -1
        val sweep = if (doneFor in 0 until 9) doneFor else -1
        for (x in 0 until BARS) {
            val v = when (x) {
                hot -> 1.45f
                cmp -> 1.05f
                sweep -> 1.3f
                else -> 0.78f
            }
            for (y in GRID - bar(bars, x) until GRID) out[cellAt(x, y)] = v
        }
    }

    private fun shuffled(seed: Int): Int {
        var bars = 0
        for (i in 0 until BARS) bars = bars or ((i + 1) shl (i * 4))
        for (i in BARS - 1 downTo 1) {
            val j = floor(hash(seed * BARS + i, 9.0) * (i + 1)).toInt()
            bars = swap(bars, i, j)
        }
        return bars
    }

    private fun bar(bars: Int, index: Int): Int = (bars ushr (index * 4)) and 0xF

    private fun swap(bars: Int, a: Int, b: Int): Int {
        if (a == b) return bars
        val va = bar(bars, a)
        val vb = bar(bars, b)
        val cleared = bars and ((0xF shl (a * 4)) or (0xF shl (b * 4))).inv()
        return cleared or (vb shl (a * 4)) or (va shl (b * 4))
    }
}

internal object Rocket : Pattern {
    private const val PERIOD = 2.6
    private const val IGNITE = 0.75
    private const val FLIGHT = 1.15

    override fun render(t: Double, out: FloatArray, context: PatternContext) {
        out.fill(0f)
        val launch = floor(t / PERIOD)
        val u = t - launch * PERIOD
        val x = 3 + positiveMod(launch, 2.0).toInt()
        val charge = if (u < IGNITE) u / IGNITE else 1 - (u - IGNITE) / (PERIOD - IGNITE)
        val flying = u >= IGNITE && u < IGNITE + FLIGHT
        val s = (u - IGNITE) / FLIGHT
        for (px in x - 2..x + 2) {
            val near = abs(px - x)
            val blast = if (flying && s < 0.25 && near <= 1) 1.3 else 0.0
            out.light(px, 7, max(blast, 0.5 + 0.35 * charge - near * 0.06))
        }
        if (u < IGNITE) {
            val flicker = if (sin(t * 31) > 0) 1.0 else 0.6
            out.light(x, 6, 0.6 + 0.85 * charge * flicker)
            return
        }
        if (!flying) return
        val head = floor(6 - s * s * 10).toInt()
        out.light(x, head, 1.5)
        out.light(x, head + 1, 1.15)
        for (k in 2 until 5) out.light(x, head + k, 0.85 * pow(0.6, k - 1))
    }
}

internal object Verified : Pattern {
    private const val RING_PERIOD = 1.45
    private val SPECKS = BooleanArray(CELLS) { hash(it, 13.0) > 0.7 }

    override fun render(t: Double, out: FloatArray, context: PatternContext) {
        val phase = positiveMod(t, RING_PERIOD) / RING_PERIOD
        val r = 1.2 + phase * 3.6
        val fade = 1 - phase
        for (i in 0 until CELLS) {
            val d = hypot((i % GRID) - CENTER_OFFSET, (i / GRID) - CENTER_OFFSET)
            val ring = exp(-((d - r) * (d - r)) / 0.35) * 0.55 * fade
            out[i] = if (ring > 0.06) (ring + 0.08).toFloat() else if (SPECKS[i]) 0.12f else 0f
        }
        val drawn = t * 11
        val stroke = Cells.CHECK_STROKE
        for (k in stroke.indices) {
            if (k < drawn) out[stroke[k]] = (if (k + 1 > drawn) 1.5 else 1.25 + 0.15 * sin(t * 2.4 - k * 0.5)).toFloat()
        }
    }
}
