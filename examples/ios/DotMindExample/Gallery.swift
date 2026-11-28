import DotMind
import SwiftUI

struct GalleryItem: Identifiable {
    let id: String
    let activity: Activity
    let label: DotMindLabel
    let scene: SceneName?
    var look: Look?

    static func state(_ phase: Phase, tool: String? = nil) -> GalleryItem {
        let activity = tool.map { name in
            phase == .tool ? Activity.using(name) : Activity(phase: phase, tool: name)
        } ?? Activity(phase: phase)
        let caption = tool.map { "phase=\"\(phase.rawValue)\" tool=\"\($0)\"" } ?? "phase=\"\(phase.rawValue)\""
        return GalleryItem(id: caption, activity: activity, label: .text(labelFor(activity)), scene: nil)
    }

    static func scene(_ scene: SceneName) -> GalleryItem {
        GalleryItem(id: "scene=\"\(scene.rawValue)\"", activity: .thinking, label: .text(scene.rawValue.capitalized), scene: scene)
    }

    static func styled(_ look: Look, _ activity: Activity, label: String? = nil) -> GalleryItem {
        let text = label ?? labelFor(activity)
        let scene = sceneFor(activity, look: look)
        return GalleryItem(
            id: "look=\"\(look.rawValue)\" scene=\"\(scene.rawValue)\"",
            activity: activity,
            label: .text(text),
            scene: nil,
            look: look
        )
    }

    static let states: [GalleryItem] = [
        .state(.thinking),
        .state(.tool, tool: "web_search"),
        .state(.tool, tool: "web_fetch"),
        .state(.tool, tool: "bash"),
        .state(.tool, tool: "read_file"),
        .state(.tool, tool: "run_sql"),
        .state(.tool, tool: "calculate_margin"),
        .state(.tool, tool: "translate_text"),
        .state(.tool, tool: "deploy_service"),
        .state(.tool, tool: "set_breakpoint"),
        .state(.tool, tool: "get_weather"),
        .state(.writing),
        .state(.waiting, tool: "deploy_config"),
        .state(.error),
        .state(.done),
    ]

    static let icons: [GalleryItem] = [
        .styled(.icons, .thinking),
        .styled(.icons, .using("web_search")),
        .styled(.icons, .using("translate_text")),
        .styled(.icons, .using("calculate_margin"), label: "Sorting"),
        .styled(.icons, .using("deploy_service")),
        .styled(.icons, .done),
    ]

    static let pixels: [GalleryItem] = [
        .styled(.pixel, .using("set_breakpoint")),
        .styled(.pixel, .using("bash"), label: "Running code"),
        .styled(.pixel, .using("web_search"), label: "Searching"),
    ]

    static let scenes: [GalleryItem] = [
        SceneName.ember, .orbit, .prism, .serpent, .circuit, .pulse, .comet, .halo,
    ].map(scene)
}

struct Gallery: View {
    let items: [GalleryItem]
    var look: Look = .classic
    @State private var replaying = false

    var body: some View {
        FlowLayout(spacing: 10) {
            ForEach(items) { item in
                DotMindView(
                    activity: shown(item.activity),
                    size: 30,
                    label: item.label,
                    scene: item.scene,
                    look: item.look ?? look
                )
                    .accessibilityHint(Text(item.id))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .task { await replayEndings() }
    }

    private func shown(_ activity: Activity) -> Activity {
        let ending = activity.phase == .done || activity.phase == .error
        return replaying && ending ? .idle : activity
    }

    private func replayEndings() async {
        while !Task.isCancelled {
            do {
                try await Task.sleep(for: .seconds(4))
                replaying = true
                try await Task.sleep(for: .milliseconds(50))
                replaying = false
            } catch {
                return
            }
        }
    }
}
