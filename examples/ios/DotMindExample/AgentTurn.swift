import DotMind
import SwiftUI

@MainActor
final class AgentTurn: ObservableObject {
    private struct Step {
        let delay: Duration
        let event: AgentEvent
    }

    let tracker = ActivityTracker()
    @Published private(set) var trail: [String] = []

    private static let script: [Step] = {
        var steps = [
            Step(delay: .milliseconds(500), event: .start),
            Step(delay: .milliseconds(900), event: .thinking(chars: 140)),
            Step(delay: .milliseconds(900), event: .thinking(chars: 220)),
            Step(delay: .milliseconds(600), event: .tool(name: "web_search", id: "search")),
            Step(delay: .milliseconds(2600), event: .toolResult(id: "search")),
            Step(delay: .milliseconds(1100), event: .thinking(chars: 90)),
            Step(delay: .milliseconds(500), event: .tool(name: "bash", id: "code")),
            Step(delay: .milliseconds(2600), event: .toolResult(id: "code")),
            Step(delay: .milliseconds(700), event: .thinking(chars: 40)),
            Step(delay: .milliseconds(500), event: .tool(name: "deploy_preview", id: "deploy")),
            Step(delay: .milliseconds(2600), event: .toolResult(id: "deploy")),
            Step(delay: .milliseconds(900), event: .thinking(chars: 60)),
        ]
        steps += (0..<10).map { _ in Step(delay: .milliseconds(320), event: .text(chars: 48)) }
        steps.append(Step(delay: .milliseconds(500), event: .finish()))
        return steps
    }()

    func play() async {
        while !Task.isCancelled {
            trail.removeAll()
            tracker.reset()
            for step in Self.script {
                guard await pause(step.delay) else { return }
                tracker.push(step.event)
                record(tracker.activity)
            }
            guard await pause(.seconds(3)) else { return }
        }
    }

    private func record(_ activity: Activity) {
        guard activity.phase != .idle else { return }
        let label = labelFor(activity)
        if trail.last != label { trail.append(label) }
    }

    private func pause(_ duration: Duration) async -> Bool {
        do {
            try await Task.sleep(for: duration)
            return true
        } catch {
            return false
        }
    }
}
