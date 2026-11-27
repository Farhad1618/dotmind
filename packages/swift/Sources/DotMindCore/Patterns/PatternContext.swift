public struct PatternContext: Hashable, Sendable {
    public var energy: Double
    public var progress: Double

    public init(energy: Double, progress: Double) {
        self.energy = energy
        self.progress = progress
    }
}
