import SwiftUI

struct DotPainter {
    private static let baseAlpha = 0.14
    private static let glowLevels = 16

    private var layoutSide: CGFloat = -1
    private var basePath = Path()
    private var origin: CGFloat = 0
    private var spacing: CGFloat = 0
    private var radius: CGFloat = 0
    private var glowColor: RGB?
    private var glows: [Gradient?] = Array(repeating: nil, count: glowLevels + 1)

    mutating func paint(_ values: [Double], color: RGB, in context: inout GraphicsContext, size: CGSize) {
        layout(side: min(size.width, size.height))
        let tint = color.truncated
        context.fill(basePath, with: shading(tint, opacity: Self.baseAlpha))
        for index in 0..<dotCount {
            let value = clamp(values[index], 0, 1.5)
            guard value >= 0.03 else { continue }
            paintGlow(index, value: value, tint: tint, in: &context)
        }
        for index in 0..<dotCount {
            let value = clamp(values[index], 0, 1.5)
            guard value >= 0.03 else { continue }
            paintDot(index, value: value, tint: tint, in: &context)
        }
    }

    private mutating func paintGlow(_ index: Int, value: Double, tint: RGB, in context: inout GraphicsContext) {
        let heat = clamp((value - 0.85) / 0.55, 0, 1)
        let alpha = clamp(value, 0, 1)
        let reach = radius * (1.5 + 2.5 * CGFloat(heat))
        let center = point(index)
        let outer = radius + reach
        let rect = CGRect(x: center.x - outer, y: center.y - outer, width: outer * 2, height: outer * 2)
        let gradient = glow(tint, alpha: alpha)
        context.fill(
            Path(ellipseIn: rect),
            with: .radialGradient(gradient, center: center, startRadius: radius * 0.5, endRadius: outer)
        )
    }

    private func paintDot(_ index: Int, value: Double, tint: RGB, in context: inout GraphicsContext) {
        let heat = clamp((value - 0.85) / 0.55, 0, 1)
        let alpha = clamp(value, 0, 1)
        let dot = radius * (1 + CGFloat(heat) * 0.12)
        let center = point(index)
        let rect = CGRect(x: center.x - dot, y: center.y - dot, width: dot * 2, height: dot * 2)
        context.fill(Path(ellipseIn: rect), with: shading(tint.towardWhite(heat), opacity: alpha))
    }

    private mutating func glow(_ tint: RGB, alpha: Double) -> Gradient {
        if glowColor != tint {
            glowColor = tint
            for level in glows.indices { glows[level] = nil }
        }
        let level = Int((alpha * Double(Self.glowLevels)).rounded())
        if let cached = glows[level] { return cached }
        let strength = Double(level) / Double(Self.glowLevels) * 0.55
        let gradient = Gradient(colors: [Color(tint, opacity: strength), Color(tint, opacity: 0)])
        glows[level] = gradient
        return gradient
    }

    private func shading(_ tint: RGB, opacity: Double) -> GraphicsContext.Shading {
        .color(.sRGB, red: tint.red / 255, green: tint.green / 255, blue: tint.blue / 255, opacity: opacity)
    }

    private func point(_ index: Int) -> CGPoint {
        CGPoint(
            x: origin + CGFloat(index % dotGridSide) * spacing,
            y: origin + CGFloat(index / dotGridSide) * spacing
        )
    }

    private mutating func layout(side: CGFloat) {
        guard side != layoutSide else { return }
        layoutSide = side
        origin = side * 0.12
        spacing = (side - origin * 2) / CGFloat(dotGridSide - 1)
        radius = spacing * 0.34
        var path = Path()
        for index in 0..<dotCount {
            let center = point(index)
            path.addEllipse(in: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
        }
        basePath = path
    }
}

private func clamp(_ value: Double, _ lower: Double, _ upper: Double) -> Double {
    min(max(value, lower), upper)
}
