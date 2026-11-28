package io.github.farhad1618.dotmind.pattern

import kotlin.math.floor

internal object Bug : Pattern {
    private const val PERIOD = 6.3
    private const val SPARKLE = 0.9
    private const val SCAN = 1.6
    private const val FORM = 2.5
    private const val FADE = 5.2
    private val HEAD = Cells.bitmap(
        "........",
        "........",
        "..####..",
        ".######.",
    )
    private val ABDOMEN = Cells.bitmap(
        "........",
        "........",
        "........",
        "........",
        ".######.",
        ".######.",
        "..####..",
    )
    private val ANTENNAE = Cells.path(1 to 0, 2 to 1, 6 to 0, 5 to 1)
    private val EYES = Cells.path(2 to 3, 5 to 3)
    private val LEGS: Array<IntArray> = arrayOf(
        Cells.path(0 to 3, 7 to 3, 0 to 5, 7 to 5, 1 to 7, 6 to 7),
        Cells.path(0 to 4, 7 to 4, 0 to 6, 7 to 6, 2 to 7, 5 to 7),
    )
    private val SPRITE = HEAD + ABDOMEN + ANTENNAE + LEGS[0]
    private val REVEAL = DoubleArray(SPRITE.size) { hash(SPRITE[it], 21.0) }

    override fun render(t: Double, out: FloatArray, context: PatternContext) {
        out.fill(0f)
        val u = positiveMod(t, PERIOD)
        if (u < SPARKLE) {
            sparkle(out, t, 1.0)
            return
        }
        if (u < SCAN) {
            sparkle(out, t, 0.6)
            val row = floor(((u - SPARKLE) / (SCAN - SPARKLE)) * GRID).toInt()
            for (x in 0 until GRID) {
                out.light(x, row, 1.0)
                out.light(x, row - 1, 0.45)
            }
            return
        }
        if (u < FORM) {
            val s = (u - SCAN) / (FORM - SCAN)
            sparkle(out, t, 1 - s)
            for (k in SPRITE.indices) if (REVEAL[k] < s * 1.15) out.raise(SPRITE[k], 0.85)
            return
        }
        if (u >= FADE) {
            val s = (u - FADE) / (PERIOD - FADE)
            sparkle(out, t, s)
            for (k in SPRITE.indices) if (REVEAL[k] >= s) out.raise(SPRITE[k], 0.85 * (1 - s * 0.5))
            return
        }
        out.raiseAll(HEAD, 0.95)
        for (cell in ABDOMEN) {
            val x = cell % GRID
            out.raise(cell, if (x == 3 || x == 4) 0.6 else 0.85)
        }
        out.raiseAll(ANTENNAE, 0.8)
        out.raiseAll(LEGS[positiveMod(floor(t / 0.3), 2.0).toInt()], 0.8)
        val blink = u > 3.9 && u < 4.08
        for (cell in EYES) out[cell] = if (blink) 0.95f else 1.5f
        val pick = floor(hash(floor(t / 0.35).toInt(), 23.0) * ABDOMEN.size).toInt()
        out.raise(ABDOMEN[pick], 1.3)
    }

    private fun sparkle(out: FloatArray, t: Double, amount: Double) {
        val k = floor(t / 0.35)
        for (i in 0 until CELLS) {
            if (hash(i, k) > 1 - 0.14 * amount) out.raise(i, 0.35 + 0.6 * hash(i, k + 0.5))
        }
    }
}

internal object Blocks : Pattern {
    private const val STEP = 0.075
    private const val FLASH = 4
    private const val CLEAR = 8

    private class Piece(val xs: IntArray, val ys: IntArray, val start: Int, val land: Int, val y: Int)

    private val DROPS: List<Pair<List<String>, Int>> = listOf(
        listOf("##", "##") to 0,
        listOf("####") to 4,
        listOf("##", "##") to 2,
        listOf("####") to 4,
        listOf("#..", "###") to 0,
        listOf("..#", "###") to 3,
        listOf("##", "##") to 6,
        listOf("####") to 1,
        listOf("##", "##") to 0,
        listOf("#", "#", "#") to 2,
        listOf("###") to 3,
        listOf("##", "##") to 6,
        listOf("###") to 3,
        listOf(".#.", "###") to 3,
    )

    private val PIECES: Array<Piece> = stack()
    private val FILLED = PIECES.last().land + 1
    private val CYCLE = FILLED + FLASH + CLEAR

    override fun render(t: Double, out: FloatArray, context: PatternContext) {
        out.fill(0f)
        val step = positiveMod(floor(t / STEP), CYCLE.toDouble()).toInt()
        val flashing = step >= FILLED && step < FILLED + FLASH
        val cleared = step - FILLED - FLASH
        for (piece in PIECES) {
            if (step < piece.start) break
            val landed = step >= piece.land
            val y = if (landed) piece.y else piece.y - (piece.land - step)
            val fresh = landed && step - piece.land < 2
            var v = if (!landed) 1.1 else if (fresh) 1.35 else 0.72
            if (flashing) v = if (step % 2 != 0) 1.4 else 0.9
            for (k in piece.xs.indices) {
                val row = y + piece.ys[k]
                if (cleared >= 0 && row >= GRID - cleared) continue
                out.light(piece.xs[k], row, if (cleared >= 0) 0.72 * (1 - cleared.toDouble() / CLEAR) + 0.1 else v)
            }
        }
    }

    private fun stack(): Array<Piece> {
        val board = BooleanArray(CELLS)
        val pieces = ArrayList<Piece>()
        var clock = 0
        for ((rows, x) in DROPS) {
            val shape = Cells.bitmap(*rows.toTypedArray())
            val cx = IntArray(shape.size) { shape[it] % GRID }
            val cy = IntArray(shape.size) { shape[it] / GRID }
            fun fits(y: Int): Boolean = cx.indices.all { k ->
                val row = y + cy[k]
                row < GRID && (row < 0 || !board[cellAt(x + cx[k], row)])
            }
            var y = -rows.size
            while (fits(y + 1)) y++
            if (y < 0) break
            for (k in cx.indices) board[cellAt(x + cx[k], y + cy[k])] = true
            val fall = y + rows.size
            pieces += Piece(IntArray(cx.size) { x + cx[it] }, cy, clock, clock + fall, y)
            clock += fall + 1
        }
        return pieces.toTypedArray()
    }
}

internal object Scan : Pattern {
    private const val ROW = 0.4
    private const val PASS = ROW * GRID

    override fun render(t: Double, out: FloatArray, context: PatternContext) {
        val pass = floor(t / PASS)
        val u = t - pass * PASS
        val row = floor(u / ROW).toInt()
        val cursor = floor(((u - row * ROW) / ROW) * 9).toInt() - 1
        val noise = floor(t / 1.3)
        for (i in 0 until CELLS) {
            val x = i % GRID
            val y = i / GRID
            val h = hash(i, noise + pass * 17)
            var v = if (h > 0.62) 0.06 + 0.22 * h else 0.0
            if (y < row) v = if (hash(i, pass + 31) > 0.5) 0.42 + (if (y == row - 1) 0.22 else 0.0) else 0.0
            if (y == row) v = if (x < cursor) 0.98 else if (x == cursor) 1.5 else v
            out[i] = v.toFloat()
        }
    }
}
