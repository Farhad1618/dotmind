import SwiftUI

public struct DotMindTheme {
    public var background: Color
    public var edge: Color
    public var well: Color
    public var ink: Color
    public var peak: Color
    public var font: Font
    public var fontSize: CGFloat
    public var shimmerPeriod: Double

    public init(
        background: Color? = nil,
        edge: Color? = nil,
        well: Color? = nil,
        ink: Color? = nil,
        peak: Color = .white,
        font: Font? = nil,
        fontSize: CGFloat = 15,
        shimmerPeriod: Double = 2.4
    ) {
        self.background = background ?? Color(hex: 0x0B0B0C)
        self.edge = edge ?? Color(hex: 0x26262A)
        self.well = well ?? Color(hex: 0x050506)
        self.ink = ink ?? Color(hex: 0x8A8A92)
        self.peak = peak
        self.font = font ?? .system(size: fontSize, weight: .medium)
        self.fontSize = fontSize
        self.shimmerPeriod = shimmerPeriod
    }

    public static var standard: DotMindTheme { DotMindTheme() }
}

private struct DotMindThemeKey: EnvironmentKey {
    static var defaultValue: DotMindTheme { .standard }
}

extension EnvironmentValues {
    public var dotMindTheme: DotMindTheme {
        get { self[DotMindThemeKey.self] }
        set { self[DotMindThemeKey.self] = newValue }
    }
}

extension View {
    public func dotMindTheme(_ theme: DotMindTheme) -> some View {
        environment(\.dotMindTheme, theme)
    }
}
