import Foundation

enum PixelPatterns {
    private static let bugHead = GridPoint.bitmap([
        "........",
        "........",
        "..####..",
        ".######.",
    ])
    private static let bugAbdomen = GridPoint.bitmap([
        "........",
        "........",
        "........",
        "........",
        ".######.",
        ".######.",
        "..####..",
    ])
    private static let bugAntennae = GridPoint.list([(1, 0), (2, 1), (6, 0), (5, 1)])
    private static let bugEyes = GridPoint.list([(2, 3), (5, 3)])
    private static let bugLegs = [
        GridPoint.list([(0, 3), (7, 3), (0, 5), (7, 5), (1, 7), (6, 7)]),
        GridPoint.list([(0, 4), (7, 4), (0, 6), (7, 6), (2, 7), (5, 7)]),
    ]
    private static let bugSprite = bugHead + bugAbdomen + bugAntennae + bugLegs[0]
    private static let bugPeriod = 6.3
    private static let bugSparkle = 0.9
    private static let bugScan = 1.6
    private static let bugForm = 2.5
    private static let bugFade = 5.2

    private struct Piece {
        var cells: [GridPoint]
        var start: Int
        var land: Int
        var y: Int
    }

    private static let blockDrops: [(rows: [String], x: Int)] = [
        (["##", "##"], 0),
        (["####"], 4),
        (["##", "##"], 2),
        (["####"], 4),
        (["#..", "###"], 0),
        (["..#", "###"], 3),
        (["##", "##"], 6),
        (["####"], 1),
        (["##", "##"], 0),
        (["#", "#", "#"], 2),
        (["###"], 3),
        (["##", "##"], 6),
        (["###"], 3),
        ([".#.", "###"], 3),
    ]
    private static let blockPieces = stackPieces()
    private static let blockStep = 0.075
    private static let blockFilled = (blockPieces.last?.land ?? 0) + 1
    private static let blockFlash = 4
    private static let blockClear = 8
    private static let blockCycle = blockFilled + blockFlash + blockClear

    private static let scanRow = 0.4
    private static let scanPass = scanRow * 8

    static func bug(_ t: Double, _ out: inout [Double]) {
        clear(&out)
        let u = positiveModulo(t, bugPeriod)
        if u < bugSparkle {
            sparkle(&out, t, 1)
            return
        }
        if u < bugScan {
            sparkle(&out, t, 0.6)
            let row = floorInt((u - bugSparkle) / (bugScan - bugSparkle) * 8)
            for x in 0..<Grid.side {
                light(&out, x, row, 1)
                light(&out, x, row - 1, 0.45)
            }
            return
        }
        if u < bugForm {
            let s = (u - bugScan) / (bugForm - bugScan)
            sparkle(&out, t, 1 - s)
            for point in bugSprite where dotHash(point.index, 21) < s * 1.15 {
                light(&out, point.x, point.y, 0.85)
            }
            return
        }
        if u >= bugFade {
            let s = (u - bugFade) / (bugPeriod - bugFade)
            sparkle(&out, t, s)
            for point in bugSprite where dotHash(point.index, 21) >= s {
                light(&out, point.x, point.y, 0.85 * (1 - s * 0.5))
            }
            return
        }
        light(&out, bugHead, 0.95)
        for point in bugAbdomen {
            light(&out, point.x, point.y, point.x == 3 || point.x == 4 ? 0.6 : 0.85)
        }
        light(&out, bugAntennae, 0.8)
        light(&out, bugLegs[positiveModulo(floorInt(t / 0.3), bugLegs.count)], 0.8)
        let blink = u > 3.9 && u < 4.08
        for point in bugEyes { out[point.index] = blink ? 0.95 : 1.5 }
        let pick = floorInt(dotHash(floorInt(t / 0.35), 23) * Double(bugAbdomen.count))
        let pulse = bugAbdomen[pick]
        light(&out, pulse.x, pulse.y, 1.3)
    }

    static func blocks(_ t: Double, _ out: inout [Double]) {
        clear(&out)
        let step = positiveModulo(floorInt(t / blockStep), blockCycle)
        let flashing = step >= blockFilled && step < blockFilled + blockFlash
        let cleared = step - blockFilled - blockFlash
        for piece in blockPieces {
            if step < piece.start { break }
            let landed = step >= piece.land
            let y = landed ? piece.y : piece.y - (piece.land - step)
            let fresh = landed && step - piece.land < 2
            var value = !landed ? 1.1 : fresh ? 1.35 : 0.72
            if flashing { value = step % 2 == 1 ? 1.4 : 0.9 }
            for point in piece.cells {
                if cleared >= 0 && y + point.y >= Grid.side - cleared { continue }
                let shown = cleared >= 0 ? 0.72 * (1 - Double(cleared) / Double(blockClear)) + 0.1 : value
                light(&out, point.x, y + point.y, shown)
            }
        }
    }

    static func scan(_ t: Double, _ out: inout [Double]) {
        let pass = floor(t / scanPass)
        let u = t - pass * scanPass
        let row = floorInt(u / scanRow)
        let cursor = floorInt((u - Double(row) * scanRow) / scanRow * 9) - 1
        let noise = floor(t / 1.3)
        for index in 0..<Grid.cells {
            let x = index % Grid.side
            let y = index / Grid.side
            let h = dotHash(index, noise + pass * 17)
            var value = h > 0.62 ? 0.06 + 0.22 * h : 0
            if y < row { value = dotHash(index, pass + 31) > 0.5 ? 0.42 + (y == row - 1 ? 0.22 : 0) : 0 }
            if y == row { value = x < cursor ? 0.98 : x == cursor ? 1.5 : value }
            out[index] = value
        }
    }

    private static func sparkle(_ out: inout [Double], _ t: Double, _ amount: Double) {
        let k = floor(t / 0.35)
        for index in 0..<Grid.cells where dotHash(index, k) > 1 - 0.14 * amount {
            out[index] = max(out[index], 0.35 + 0.6 * dotHash(index, k + 0.5))
        }
    }

    private static func stackPieces() -> [Piece] {
        var board = [Bool](repeating: false, count: Grid.cells)
        var pieces: [Piece] = []
        var clock = 0
        for drop in blockDrops {
            let shape = GridPoint.bitmap(drop.rows)
            let height = drop.rows.count
            func fits(_ y: Int) -> Bool {
                shape.allSatisfy { point in
                    let row = y + point.y
                    return row < Grid.side && (row < 0 || !board[cell(drop.x + point.x, row)])
                }
            }
            var y = -height
            while fits(y + 1) { y += 1 }
            if y < 0 { break }
            for point in shape { board[cell(drop.x + point.x, y + point.y)] = true }
            let fall = y + height
            pieces.append(Piece(
                cells: shape.map { GridPoint(drop.x + $0.x, $0.y) },
                start: clock,
                land: clock + fall,
                y: y
            ))
            clock += fall + 1
        }
        return pieces
    }
}
