public struct OpenAIResponsesTranslator: EventTranslator {
    private static let serverTools: [String: String] = [
        "web_search_call": "web_search",
        "file_search_call": "file_search",
        "code_interpreter_call": "code_interpreter",
        "computer_call": "computer",
        "image_generation_call": "image_generation",
        "local_shell_call": "shell",
        "shell_call": "shell",
    ]
    private static let clientCalls: Set<String> = [
        "function_call", "custom_tool_call", "local_shell_call", "shell_call", "computer_call",
    ]
    private static let namedCalls: Set<String> = ["function_call", "custom_tool_call", "mcp_call"]

    public init() {}

    public mutating func translate(_ event: OpenAIResponsesEvent) -> [AgentEvent] {
        switch event.type {
        case "response.created":
            return [.start]
        case "response.output_item.added":
            return event.item.map(Self.itemAdded) ?? []
        case "response.output_item.done":
            return event.item.map(Self.itemDone) ?? []
        case "response.reasoning_summary_text.delta", "response.reasoning_text.delta":
            return [.thinking(chars: event.delta.jsLength)]
        case "response.output_text.delta", "response.refusal.delta":
            return [.text(chars: event.delta.jsLength)]
        case "response.function_call_arguments.delta",
             "response.custom_tool_call_input.delta",
             "response.mcp_call_arguments.delta":
            return [.toolInput(chars: event.delta.jsLength)]
        case "response.completed", "response.incomplete":
            let pending = event.response?.output?.contains { Self.clientCalls.contains($0.type) } ?? false
            return [.finish(pendingTools: pending)]
        case "response.failed", "error":
            return [.error(message: event.message)]
        default:
            return []
        }
    }

    private static func itemAdded(_ item: OpenAIResponsesEvent.Item) -> [AgentEvent] {
        switch item.type {
        case "reasoning": return [.thinking()]
        case "message": return [.text(chars: 0)]
        case "mcp_approval_request": return [.approval(name: item.name, id: item.id)]
        default:
            guard let name = toolName(item).nonEmpty else { return [] }
            return [.tool(name: name, id: item.callId ?? item.id)]
        }
    }

    private static func itemDone(_ item: OpenAIResponsesEvent.Item) -> [AgentEvent] {
        if serverTools[item.type] != nil && !clientCalls.contains(item.type) {
            return [.toolResult(id: item.id)]
        }
        if item.type == "mcp_call" {
            return [.toolResult(id: item.callId ?? item.id)]
        }
        return []
    }

    private static func toolName(_ item: OpenAIResponsesEvent.Item) -> String? {
        namedCalls.contains(item.type) ? item.name : serverTools[item.type]
    }
}
