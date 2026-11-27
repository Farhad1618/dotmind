import Foundation

public struct DotRenderer: Sendable {
    private struct Layer: Sendable {
        var scene: SceneName
        var color: RGB
        var time: Double
        var origin: Double
    }

    private static let blendSeconds = 0.35

    private var current: Layer
    private var previous: Layer?
    private var blend = 1.0
    private var currentValues = [Double](repeating: 0, count: Grid.cells)
    private var previousValues = [Double](repeating: 0, count: Grid.cells)
    private var energy = 0.3
    private var rate = 0.0
    private var lastProgress: Double?
    private var lastProgressAt = 0.0
    private var synthetic = 0.0
    private var clock = 0.0
    private var hasProgress = false

    public init(scene: SceneName = .breathe, color: RGB? = nil) {
        current = Layer(scene: scene, color: color ?? scene.defaultColor, time: 0, origin: 0)
    }

    public var scene: SceneName { current.scene }

    public var level: Double { energy }

    public var color: RGB {
        guard let previous else { return current.color }
        return previous.color.mixed(with: current.color, by: easedBlend)
    }

    public mutating func show(_ scene: SceneName, color: RGB? = nil, instant: Bool = false) {
        let color = color ?? scene.defaultColor
        if scene == current.scene {
            current.color = color
            return
        }
        previous = instant ? nil : current
        current = Layer(scene: scene, color: color, time: 0, origin: progressNow)
        blend = instant ? 1 : 0
    }

    public mutating func feed(_ progress: Double?) {
        guard let progress else {
            hasProgress = false
            return
        }
        hasProgress = true
        guard let last = lastProgress, progress >= last else {
            lastProgress = progress
            lastProgressAt = clock
            rate = 0
            current.origin = min(current.origin, progress)
            return
        }
        if progress == last { return }
        let elapsed = max(1.0 / 60.0, clock - lastProgressAt)
        rate = rate * 0.7 + (progress - last) / elapsed * 0.3
        lastProgress = progress
        lastProgressAt = clock
    }

    public mutating func step(_ dt: Double) {
        clock += dt
        if clock - lastProgressAt > 0.45 { rate *= exp(-dt * 3) }
        let target = clamp(0.3 + rate / 160, 0.3, 1.5)
        energy += (target - energy) * (1 - exp(-dt * 6))
        let speed = 0.6 + 0.6 * energy
        current.time += dt * speed
        previous?.time += dt * speed
        synthetic += dt * 40 * speed
        if blend < 1 {
            blend = min(1, blend + dt / Self.blendSeconds)
            if blend >= 1 { previous = nil }
        }
    }

    public mutating func sample(into out: inout [Double]) {
        precondition(out.count == Grid.cells, "dotmind samples need a 64 value buffer")
        current.scene.render(at: current.time, into: &currentValues, context: context(for: current))
        guard let previous else {
            for index in 0..<Grid.cells { out[index] = currentValues[index] }
            return
        }
        previous.scene.render(at: previous.time, into: &previousValues, context: context(for: previous))
        let k = easedBlend
        for index in 0..<Grid.cells {
            out[index] = previousValues[index] * (1 - k) + currentValues[index] * k
        }
    }

    mutating func sample() -> [Double] {
        var out = [Double](repeating: 0, count: Grid.cells)
        sample(into: &out)
        return out
    }

    private var progressNow: Double {
        hasProgress ? (lastProgress ?? 0) : synthetic
    }

    private var easedBlend: Double {
        blend * blend * (3 - 2 * blend)
    }

    private func context(for layer: Layer) -> PatternContext {
        PatternContext(energy: energy, progress: max(0, progressNow - layer.origin))
    }
}
