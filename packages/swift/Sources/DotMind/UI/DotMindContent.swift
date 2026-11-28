import SwiftUI

struct DotMindContent: View {
    let activity: Activity
    let configuration: DotMindConfiguration

    @StateObject private var engine = DotEngine()
    @State private var visible = false
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dotMindTheme) private var theme

    var body: some View {
        let still = configuration.reducedMotion ?? systemReduceMotion
        let paused = still || !visible || scenePhase == .background
        let scene = configuration.scene(for: activity)
        let color = configuration.color(for: scene)
        let text = configuration.visibleText(for: activity)
        let spoken = configuration.spokenText(for: activity)
        let shape = configuration.resolvedShape
        let aura = configuration.showsAura
        let shimmer = ShimmerLabel.gradient(theme: theme, glow: Color(color.glow))

        TimelineView(.animation(minimumInterval: nil, paused: paused)) { timeline in
            HStack(spacing: theme.fontSize * 0.6) {
                DotMatrix(
                    engine: engine,
                    frame: DotFrame(
                        activity: activity,
                        scene: scene,
                        color: color,
                        shape: shape,
                        date: timeline.date,
                        still: still,
                        visible: visible
                    ),
                    size: configuration.size,
                    theme: theme,
                    aura: aura && configuration.variant == .bare
                )
                if !text.isEmpty {
                    ShimmerLabel(
                        text: text,
                        position: shimmerPosition(at: timeline.date, still: still),
                        gradient: shimmer,
                        font: theme.font
                    )
                }
            }
            .modifier(
                VariantBackground(
                    variant: configuration.variant,
                    theme: theme,
                    aura: color,
                    auraOn: aura && configuration.variant == .pill
                )
            )
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(spoken))
        .accessibilityAddTraits(.updatesFrequently)
        .modifier(PoliteAnnouncement(text: spoken))
        .onAppear { visible = true }
        .onDisappear { visible = false }
    }

    private func shimmerPosition(at date: Date, still: Bool) -> Double {
        switch activity.phase {
        case .idle, .done, .error: return 1
        default: break
        }
        if still { return 0.5 }
        let period = max(0.1, theme.shimmerPeriod)
        let cycle = date.timeIntervalSinceReferenceDate / period
        return 1.3 - 1.6 * (cycle - floor(cycle))
    }
}
