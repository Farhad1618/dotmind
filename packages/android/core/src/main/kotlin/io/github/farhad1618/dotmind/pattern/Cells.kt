package io.github.farhad1618.dotmind.pattern

internal object Cells {
    val RING12: IntArray = path(2 to 2, 3 to 2, 4 to 2, 5 to 2, 5 to 3, 5 to 4, 5 to 5, 4 to 5, 3 to 5, 2 to 5, 2 to 4, 2 to 3)

    val CENTER: IntArray = path(3 to 3, 4 to 3, 3 to 4, 4 to 4)

    val PERIMETER: IntArray = buildList {
        for (x in 0 until GRID) add(cellAt(x, 0))
        for (y in 1 until GRID) add(cellAt(GRID - 1, y))
        for (x in GRID - 2 downTo 0) add(cellAt(x, GRID - 1))
        for (y in GRID - 2 downTo 1) add(cellAt(0, y))
    }.toIntArray()

    val SERPENT: IntArray = buildList {
        for (x in 1 until GRID) {
            for (k in 0 until GRID) add(cellAt(x, if (x % 2 == 1) k else GRID - 1 - k))
        }
        for (y in GRID - 1 downTo 0) add(cellAt(0, y))
    }.toIntArray()

    val CODE: IntArray = bitmap(
        "........",
        "..#..#..",
        ".#....#.",
        "#......#",
        ".#....#.",
        "..#..#..",
        "........",
        "........",
    )

    val PAGE: IntArray = bitmap(
        ".####...",
        ".#..##..",
        ".#...##.",
        ".#....#.",
        ".#....#.",
        ".#....#.",
        ".#....#.",
        ".######.",
    )

    val PAGE_LINES: Array<IntArray> = arrayOf(
        path(2 to 3, 3 to 3, 4 to 3, 5 to 3),
        path(2 to 4, 3 to 4, 4 to 4),
        path(2 to 5, 3 to 5, 4 to 5, 5 to 5),
        path(2 to 6, 3 to 6),
    )

    val CROSS: IntArray = bitmap(
        "........",
        ".#....#.",
        "..#..#..",
        "...##...",
        "...##...",
        "..#..#..",
        ".#....#.",
        "........",
    )

    val CHECK_STROKE: IntArray = path(1 to 4, 2 to 5, 3 to 6, 4 to 5, 5 to 4, 6 to 3, 7 to 2)

    val DISKS: Array<IntArray> = Array(3) { k ->
        val y = k * 3
        IntArray(12) { j -> if (j < 6) cellAt(j + 1, y) else cellAt(j - 5, y + 1) }
    }

    private fun path(vararg cells: Pair<Int, Int>): IntArray =
        IntArray(cells.size) { cellAt(cells[it].first, cells[it].second) }

    private fun bitmap(vararg rows: String): IntArray = buildList {
        rows.forEachIndexed { y, row -> row.forEachIndexed { x, ch -> if (ch == '#') add(cellAt(x, y)) } }
    }.toIntArray()
}
