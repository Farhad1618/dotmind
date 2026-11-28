import SwiftUI

public struct DotMindView: View {
    private enum Source {
        case activity(Activity)
        case tracker(ActivityTracker)
    }

    private let source: Source
    private let configuration: DotMindConfiguration

    public init(
        activity: Activity = .idle,
        variant: DotMindVariant = .pill,
        size: CGFloat = 28,
        label: DotMindLabel = .automatic,
        labels: [LabelKey: String] = [:],
        palette: [SceneName: RGB] = [:],
        scene: SceneName? = nil,
        look: Look = .classic,
        shape: DotShape? = nil,
        scenes: [SceneKey: SceneName] = [:],
        aura: Bool? = nil,
        reducedMotion: Bool? = nil
    ) {
        source = .activity(activity)
        configuration = DotMindConfiguration(
            variant: variant,
            size: size,
            label: label,
            labels: labels,
            palette: palette,
            scene: scene,
            look: look,
            shape: shape,
            scenes: scenes,
            aura: aura,
            reducedMotion: reducedMotion
        )
    }

    public init(
        tracker: ActivityTracker,
        variant: DotMindVariant = .pill,
        size: CGFloat = 28,
        label: DotMindLabel = .automatic,
        labels: [LabelKey: String] = [:],
        palette: [SceneName: RGB] = [:],
        scene: SceneName? = nil,
        look: Look = .classic,
        shape: DotShape? = nil,
        scenes: [SceneKey: SceneName] = [:],
        aura: Bool? = nil,
        reducedMotion: Bool? = nil
    ) {
        source = .tracker(tracker)
        configuration = DotMindConfiguration(
            variant: variant,
            size: size,
            label: label,
            labels: labels,
            palette: palette,
            scene: scene,
            look: look,
            shape: shape,
            scenes: scenes,
            aura: aura,
            reducedMotion: reducedMotion
        )
    }

    public var body: some View {
        switch source {
        case let .activity(activity):
            DotMindContent(activity: activity, configuration: configuration)
        case let .tracker(tracker):
            TrackedDotMind(tracker: tracker, configuration: configuration)
        }
    }
}

private struct TrackedDotMind: View {
    @ObservedObject var tracker: ActivityTracker
    let configuration: DotMindConfiguration

    var body: some View {
        DotMindContent(activity: tracker.activity, configuration: configuration)
    }
}
