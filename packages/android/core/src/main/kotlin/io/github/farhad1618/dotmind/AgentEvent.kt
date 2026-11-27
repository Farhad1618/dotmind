package io.github.farhad1618.dotmind

public sealed interface AgentEvent {
    public data object Start : AgentEvent

    public data class Thinking(val chars: Int = 0) : AgentEvent

    public data class Tool(val name: String, val id: String? = null) : AgentEvent

    public data class ToolInput(val chars: Int = 0) : AgentEvent

    public data class ToolResult(val id: String? = null, val error: Boolean = false) : AgentEvent

    public data class Text(val chars: Int = 0) : AgentEvent

    public data class Approval(val name: String? = null, val id: String? = null) : AgentEvent

    public data class Error(val message: String? = null) : AgentEvent

    public data class Finish(val pendingTools: Boolean = false) : AgentEvent
}
