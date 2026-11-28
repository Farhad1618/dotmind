import SwiftUI

struct DotMatrix: View {
    let engine: DotEngine
    let frame: DotFrame
    let size: CGFloat
    let theme: DotMindTheme
    let aura: Bool

    var body: some View {
        let radius = size * CGFloat(frame.shape.geometry.well)
        Canvas { context, canvasSize in
            engine.draw(frame, in: &context, size: canvasSize)
        }
        .frame(width: size, height: size)
        .background(RoundedRectangle(cornerRadius: radius, style: .continuous).fill(theme.well))
        .background(
            AuraGlow(color: frame.color, on: aura, layers: AuraLayer.well(theme)) { spread in
                RoundedRectangle(cornerRadius: radius + spread, style: .continuous)
            }
        )
        .accessibilityHidden(true)
    }
}
