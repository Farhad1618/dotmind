import XCTest
@testable import DotMindCore

@MainActor
final class OpenAIAdapterTests: XCTestCase {
    func testResponsesReasoningWebSearchFunctionCallPending() async throws {
        let tracker = ActivityTracker()
        let recorder = PhaseRecorder(tracker)
        try await followOpenAIResponses(
            sequence([
                OpenAIResponsesEvent(type: "response.created"),
                OpenAIResponsesEvent(type: "response.output_item.added", item: .init(type: "reasoning")),
                OpenAIResponsesEvent(type: "response.reasoning_summary_text.delta", delta: "Looking up"),
                OpenAIResponsesEvent(type: "response.output_item.added", item: .init(type: "web_search_call", id: "ws")),
                OpenAIResponsesEvent(type: "response.output_item.done", item: .init(type: "web_search_call", id: "ws")),
                OpenAIResponsesEvent(type: "response.output_item.added", item: .init(type: "message")),
                OpenAIResponsesEvent(type: "response.output_text.delta", delta: "Here is"),
                OpenAIResponsesEvent(
                    type: "response.output_item.added",
                    item: .init(type: "function_call", name: "read_file", callId: "c1")
                ),
                OpenAIResponsesEvent(type: "response.function_call_arguments.delta", delta: "{\"path\""),
                OpenAIResponsesEvent(
                    type: "response.completed",
                    response: .init(output: [.init(type: "message"), .init(type: "function_call", name: "read_file")])
                ),
            ]),
            tracker: tracker
        )
        XCTAssertEqual(recorder.seen, ["idle", "thinking", "tool:web_search", "thinking", "writing", "tool:read_file"])
        XCTAssertEqual(tracker.activity.kind, .file)
    }

    func testResponsesDecodeFromRawServerSentEvents() async throws {
        let stream = """
        event: response.created
        data: {"type":"response.created","response":{"id":"r1","output":[]}}

        data: {"type":"response.output_item.added","output_index":0,"item":{"type":"mcp_approval_request","name":"deploy_config","id":"ap1","arguments":"{}"}}

        data: {"type":"response.output_item.added","output_index":1,"item":{"type":"message","content":[]}}

        data: {"type":"response.output_text.delta","delta":"Done."}

        data: {"type":"response.completed","response":{"output":[{"type":"message","content":[{"type":"output_text"}]}]}}
        """
        let tracker = ActivityTracker()
        let recorder = PhaseRecorder(tracker)
        try await followOpenAIResponses(lines(stream).serverSentEvents(OpenAIResponsesEvent.self), tracker: tracker)
        XCTAssertEqual(recorder.seen, ["idle", "thinking", "waiting:deploy_config", "writing", "done"])
        XCTAssertEqual(tracker.activity.progress, 5)
    }

    func testChatCompletionsReasoningThenToolCalls() async throws {
        let tracker = ActivityTracker()
        let recorder = PhaseRecorder(tracker)
        try await followChatCompletions(
            sequence([
                ChatCompletionChunk(choices: [.init(delta: .init(reasoningContent: "hmm"))]),
                ChatCompletionChunk(choices: [.init(delta: .init(content: "Let me check."))]),
                ChatCompletionChunk(choices: [.init(delta: .init(toolCalls: [
                    .init(id: "1", function: .init(name: "search_docs", arguments: "")),
                ]))]),
                ChatCompletionChunk(choices: [.init(delta: .init(toolCalls: [
                    .init(function: .init(arguments: "{\"q\":\"x\"}")),
                ]))]),
                ChatCompletionChunk(choices: [.init(delta: .init(), finishReason: "tool_calls")]),
            ]),
            tracker: tracker
        )
        XCTAssertEqual(recorder.seen, ["idle", "thinking", "writing", "tool:search_docs"])
    }

    func testChatCompletionsDecodeFromRawServerSentEventsAndSkipDone() async throws {
        let stream = """
        data: {"id":"c","choices":[{"index":0,"delta":{"role":"assistant","content":null,"reasoning":"Plan"}}]}

        data: {"id":"c","choices":[{"index":0,"delta":{"content":"Hi there"},"finish_reason":null}]}

        data: {"id":"c","choices":[{"index":0,"delta":{},"finish_reason":"stop"}]}

        data: [DONE]
        """
        let tracker = ActivityTracker()
        let recorder = PhaseRecorder(tracker)
        try await followChatCompletions(lines(stream).serverSentEvents(ChatCompletionChunk.self), tracker: tracker)
        XCTAssertEqual(recorder.seen, ["idle", "thinking", "writing", "done"])
        XCTAssertEqual(tracker.activity.progress, 12)
    }

    func testAChatCompletionsStreamThatThrowsShowsTheError() async {
        let tracker = ActivityTracker()
        do {
            try await followChatCompletions(sequence([ChatCompletionChunk(choices: [])], failing: true), tracker: tracker)
            XCTFail("expected the stream to throw")
        } catch {
            XCTAssertTrue(error is StreamFailure)
        }
        XCTAssertEqual(tracker.activity.phase, .error)
    }
}
