import SwiftUI

struct AuraLayer: Hashable {
    var spread: CGFloat
    var blur: CGFloat
    var opacity: Double
}

struct AuraGlow<Outline: Shape>: View {
    private struct Fade: Equatable {
        var color: RGB
        var on: Bool
    }

    let color: RGB
    let on: Bool
    let layers: [AuraLayer]
    let outline: (CGFloat) -> Outline

    var body: some View {
        ZStack {
            ForEach(layers, id: \.self) { layer in
                outline(layer.spread)
                    .fill(Color(color, opacity: on ? layer.opacity : 0))
                    .padding(-layer.spread)
                    .blur(radius: layer.blur / 2)
            }
        }
        .animation(.timingCurve(0.25, 0.1, 0.25, 1, duration: 0.35), value: Fade(color: color, on: on))
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

extension AuraLayer {
    static func pill(_ theme: DotMindTheme) -> [AuraLayer] {
        [
            AuraLayer(spread: -6, blur: 24, opacity: theme.auraNear),
            AuraLayer(spread: 8, blur: 72, opacity: theme.auraFar),
        ]
    }

    static func well(_ theme: DotMindTheme) -> [AuraLayer] {
        [AuraLayer(spread: 2, blur: 18, opacity: theme.auraNear)]
    }
}
