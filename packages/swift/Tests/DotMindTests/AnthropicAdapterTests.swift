import XCTest
@testable import DotMindCore

@MainActor
final class AnthropicAdapterTests: XCTestCase {
    func testThinkingServerSearchTextDone() async throws {
        let tracker = ActivityTracker()
        let recorder = PhaseRecorder(tracker)
        let events = lines(anthropicTurn).serverSentEvents(AnthropicStreamEvent.self)
        try await followAnthropicStream(events, tracker: tracker)
        XCTAssertEqual(
            recorder.seen,
            ["idle", "thinking", "tool:web_search", "thinking", "tool:run_sql", "thinking", "writing", "done"]
        )
    }

    func testAClientToolCallLeavesTheToolShowing() async throws {
        let tracker = ActivityTracker()
        try await followAnthropicStream(
            sequence([
                AnthropicStreamEvent(type: "message_start"),
                AnthropicStreamEvent(type: "content_block_start", contentBlock: .init(type: "tool_use", name: "bash", id: "t1")),
                AnthropicStreamEvent(type: "content_block_delta", delta: .init(type: "input_json_delta", partialJson: "{\"cmd\":\"ls\"}")),
                AnthropicStreamEvent(type: "message_delta", delta: .init(stopReason: "tool_use")),
                AnthropicStreamEvent(type: "message_stop"),
            ]),
            tracker: tracker
        )
        XCTAssertEqual(tracker.activity.phase, .tool)
        XCTAssertEqual(tracker.activity.kind, .code)
    }

    func testPauseTurnAlsoLeavesTheToolShowing() {
        var translator = AnthropicTranslator()
        _ = translator.translate(AnthropicStreamEvent(type: "message_start"))
        _ = translator.translate(AnthropicStreamEvent(type: "message_delta", delta: .init(stopReason: "pause_turn")))
        _ = translator.translate(AnthropicStreamEvent(type: "message_delta", delta: .init()))
        XCTAssertEqual(translator.translate(AnthropicStreamEvent(type: "message_stop")), [.finish(pendingTools: true)])
    }

    func testAStreamThatThrowsShowsTheError() async {
        let tracker = ActivityTracker()
        do {
            try await followAnthropicStream(sequence([AnthropicStreamEvent(type: "message_start")], failing: true), tracker: tracker)
            XCTFail("expected the stream to throw")
        } catch {
            XCTAssertTrue(error is StreamFailure)
        }
        XCTAssertEqual(tracker.activity.phase, .error)
    }

    func testFailedToolResultsAreFlagged() throws {
        let json = #"{"type":"content_block_start","index":2,"content_block":{"type":"web_fetch_tool_result","tool_use_id":"f1","content":{"type":"web_fetch_tool_result_error","error_code":"url_not_accessible"}}}"#
        let event = try JSONDecoder().decode(AnthropicStreamEvent.self, from: Data(json.utf8))
        var translator = AnthropicTranslator()
        XCTAssertEqual(translator.translate(event), [.toolResult(id: "f1", error: true)])
    }

    func testTextLengthsCountUTF16UnitsLikeJavaScript() {
        var translator = AnthropicTranslator()
        let event = AnthropicStreamEvent(type: "content_block_delta", delta: .init(type: "text_delta", text: "héllo 👋"))
        XCTAssertEqual(translator.translate(event), [.text(chars: 8)])
    }
}
