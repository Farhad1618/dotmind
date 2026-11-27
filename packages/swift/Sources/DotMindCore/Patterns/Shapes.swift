enum Shapes {
    static let ring = points([(2, 2), (3, 2), (4, 2), (5, 2), (5, 3), (5, 4), (5, 5), (4, 5), (3, 5), (2, 5), (2, 4), (2, 3)])
    static let center = points([(3, 3), (4, 3), (3, 4), (4, 4)])
    static let checkStroke = points([(1, 4), (2, 5), (3, 6), (4, 5), (5, 4), (6, 3), (7, 2)])

    static let perimeter: [Int] = {
        var path: [(Int, Int)] = []
        for x in 0..<8 { path.append((x, 0)) }
        for y in 1..<8 { path.append((7, y)) }
        for x in stride(from: 6, through: 0, by: -1) { path.append((x, 7)) }
        for y in stride(from: 6, to: 0, by: -1) { path.append((0, y)) }
        return points(path)
    }()

    static let serpent: [Int] = {
        var path: [(Int, Int)] = []
        for x in 1..<8 {
            for k in 0..<8 { path.append((x, x % 2 == 1 ? k : 7 - k)) }
        }
        for y in stride(from: 7, through: 0, by: -1) { path.append((0, y)) }
        return points(path)
    }()

    static let code = bitmap([
        "........",
        "..#..#..",
        ".#....#.",
        "#......#",
        ".#....#.",
        "..#..#..",
        "........",
        "........",
    ])

    static let page = bitmap([
        ".####...",
        ".#..##..",
        ".#...##.",
        ".#....#.",
        ".#....#.",
        ".#....#.",
        ".#....#.",
        ".######.",
    ])

    static let pageLines = [
        points([(2, 3), (3, 3), (4, 3), (5, 3)]),
        points([(2, 4), (3, 4), (4, 4)]),
        points([(2, 5), (3, 5), (4, 5), (5, 5)]),
        points([(2, 6), (3, 6)]),
    ]

    static let cross = bitmap([
        "........",
        ".#....#.",
        "..#..#..",
        "...##...",
        "...##...",
        "..#..#..",
        ".#....#.",
        "........",
    ])

    static let disks: [[Int]] = [0, 3, 6].map { y in
        (1...6).map { cell($0, y) } + (1...6).map { cell($0, y + 1) }
    }

    private static func points(_ pairs: [(Int, Int)]) -> [Int] {
        pairs.map { cell($0.0, $0.1) }
    }

    private static func bitmap(_ rows: [String]) -> [Int] {
        var cells: [Int] = []
        for (y, row) in rows.enumerated() {
            for (x, character) in row.enumerated() where character == "#" {
                cells.append(cell(x, y))
            }
        }
        return cells
    }
}
