import SwiftUI

extension Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }

    init(_ rgb: RGB, opacity: Double = 1) {
        self.init(.sRGB, red: rgb.red / 255, green: rgb.green / 255, blue: rgb.blue / 255, opacity: opacity)
    }
}

extension RGB {
    var truncated: RGB {
        RGB(rgbTruncate(red), rgbTruncate(green), rgbTruncate(blue))
    }

    var glow: RGB {
        RGB(rgbTruncate((red + 510) / 3), rgbTruncate((green + 510) / 3), rgbTruncate((blue + 510) / 3))
    }

    func towardWhite(_ amount: Double) -> RGB {
        RGB(
            rgbTruncate(red + (255 - red) * amount),
            rgbTruncate(green + (255 - green) * amount),
            rgbTruncate(blue + (255 - blue) * amount)
        )
    }
}

private func rgbTruncate(_ value: Double) -> Double {
    value.rounded(.towardZero)
}
