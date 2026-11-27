import Foundation

enum AmbientPatterns {
    static func breathe(_ t: Double, _ out: inout [Double]) {
        clear(&out)
        let pulse = 0.5 + 0.5 * sin(t * 1.6)
        fill(&out, Shapes.center, 0.18 + pulse * 0.5)
    }

    static func comet(_ t: Double, _ out: inout [Double]) {
        clear(&out)
        for k in 0..<14 {
            let angle = t * 2.6 - Double(k) * 0.17
            let x = roundHalfUp(Grid.center + 3.2 * sin(angle))
            let y = roundHalfUp(Grid.center + 3.1 * sin(2 * angle))
            let index = cell(clamp(x, 0, 7), clamp(y, 0, 7))
            out[index] = max(out[index], k == 0 ? 1.45 : pow(0.8, Double(k)))
        }
    }

    static func ember(_ t: Double, _ out: inout [Double]) {
        let hx = Grid.center + 2.4 * sin(t * 1.3)
        let hy = Grid.center + 2.4 * sin(t * 1.9 + 1)
        for index in 0..<Grid.cells {
            let dx = Double(index % 8) - hx
            let dy = Double(index / 8) - hy
            let wave = sin(t * (2 + dotHash(index, 1) * 3) + dotHash(index, 2) * tau)
            let flick = pow(max(0, wave), 6) * 0.75
            out[index] = min(1.5, 0.12 + flick + 1.35 * exp(-(dx * dx + dy * dy) / 1.1))
        }
    }

    static func orbit(_ t: Double, _ out: inout [Double]) {
        let head = t * tau / 1.5
        for index in 0..<Grid.cells {
            let dx = Double(index % 8) - Grid.center
            let dy = Double(index / 8) - Grid.center
            if abs(hypot(dx, dy) - 3.1) > 0.75 {
                out[index] = 0
                continue
            }
            out[index] = 0.22 + 1.25 * exp(-wrapAngle(head - atan2(dy, dx)) * 1.1)
        }
    }

    static func serpent(_ t: Double, _ out: inout [Double]) {
        clear(&out)
        trail(&out, Shapes.serpent, head: t * 11, length: 9, decay: 0.78)
    }

    static func pulse(_ t: Double, _ out: inout [Double]) {
        for x in 0..<8 {
            let column = Double(x)
            let height = 1 + 6.5 * (0.5 + 0.5 * sin(t * 3.1 + column * 0.8) * cos(t * 1.3 - column * 0.35))
            for y in 0..<8 {
                let up = Double(7 - y)
                out[cell(x, y)] = up < height - 1 ? 0.7 : (up < height ? 1.4 : 0)
            }
        }
    }
}
