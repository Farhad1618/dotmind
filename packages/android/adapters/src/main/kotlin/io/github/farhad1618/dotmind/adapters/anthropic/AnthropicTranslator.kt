package io.github.farhad1618.dotmind.adapters.anthropic

import io.github.farhad1618.dotmind.AgentEvent
import io.github.farhad1618.dotmind.adapters.StreamTranslator
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive

public class AnthropicTranslator : StreamTranslator<AnthropicStreamEvent> {
    private var stopReason: String? = null

    override fun translate(event: AnthropicStreamEvent): List<AgentEvent> = when (event.type) {
        "message_start" -> {
            stopReason = null
            listOf(AgentEvent.Start)
        }
        "content_block_start" -> event.contentBlock?.let(::blockStarted).orEmpty()
        "content_block_delta" -> deltaOf(event.delta)
        "message_delta" -> {
            stopReason = event.delta?.stopReason ?: stopReason
            emptyList()
        }
        "message_stop" -> listOf(AgentEvent.Finish(pendingTools = stopReason in PENDING_STOPS))
        "error" -> listOf(AgentEvent.Error(event.error?.message))
        else -> emptyList()
    }

    private fun blockStarted(block: AnthropicContentBlock): List<AgentEvent> {
        val name = block.name
        return when {
            block.type == "thinking" || block.type == "redacted_thinking" -> listOf(AgentEvent.Thinking())
            block.type == "text" -> listOf(AgentEvent.Text(0))
            block.type in TOOL_CALL_BLOCKS && !name.isNullOrEmpty() -> listOf(AgentEvent.Tool(name, block.id))
            block.type.endsWith("_tool_result") -> listOf(AgentEvent.ToolResult(block.toolUseId, failed(block)))
            else -> emptyList()
        }
    }

    private fun deltaOf(delta: AnthropicDelta?): List<AgentEvent> = when (delta?.type) {
        "thinking_delta" -> listOf(AgentEvent.Thinking(delta.thinking?.length ?: 0))
        "text_delta" -> listOf(AgentEvent.Text(delta.text?.length ?: 0))
        "input_json_delta" -> listOf(AgentEvent.ToolInput(delta.partialJson?.length ?: 0))
        else -> emptyList()
    }

    private fun failed(block: AnthropicContentBlock): Boolean {
        if (block.isError == true) return true
        val type = ((block.content as? JsonObject)?.get("type") as? JsonPrimitive)?.takeIf { it.isString }?.content
        return type?.endsWith("error") == true
    }

    private companion object {
        val TOOL_CALL_BLOCKS = setOf("tool_use", "server_tool_use", "mcp_tool_use")
        val PENDING_STOPS = setOf("tool_use", "pause_turn")
    }
}
