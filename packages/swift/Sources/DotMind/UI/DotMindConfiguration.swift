import CoreGraphics

struct DotMindConfiguration: Hashable {
    var variant: DotMindVariant
    var size: CGFloat
    var label: DotMindLabel
    var labels: [LabelKey: String]
    var palette: [SceneName: RGB]
    var scene: SceneName?
    var look: Look
    var shape: DotShape?
    var scenes: [SceneKey: SceneName]
    var aura: Bool?
    var reducedMotion: Bool?

    var resolvedShape: DotShape {
        shape ?? look.definition.shape
    }

    var showsAura: Bool {
        aura ?? look.definition.aura
    }

    func scene(for activity: Activity) -> SceneName {
        scene ?? sceneFor(activity, look: look, overrides: scenes)
    }

    func color(for scene: SceneName) -> RGB {
        palette[scene] ?? scene.defaultColor
    }

    func visibleText(for activity: Activity) -> String {
        switch label {
        case .automatic: labelFor(activity, labels: labels)
        case let .text(text): text
        case .hidden: ""
        }
    }

    func spokenText(for activity: Activity) -> String {
        let text = visibleText(for: activity)
        return text.isEmpty ? labelFor(activity, labels: labels) : text
    }
}
