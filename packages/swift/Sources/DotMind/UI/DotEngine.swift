import SwiftUI

final class DotEngine: ObservableObject {
    private struct Applied: Equatable {
        var activity: Activity
        var scene: SceneName
        var color: RGB
    }

    private var renderer = DotRenderer()
    private var values = [Double](repeating: 0, count: dotCount)
    private var painter = DotPainter()
    private var applied: Applied?
    private var lastDate: Date?
    private var drawn = false

    func draw(_ frame: DotFrame, in context: inout GraphicsContext, size: CGSize) {
        apply(frame)
        advance(to: frame.date, still: frame.still)
        renderer.sample(into: &values)
        painter.paint(values, color: renderer.color, shape: frame.shape, in: &context, size: size)
        drawn = true
    }

    private func apply(_ frame: DotFrame) {
        let next = Applied(activity: frame.activity, scene: frame.scene, color: frame.color)
        guard next != applied else { return }
        renderer.feed(frame.activity.progress.map(Double.init))
        renderer.show(frame.scene, color: frame.color, instant: !frame.visible || !drawn)
        if frame.still {
            renderer.step(1.2)
            renderer.step(0.5)
        }
        applied = next
    }

    private func advance(to date: Date, still: Bool) {
        defer { lastDate = date }
        guard !still, let lastDate else { return }
        let dt = min(0.05, max(0, date.timeIntervalSince(lastDate)))
        if dt > 0 { renderer.step(dt) }
    }
}
