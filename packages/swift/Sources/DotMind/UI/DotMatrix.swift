import SwiftUI

struct DotMatrix: View {
    let engine: DotEngine
    let frame: DotFrame
    let size: CGFloat
    let well: Color

    var body: some View {
        Canvas { context, canvasSize in
            engine.draw(frame, in: &context, size: canvasSize)
        }
        .frame(width: size, height: size)
        .background(RoundedRectangle(cornerRadius: size * 0.24, style: .continuous).fill(well))
        .accessibilityHidden(true)
    }
}
