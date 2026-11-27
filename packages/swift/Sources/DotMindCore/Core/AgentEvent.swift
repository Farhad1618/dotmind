public enum AgentEvent: Hashable, Sendable {
    case start
    case thinking(chars: Int = 0)
    case tool(name: String, id: String? = nil)
    case toolInput(chars: Int = 0)
    case toolResult(id: String? = nil, error: Bool = false)
    case text(chars: Int = 0)
    case approval(name: String? = nil, id: String? = nil)
    case error(message: String? = nil)
    case finish(pendingTools: Bool = false)
}
