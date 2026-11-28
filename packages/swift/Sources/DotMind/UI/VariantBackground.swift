import SwiftUI

struct VariantBackground: ViewModifier {
    let variant: DotMindVariant
    let theme: DotMindTheme
    let aura: RGB
    let auraOn: Bool

    func body(content: Content) -> some View {
        switch variant {
        case .bare:
            content
        case .pill:
            let em = theme.fontSize
            content
                .padding(.vertical, em * 0.35)
                .padding(.leading, em * 0.35)
                .padding(.trailing, em * 1.15)
                .background(
                    Capsule(style: .continuous)
                        .fill(theme.background)
                        .overlay(Capsule(style: .continuous).strokeBorder(theme.edge, lineWidth: 1))
                        .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 6)
                )
                .background(
                    AuraGlow(color: aura, on: auraOn, layers: AuraLayer.pill(theme)) { _ in
                        Capsule(style: .continuous)
                    }
                )
        }
    }
}
