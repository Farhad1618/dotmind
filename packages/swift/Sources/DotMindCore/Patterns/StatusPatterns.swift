import Foundation

enum StatusPatterns {
    static func type(_ t: Double, _ out: inout [Double], _ context: PatternContext) {
        clear(&out)
        let total = floorInt(context.progress / 4)
        var line = 0
        var used = 0
        while used + lineLength(line) <= total {
            used += lineLength(line)
            line += 1
        }
        let position = total - used
        let first = max(0, line - 7)
        for k in first...line {
            let row = k - first
            let length = k < line ? lineLength(k) : position
            for x in 0..<length { out[cell(x, row)] = k == line ? 0.85 : 0.5 }
            if k == line && position < 8 {
                out[cell(position, row)] = sin(t * 10) > -0.2 ? 1.45 : 0.25
            }
        }
    }

    static func halo(_ t: Double, _ out: inout [Double]) {
        clear(&out)
        trail(&out, Shapes.ring, head: t * 10, length: 6, decay: 0.68)
        fill(&out, Shapes.center, 0.15 + (0.5 + 0.5 * sin(t * 2.2)) * 0.35)
    }

    static func cross(_ t: Double, _ out: inout [Double]) {
        clear(&out)
        let flash = t < 0.9 ? (sin(t * 22) > 0 ? 1.4 : 0.35) : 0.85 + 0.15 * sin(t * 2)
        fill(&out, Shapes.cross, flash)
    }

    static func check(_ t: Double, _ out: inout [Double]) {
        clear(&out)
        let drawn = t * 14
        let settled = t > 1.2 ? 0.8 + 0.1 * sin(t * 2) : 1.1
        for (k, index) in Shapes.checkStroke.enumerated() where Double(k) < drawn {
            out[index] = Double(k + 1) > drawn ? 1.45 : settled
        }
    }

    private static func lineLength(_ line: Int) -> Int {
        3 + floorInt(dotHash(line, 7) * 5)
    }
}
