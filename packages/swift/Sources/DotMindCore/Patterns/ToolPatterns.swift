import Foundation

enum ToolPatterns {
    static func radar(_ t: Double, _ out: inout [Double]) {
        let sweep = t * tau / 1.6
        let turn = floor(sweep / tau)
        for index in 0..<Grid.cells {
            let dx = Double(index % 8) - Grid.center
            let dy = Double(index / 8) - Grid.center
            let radius = hypot(dx, dy)
            if radius > 4 {
                out[index] = 0
                continue
            }
            let behind = wrapAngle(sweep - atan2(dy, dx))
            var value = 0.1 + 1.1 * exp(-behind * 2.4) * (0.4 + radius / 6)
            if dotHash(index, turn) > 0.9 && behind < 3 {
                value = max(value, 1.4 * exp(-behind * 0.8))
            }
            out[index] = value
        }
    }

    static func globe(_ t: Double, _ out: inout [Double]) {
        clear(&out)
        for index in 0..<Grid.cells {
            let y = index / 8
            let radius = hypot(Double(index % 8) - Grid.center, Double(y) - Grid.center)
            if abs(radius - 3.2) < 0.7 { out[index] = 0.35 }
            if y == 3 || y == 4 { out[index] = max(out[index], radius < 3.6 ? 0.22 : 0) }
        }
        for half in 0..<2 {
            let phase = t * 1.8 + Double(half) * Double.pi
            let swing = sin(phase)
            let front = cos(phase) > 0
            for y in 0..<8 {
                let dy = Double(y) - Grid.center
                let width = sqrt(max(0, 12.25 - dy * dy))
                let x = roundHalfUp(Grid.center + width * swing)
                if x < 0 || x > 7 { continue }
                let index = cell(x, y)
                out[index] = max(out[index], front ? 1.3 : 0.45)
            }
        }
    }

    static func code(_ t: Double, _ out: inout [Double], _ context: PatternContext) {
        clear(&out)
        fill(&out, Shapes.code, 0.7)
        let typed = floorInt((context.progress * 0.2 + t * 3).truncatingRemainder(dividingBy: 6))
        var k = 0
        while k < typed && k < 4 {
            out[cell(2 + k, 3)] = 0.85
            k += 1
        }
        let cursor = 2 + min(typed, 4)
        if cursor <= 5 { out[cell(cursor, 3)] = sin(t * 9) > 0 ? 1.45 : 0.3 }
    }

    static func pages(_ t: Double, _ out: inout [Double]) {
        clear(&out)
        fill(&out, Shapes.page, 0.55)
        let line = positiveModulo(floorInt(t * 1.8), Shapes.pageLines.count + 1)
        for (k, cells) in Shapes.pageLines.enumerated() {
            if k < line { fill(&out, cells, 0.75) }
            guard k == line else { continue }
            let head = (t * 1.8 - floor(t * 1.8)) * Double(cells.count)
            let lead = floorInt(head)
            for (j, index) in cells.enumerated() where Double(j) <= head {
                out[index] = j == lead ? 1.4 : 0.9
            }
        }
    }

    static func stack(_ t: Double, _ out: inout [Double]) {
        clear(&out)
        let active = positiveModulo(floorInt(t * 2.2), 3)
        let fraction = t * 2.2 - floor(t * 2.2)
        for (k, cells) in Shapes.disks.enumerated() {
            fill(&out, cells, k == active ? 0.95 : 0.28)
            guard k == active else { continue }
            let x = 1 + floorInt(fraction * 6)
            out[cell(x, k * 3)] = 1.45
            out[cell(7 - x, k * 3 + 1)] = 1.2
        }
    }

    static func prism(_ t: Double, _ out: inout [Double]) {
        let swell = 0.5 + 0.5 * sin(t * 2.1)
        let radius = 1 + 2.6 * swell
        for index in 0..<Grid.cells {
            let dx = abs(Double(index % 8) - Grid.center)
            let dy = abs(Double(index / 8) - Grid.center)
            let distance = dx + dy - radius
            let on = exp(-(distance * distance) / 0.18)
            let axis = dx < 1 || dy < 1 ? 0.45 : 0
            out[index] = on * (0.75 + axis + (1 - swell) * 0.3)
        }
    }

    static func circuit(_ t: Double, _ out: inout [Double]) {
        clear(&out)
        trail(&out, Shapes.perimeter, head: t * 13, length: 9, decay: 0.8)
        fill(&out, Shapes.center, 0.25 + (0.5 + 0.5 * sin(t * 4)) * 0.9)
    }
}
