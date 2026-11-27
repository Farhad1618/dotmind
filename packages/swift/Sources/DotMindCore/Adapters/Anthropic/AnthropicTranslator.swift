public struct AnthropicTranslator: EventTranslator {
    private static let toolCallBlocks: Set<String> = ["tool_use", "server_tool_use", "mcp_tool_use"]
    private static let pendingStops: Set<String> = ["tool_use", "pause_turn"]

    private var stopReason: String?

    public init() {}

    public mutating func translate(_ event: AnthropicStreamEvent) -> [AgentEvent] {
        switch event.type {
        case "message_start":
            stopReason = nil
            return [.start]
        case "content_block_start":
            return event.contentBlock.map(Self.blockStarted) ?? []
        case "content_block_delta":
            return event.delta.map(Self.deltaReceived) ?? []
        case "message_delta":
            stopReason = event.delta?.stopReason ?? stopReason
            return []
        case "message_stop":
            let pending = stopReason.nonEmpty.map(Self.pendingStops.contains) ?? false
            return [.finish(pendingTools: pending)]
        case "error":
            return [.error(message: event.error?.message)]
        default:
            return []
        }
    }

    private static func blockStarted(_ block: AnthropicStreamEvent.ContentBlock) -> [AgentEvent] {
        if block.type == "thinking" || block.type == "redacted_thinking" { return [.thinking()] }
        if block.type == "text" { return [.text(chars: 0)] }
        if toolCallBlocks.contains(block.type), let name = block.name.nonEmpty {
            return [.tool(name: name, id: block.id)]
        }
        if block.type.hasSuffix("_tool_result") {
            return [.toolResult(id: block.toolUseId, error: failed(block))]
        }
        return []
    }

    private static func deltaReceived(_ delta: AnthropicStreamEvent.Delta) -> [AgentEvent] {
        switch delta.type {
        case "thinking_delta": [.thinking(chars: delta.thinking.jsLength)]
        case "text_delta": [.text(chars: delta.text.jsLength)]
        case "input_json_delta": [.toolInput(chars: delta.partialJson.jsLength)]
        default: []
        }
    }

    private static func failed(_ block: AnthropicStreamEvent.ContentBlock) -> Bool {
        if block.isError == true { return true }
        return block.contentType?.hasSuffix("error") ?? false
    }
}
