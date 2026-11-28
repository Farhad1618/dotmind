import SwiftUI

enum Palette {
    static let stage = Color(hex: 0x121213)
    static let stageHighlight = Color(hex: 0x1B1B1E)
    static let panel = Color(hex: 0x0D0D0E)
    static let rule = Color(hex: 0x232327)
    static let ink = Color(hex: 0xECECEF)
    static let inkDim = Color(hex: 0x8A8A92)
    static let inkFaint = Color(hex: 0x55555C)
    static let chip = Color(hex: 0x1A1A1D)
    static let chipActive = Color(hex: 0x26263A)
}

extension Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}

extension Font {
    static func mono(_ size: CGFloat) -> Font {
        .system(size: size, design: .monospaced)
    }
}
