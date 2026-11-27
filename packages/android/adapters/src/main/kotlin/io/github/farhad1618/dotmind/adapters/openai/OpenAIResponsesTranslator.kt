package io.github.farhad1618.dotmind.adapters.openai

import io.github.farhad1618.dotmind.AgentEvent
import io.github.farhad1618.dotmind.adapters.StreamTranslator

public class OpenAIResponsesTranslator : StreamTranslator<OpenAIResponsesEvent> {
    override fun translate(event: OpenAIResponsesEvent): List<AgentEvent> {
        val item = event.item
        return when (event.type) {
            "response.created" -> listOf(AgentEvent.Start)
            "response.output_item.added" -> item?.let(::itemAdded).orEmpty()
            "response.output_item.done" -> item?.let(::itemDone).orEmpty()
            "response.reasoning_summary_text.delta",
            "response.reasoning_text.delta",
            -> listOf(AgentEvent.Thinking(event.delta?.length ?: 0))
            "response.output_text.delta",
            "response.refusal.delta",
            -> listOf(AgentEvent.Text(event.delta?.length ?: 0))
            "response.function_call_arguments.delta",
            "response.custom_tool_call_input.delta",
            "response.mcp_call_arguments.delta",
            -> listOf(AgentEvent.ToolInput(event.delta?.length ?: 0))
            "response.completed",
            "response.incomplete",
            -> listOf(AgentEvent.Finish(pendingTools = event.response?.output.orEmpty().any { it.type in CLIENT_CALLS }))
            "response.failed", "error" -> listOf(AgentEvent.Error(event.message))
            else -> emptyList()
        }
    }

    private fun itemAdded(item: OpenAIResponseItem): List<AgentEvent> = when (item.type) {
        "reasoning" -> listOf(AgentEvent.Thinking())
        "message" -> listOf(AgentEvent.Text(0))
        "mcp_approval_request" -> listOf(AgentEvent.Approval(item.name, item.id))
        else -> toolName(item)?.takeIf { it.isNotEmpty() }?.let { listOf(AgentEvent.Tool(it, item.callId ?: item.id)) }.orEmpty()
    }

    private fun itemDone(item: OpenAIResponseItem): List<AgentEvent> = when {
        item.type in SERVER_TOOLS && item.type !in CLIENT_CALLS -> listOf(AgentEvent.ToolResult(item.id))
        item.type == "mcp_call" -> listOf(AgentEvent.ToolResult(item.callId ?: item.id))
        else -> emptyList()
    }

    private fun toolName(item: OpenAIResponseItem): String? = when (item.type) {
        "function_call", "custom_tool_call", "mcp_call" -> item.name
        else -> SERVER_TOOLS[item.type]
    }

    private companion object {
        val SERVER_TOOLS = mapOf(
            "web_search_call" to "web_search",
            "file_search_call" to "file_search",
            "code_interpreter_call" to "code_interpreter",
            "computer_call" to "computer",
            "image_generation_call" to "image_generation",
            "local_shell_call" to "shell",
            "shell_call" to "shell",
        )
        val CLIENT_CALLS = setOf("function_call", "custom_tool_call", "local_shell_call", "shell_call", "computer_call")
    }
}
