struct GridPoint: Hashable {
    var x: Int
    var y: Int

    init(_ x: Int, _ y: Int) {
        self.x = x
        self.y = y
    }

    var index: Int { cell(x, y) }

    static func list(_ pairs: [(Int, Int)]) -> [GridPoint] {
        pairs.map { GridPoint($0.0, $0.1) }
    }

    static func bitmap(_ rows: [String]) -> [GridPoint] {
        var points: [GridPoint] = []
        for (y, row) in rows.enumerated() {
            for (x, character) in row.enumerated() where character == "#" {
                points.append(GridPoint(x, y))
            }
        }
        return points
    }

    static func line(_ from: GridPoint, _ to: GridPoint) -> [GridPoint] {
        var points: [GridPoint] = []
        var x = from.x
        var y = from.y
        let dx = abs(to.x - x)
        let dy = -abs(to.y - y)
        let sx = x < to.x ? 1 : -1
        let sy = y < to.y ? 1 : -1
        var error = dx + dy
        while true {
            points.append(GridPoint(x, y))
            if x == to.x && y == to.y { return points }
            let doubled = 2 * error
            if doubled >= dy {
                error += dy
                x += sx
            }
            if doubled <= dx {
                error += dx
                y += sy
            }
        }
    }
}

func light(_ out: inout [Double], _ points: [GridPoint], _ value: Double) {
    for point in points { light(&out, point.x, point.y, value) }
}
