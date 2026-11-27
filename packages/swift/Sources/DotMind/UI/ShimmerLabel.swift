import SwiftUI

struct ShimmerLabel: View {
    let text: String
    let position: Double
    let gradient: Gradient
    let font: Font

    var body: some View {
        let start = -1.6 * position
        Text(text)
            .font(font)
            .lineLimit(1)
            .truncationMode(.tail)
            .foregroundStyle(
                LinearGradient(
                    gradient: gradient,
                    startPoint: UnitPoint(x: start, y: 0.5),
                    endPoint: UnitPoint(x: start + 2.6, y: 0.5)
                )
            )
    }

    static func gradient(theme: DotMindTheme, glow: Color) -> Gradient {
        Gradient(stops: [
            .init(color: theme.ink, location: 0),
            .init(color: theme.ink, location: 0.38),
            .init(color: theme.peak, location: 0.47),
            .init(color: glow, location: 0.52),
            .init(color: theme.ink, location: 0.62),
            .init(color: theme.ink, location: 1),
        ])
    }
}
