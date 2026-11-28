import SwiftUI

struct DotPainter {
    private static let glowLevels = 16

    private var layoutSide: CGFloat = -1
    private var layoutShape: DotShape = .dot
    private var geometry = DotShape.dot.geometry
    private var basePath = Path()
    private var origin: CGFloat = 0
    private var spacing: CGFloat = 0
    private var half: CGFloat = 0
    private var glowColor: RGB?
    private var glows: [Gradient?] = Array(repeating: nil, count: glowLevels + 1)

    mutating func paint(
        _ values: [Double],
        color: RGB,
        shape: DotShape,
        in context: inout GraphicsContext,
        size: CGSize
    ) {
        layout(side: min(size.width, size.height), shape: shape)
        let tint = color.truncated
        context.fill(basePath, with: shading(tint, opacity: geometry.base))
        for index in 0..<dotCount {
            let value = clamp(values[index], 0, 1.5)
            guard value >= 0.03 else { continue }
            paintGlow(index, value: value, tint: tint, in: &context)
        }
        for index in 0..<dotCount {
            let value = clamp(values[index], 0, 1.5)
            guard value >= 0.03 else { continue }
            paintCell(index, value: value, tint: tint, in: &context)
        }
    }

    private mutating func paintGlow(_ index: Int, value: Double, tint: RGB, in context: inout GraphicsContext) {
        let heat = clamp((value - 0.85) / 0.55, 0, 1)
        let alpha = clamp(value, 0, 1)
        let reach = half * (1.5 + 2.5 * CGFloat(heat))
        let center = point(index)
        let outer = half + reach
        let rect = CGRect(x: center.x - outer, y: center.y - outer, width: outer * 2, height: outer * 2)
        let gradient = glow(tint, alpha: alpha)
        context.fill(
            Path(ellipseIn: rect),
            with: .radialGradient(gradient, center: center, startRadius: half * 0.5, endRadius: outer)
        )
    }

    private func paintCell(_ index: Int, value: Double, tint: RGB, in context: inout GraphicsContext) {
        let heat = clamp((value - 0.85) / 0.55, 0, 1)
        let alpha = clamp(value, 0, 1)
        let path = cellPath(at: point(index), half: half * (1 + CGFloat(heat) * 0.12))
        context.fill(path, with: shading(tint.towardWhite(heat), opacity: alpha))
    }

    private func cellPath(at center: CGPoint, half: CGFloat) -> Path {
        let rect = CGRect(x: center.x - half, y: center.y - half, width: half * 2, height: half * 2)
        switch layoutShape {
        case .dot:
            return Path(ellipseIn: rect)
        case .square:
            return Path(roundedRect: rect, cornerRadius: half * 2 * CGFloat(geometry.corner), style: .circular)
        }
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

    private mutating func layout(side: CGFloat, shape: DotShape) {
        guard side != layoutSide || shape != layoutShape else { return }
        layoutSide = side
        layoutShape = shape
        geometry = shape.geometry
        origin = side * 0.12
        spacing = (side - origin * 2) / CGFloat(dotGridSide - 1)
        half = spacing * CGFloat(geometry.size) / 2
        var path = Path()
        for index in 0..<dotCount {
            path.addPath(cellPath(at: point(index), half: half))
        }
        basePath = path
    }
}

private func clamp(_ value: Double, _ lower: Double, _ upper: Double) -> Double {
    min(max(value, lower), upper)
}
