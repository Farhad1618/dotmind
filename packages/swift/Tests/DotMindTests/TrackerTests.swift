import Combine
import XCTest
@testable import DotMindCore

@MainActor
final class TrackerTests: XCTestCase {
    func testTheTrackerFollowsAToolUsingTurn() {
        let tracker = ActivityTracker()
        var phases: [String] = []
        let subscription = tracker.$activity.sink { activity in
            let key = activity.phase == .tool ? "tool:\(activity.kind?.rawValue ?? "")" : activity.phase.rawValue
            if !phases.contains(key) { phases.append(key) }
        }
        tracker.push(contentsOf: [
            .start,
            .thinking(chars: 120),
            .tool(name: "web_search", id: "a"),
            .toolResult(id: "a"),
            .text(chars: 40),
            .text(chars: 40),
            .finish(),
        ])
        subscription.cancel()
        XCTAssertEqual(phases, ["idle", "thinking", "tool:search", "writing", "done"])
        XCTAssertEqual(tracker.activity.progress, 200)
    }

    func testATurnThatStopsToRunAClientToolStaysOnThatTool() {
        let tracker = ActivityTracker()
        tracker.push(contentsOf: [.start, .tool(name: "run_sql", id: "x"), .finish(pendingTools: true)])
        XCTAssertEqual(tracker.activity.phase, .tool)
        XCTAssertEqual(tracker.activity.kind, .database)
    }

    func testAnEmptyToolIdIsNeverTrackedAsOpen() {
        let tracker = ActivityTracker()
        tracker.push(contentsOf: [
            .start,
            .tool(name: "bash", id: "a"),
            .tool(name: "read_file", id: ""),
            .finish(pendingTools: true),
        ])
        XCTAssertEqual(tracker.activity.tool, "bash")
    }

    func testPendingToolsShowTheLastToolStillOpen() {
        let tracker = ActivityTracker()
        tracker.push(contentsOf: [
            .start,
            .tool(name: "bash", id: "a"),
            .tool(name: "read_file", id: "b"),
            .toolResult(id: "b"),
            .finish(pendingTools: true),
        ])
        XCTAssertEqual(tracker.activity.tool, "bash")
        XCTAssertEqual(tracker.activity.kind, .code)
    }

    func testOverridesAndApprovals() {
        let tracker = ActivityTracker(tools: ["lookup_customer": .database])
        tracker.push(.tool(name: "lookup_customer", id: "1"))
        XCTAssertEqual(tracker.activity.kind, .database)
        tracker.push(.approval(name: "deploy_config", id: "2"))
        XCTAssertEqual(tracker.activity.phase, .waiting)
        XCTAssertEqual(tracker.activity.tool, "deploy_config")
    }

    func testToolInputKeepsThePhaseAndCountsProgress() {
        let tracker = ActivityTracker()
        tracker.push(contentsOf: [.start, .tool(name: "bash", id: "1"), .toolInput(chars: 12)])
        XCTAssertEqual(tracker.activity.phase, .tool)
        XCTAssertEqual(tracker.activity.progress, 12)
    }

    func testUnchangedStateDoesNotPublish() {
        let tracker = ActivityTracker()
        var count = 0
        let subscription = tracker.$activity.sink { _ in count += 1 }
        tracker.push(contentsOf: [.start, .thinking(), .thinking(chars: 0), .error(), .error()])
        subscription.cancel()
        XCTAssertEqual(count, 3)
    }

    func testResetReturnsToIdle() {
        let tracker = ActivityTracker()
        tracker.push(contentsOf: [.start, .text(chars: 10)])
        tracker.reset()
        XCTAssertEqual(tracker.activity, Activity(phase: .idle, progress: 0))
    }
}
