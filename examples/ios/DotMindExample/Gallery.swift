import DotMind
import SwiftUI

struct GalleryItem: Identifiable {
    let id: String
    let activity: Activity
    let label: DotMindLabel
    let scene: SceneName?

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

    static let states: [GalleryItem] = [
        .state(.thinking),
        .state(.tool, tool: "web_search"),
        .state(.tool, tool: "web_fetch"),
        .state(.tool, tool: "bash"),
        .state(.tool, tool: "read_file"),
        .state(.tool, tool: "run_sql"),
        .state(.tool, tool: "calculate_margin"),
        .state(.tool, tool: "get_weather"),
        .state(.writing),
        .state(.waiting, tool: "deploy_config"),
        .state(.error),
        .state(.done),
    ]

    static let scenes: [GalleryItem] = [
        SceneName.ember, .orbit, .prism, .serpent, .circuit, .pulse, .comet, .halo,
    ].map(scene)
}

struct Gallery: View {
    let items: [GalleryItem]
    @State private var replaying = false

    var body: some View {
        FlowLayout(spacing: 10) {
            ForEach(items) { item in
                DotMindView(activity: shown(item.activity), size: 30, label: item.label, scene: item.scene)
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
