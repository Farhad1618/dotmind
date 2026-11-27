import Foundation
import DotMindCore

struct StreamFailure: Error {}

func sequence<Element: Sendable>(_ items: [Element], failing: Bool = false) -> AsyncThrowingStream<Element, Error> {
    AsyncThrowingStream { continuation in
        for item in items { continuation.yield(item) }
        if failing {
            continuation.finish(throwing: StreamFailure())
        } else {
            continuation.finish()
        }
    }
}

func lines(_ text: String) -> AsyncThrowingStream<String, Error> {
    sequence(text.components(separatedBy: "\n"))
}

@MainActor
final class PhaseRecorder {
    private(set) var seen: [String] = []
    private var subscription: AnyObject?

    init(_ tracker: ActivityTracker) {
        subscription = tracker.$activity.sink { [weak self] activity in
            self?.record(activity)
        } as AnyObject
    }

    private func record(_ activity: Activity) {
        let key = activity.phase == .tool || activity.phase == .waiting
            ? "\(activity.phase.rawValue):\(activity.tool ?? "")"
            : activity.phase.rawValue
        if seen.last != key { seen.append(key) }
    }
}

let anthropicTurn = """
event: message_start
data: {"type":"message_start","message":{"role":"assistant"}}

event: content_block_start
data: {"type":"content_block_start","index":0,"content_block":{"type":"thinking","thinking":""}}

event: content_block_delta
data: {"type":"content_block_delta","index":0,"delta":{"type":"thinking_delta","thinking":"The pricing change landed in August."}}

data: {"type":"content_block_stop","index":0}

data: {"type":"content_block_start","index":1,"content_block":{"type":"server_tool_use","id":"srv_1","name":"web_search","input":{}}}

data: {"type":"content_block_delta","index":1,"delta":{"type":"input_json_delta","partial_json":"{\\"query\\":\\"gulf pricing change august\\"}"}}

data: {"type":"content_block_stop","index":1}

data: {"type":"content_block_start","index":2,"content_block":{"type":"web_search_tool_result","tool_use_id":"srv_1","content":[]}}

data: {"type":"content_block_stop","index":2}

data: {"type":"content_block_start","index":3,"content_block":{"type":"thinking","thinking":""}}

data: {"type":"content_block_delta","index":3,"delta":{"type":"thinking_delta","thinking":"Compare churn by region."}}

data: {"type":"content_block_start","index":4,"content_block":{"type":"mcp_tool_use","id":"mcp_1","name":"run_sql","server_name":"warehouse","input":{}}}

data: {"type":"content_block_delta","index":4,"delta":{"type":"input_json_delta","partial_json":"{\\"sql\\":\\"select 1\\"}"}}

data: {"type":"content_block_start","index":5,"content_block":{"type":"mcp_tool_result","tool_use_id":"mcp_1","is_error":false,"content":[]}}

data: {"type":"content_block_start","index":6,"content_block":{"type":"thinking","thinking":""}}

data: {"type":"content_block_delta","index":6,"delta":{"type":"thinking_delta","thinking":"Now write it up."}}

data: {"type":"content_block_start","index":7,"content_block":{"type":"text","text":""}}

data: {"type":"content_block_delta","index":7,"delta":{"type":"text_delta","text":"Churn rose in Q3."}}

data: {"type":"content_block_stop","index":7}

data: {"type":"message_delta","delta":{"stop_reason":"end_turn"}}

data: {"type":"message_stop"}
"""
