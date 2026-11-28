import Foundation

enum IconPatterns {
    private static let nodes = GridPoint.list([(1, 0), (6, 1), (3, 3), (0, 5), (7, 4), (5, 6), (2, 7)])
    private static let edges: [(Int, Int)] = [(0, 2), (1, 2), (1, 4), (2, 3), (2, 4), (2, 5), (3, 6), (4, 5), (5, 6)]
    private static let edgePaths: [(forward: [GridPoint], backward: [GridPoint])] = edges.map { edge in
        let path = GridPoint.line(nodes[edge.0], nodes[edge.1])
        return (path, Array(path.reversed()))
    }
    private static let fireStep = 0.35
    private static let fireMemory = 6
    private static let signalSeconds = 0.47

    private static let lens = GridPoint.bitmap([".##.", "#..#", "#..#", ".##."])
    private static let lensInside = GridPoint.list([(1, 1), (2, 1), (1, 2), (2, 2)])
    private static let handle = GridPoint.list([(3, 3), (4, 4)])

    private static let glyphA = mask([
        "...##...",
        "..#..#..",
        ".#....#.",
        ".#....#.",
        ".######.",
        ".#....#.",
        ".#....#.",
        ".#....#.",
    ])
    private static let glyphWen = mask([
        "...##...",
        "########",
        ".#....#.",
        "..#..#..",
        "...##...",
        "..#..#..",
        ".##..##.",
        "##....##",
    ])
    private static let glyphHold = 1.6
    private static let glyphSweep = 0.95
    private static let glyphPeriod = 2 * (glyphHold + glyphSweep)

    private static let sortStep = 0.16
    private static let sortSlots = 40

    private static let rocketPeriod = 2.6
    private static let rocketIgnite = 0.75
    private static let rocketFlight = 1.15

    private static let ringPeriod = 1.45

    static func neural(_ t: Double, _ out: inout [Double]) {
        clear(&out)
        for path in edgePaths { light(&out, path.forward, 0.52) }
        let ages = nodes.indices.map { nodeAge($0, t) }
        for (edge, path) in zip(edges, edgePaths) {
            for (from, cells) in [(edge.0, path.forward), (edge.1, path.backward)] {
                let age = ages[from]
                if age >= signalSeconds { continue }
                let k = floorInt(age / signalSeconds * Double(cells.count))
                let point = cells[min(cells.count - 1, k)]
                light(&out, point.x, point.y, 1.15)
            }
        }
        for (node, point) in nodes.enumerated() {
            out[point.index] = 0.84 + 0.66 * exp(-ages[node] * 3.2)
        }
    }

    static func magnifier(_ t: Double, _ out: inout [Double]) {
        for index in 0..<Grid.cells { out[index] = dotHash(index, 11) > 0.8 ? 0.2 : 0 }
        let lx = roundHalfUp(1.6 + 1.6 * sin(t * 0.83))
        let ly = roundHalfUp(1.5 + 1.5 * sin(t * 1.21 + 1.3))
        for point in lensInside {
            let index = cell(lx + point.x, ly + point.y)
            out[index] = dotHash(index, 11) > 0.8 ? 1.45 : 0.1
        }
        for point in lens { out[cell(lx + point.x, ly + point.y)] = 1 }
        for point in handle { out[cell(lx + point.x, ly + point.y)] = 0.78 }
        out[cell(lx + 1, ly)] = 1.3
    }

    static func glyph(_ t: Double, _ out: inout [Double]) {
        let u = positiveModulo(t, glyphPeriod)
        let second = u >= glyphHold + glyphSweep
        let local = second ? u - glyphHold - glyphSweep : u
        let from = second ? glyphWen : glyphA
        let to = second ? glyphA : glyphWen
        let column = local >= glyphHold ? floorInt((local - glyphHold) / glyphSweep * 10) - 1 : -2
        for index in 0..<Grid.cells {
            let x = index % Grid.side
            let y = index / Grid.side
            let on = x < column ? to[index] : from[index]
            let shimmer = 0.92 + 0.08 * sin(t * 3.1 - Double(x) * 0.7 + Double(y) * 0.4)
            out[index] = on ? shimmer : 0
            if x == column { out[index] = from[index] || to[index] ? 1.5 : 1.05 }
        }
    }

    static func sort(_ t: Double, _ out: inout [Double]) {
        clear(&out)
        let step = floorInt(t / sortStep)
        let round = floorInt(Double(step) / Double(sortSlots))
        let frame = insertionSort(shuffled(round), stoppingAt: positiveModulo(step, sortSlots))
        let sweep = frame.doneFor >= 0 && frame.doneFor < 9 ? frame.doneFor : -1
        for (x, height) in frame.bars.enumerated() {
            let value = x == frame.hot ? 1.45 : x == frame.compared ? 1.05 : x == sweep ? 1.3 : 0.78
            for y in (Grid.side - height)..<Grid.side { out[cell(x, y)] = value }
        }
    }

    static func rocket(_ t: Double, _ out: inout [Double]) {
        clear(&out)
        let launch = floorInt(t / rocketPeriod)
        let u = t - Double(launch) * rocketPeriod
        let x = 3 + launch % 2
        let charge = u < rocketIgnite
            ? u / rocketIgnite
            : 1 - (u - rocketIgnite) / (rocketPeriod - rocketIgnite)
        let flying = u >= rocketIgnite && u < rocketIgnite + rocketFlight
        let s = (u - rocketIgnite) / rocketFlight
        for px in (x - 2)...(x + 2) {
            let near = abs(px - x)
            let blast = flying && s < 0.25 && near <= 1 ? 1.3 : 0
            light(&out, px, 7, max(blast, 0.5 + 0.35 * charge - Double(near) * 0.06))
        }
        if u < rocketIgnite {
            let flicker = sin(t * 31) > 0 ? 1.0 : 0.6
            light(&out, x, 6, 0.6 + 0.85 * charge * flicker)
            return
        }
        guard flying else { return }
        let head = floorInt(6 - s * s * 10)
        light(&out, x, head, 1.5)
        light(&out, x, head + 1, 1.15)
        for k in 2..<5 { light(&out, x, head + k, 0.85 * pow(0.6, Double(k - 1))) }
    }

    static func verified(_ t: Double, _ out: inout [Double]) {
        let r = 1.2 + positiveModulo(t, ringPeriod) / ringPeriod * 3.6
        let fade = 1 - positiveModulo(t, ringPeriod) / ringPeriod
        for index in 0..<Grid.cells {
            let d = hypot(Double(index % Grid.side) - Grid.center, Double(index / Grid.side) - Grid.center)
            let ring = exp(-((d - r) * (d - r)) / 0.35) * 0.55 * fade
            out[index] = ring > 0.06 ? ring + 0.08 : dotHash(index, 13) > 0.7 ? 0.12 : 0
        }
        let drawn = t * 11
        for (k, index) in Shapes.checkStroke.enumerated() where Double(k) < drawn {
            out[index] = Double(k + 1) > drawn ? 1.5 : 1.25 + 0.15 * sin(t * 2.4 - Double(k) * 0.5)
        }
    }

    private static func firedAt(_ node: Int, _ step: Int) -> Bool {
        let count = Double(nodes.count)
        if floorInt(dotHash(step, 3) * count) == node { return true }
        return dotHash(step, 4) > 0.55 && floorInt(dotHash(step, 5) * count) == node
    }

    private static func nodeAge(_ node: Int, _ t: Double) -> Double {
        let now = floorInt(t / fireStep)
        for k in stride(from: now, to: now - fireMemory, by: -1) where firedAt(node, k) {
            return t - Double(k) * fireStep
        }
        return .infinity
    }

    private static func mask(_ rows: [String]) -> [Bool] {
        var cells = [Bool](repeating: false, count: Grid.cells)
        for point in GridPoint.bitmap(rows) { cells[point.index] = true }
        return cells
    }

    private static func shuffled(_ seed: Int) -> [Int] {
        var bars = Array(1...8)
        for i in stride(from: bars.count - 1, to: 0, by: -1) {
            let j = floorInt(dotHash(seed * 8 + i, 9) * Double(i + 1))
            bars.swapAt(i, j)
        }
        return bars
    }

    private struct SortFrame {
        var bars: [Int]
        var hot: Int
        var compared: Int
        var doneFor: Int
    }

    private static func insertionSort(_ input: [Int], stoppingAt step: Int) -> SortFrame {
        var bars = input
        var count = 0
        for i in 1..<bars.count {
            var j = i
            while j > 0 && bars[j - 1] > bars[j] {
                if count == step { return SortFrame(bars: bars, hot: j, compared: j - 1, doneFor: -1) }
                bars.swapAt(j - 1, j)
                count += 1
                j -= 1
            }
        }
        return SortFrame(bars: bars, hot: -1, compared: -1, doneFor: step - count)
    }
}
