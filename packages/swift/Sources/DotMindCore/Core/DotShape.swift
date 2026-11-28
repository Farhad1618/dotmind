public enum DotShape: String, CaseIterable, Codable, Hashable, Sendable {
    case dot
    case square

    public var geometry: ShapeGeometry {
        switch self {
        case .dot: ShapeGeometry(size: 0.68, corner: 0.5, base: 0.14, well: 0.24)
        case .square: ShapeGeometry(size: 0.8, corner: 0.22, base: 0.2, well: 0.14)
        }
    }
}

public struct ShapeGeometry: Hashable, Sendable {
    public var size: Double
    public var corner: Double
    public var base: Double
    public var well: Double

    public init(size: Double, corner: Double, base: Double, well: Double) {
        self.size = size
        self.corner = corner
        self.base = base
        self.well = well
    }
}
