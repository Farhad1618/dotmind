public struct ChatCompletionsTranslator: EventTranslator {
    private var started = false

    public init() {}

    public mutating func translate(_ chunk: ChatCompletionChunk) -> [AgentEvent] {
        var events: [AgentEvent] = []
        if !started {
            started = true
            events.append(.start)
        }
        let choice = chunk.choices?.first
        let delta = choice?.delta
        if let reasoning = (delta?.reasoning ?? delta?.reasoningContent).nonEmpty {
            events.append(.thinking(chars: reasoning.jsLength))
        }
        for call in delta?.toolCalls ?? [] {
            if let name = call.function?.name.nonEmpty { events.append(.tool(name: name, id: call.id)) }
            if let arguments = call.function?.arguments.nonEmpty { events.append(.toolInput(chars: arguments.jsLength)) }
        }
        if let content = delta?.content.nonEmpty { events.append(.text(chars: content.jsLength)) }
        if let reason = choice?.finishReason.nonEmpty { events.append(.finish(pendingTools: reason == "tool_calls")) }
        return events
    }
}
