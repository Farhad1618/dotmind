package io.github.farhad1618.dotmind.adapters.openai

import io.github.farhad1618.dotmind.AgentEvent
import io.github.farhad1618.dotmind.adapters.StreamTranslator

public class ChatCompletionsTranslator : StreamTranslator<ChatCompletionChunk> {
    private var started = false

    override fun translate(event: ChatCompletionChunk): List<AgentEvent> {
        val out = ArrayList<AgentEvent>(4)
        if (!started) {
            started = true
            out.add(AgentEvent.Start)
        }
        val choice = event.choices?.firstOrNull()
        val delta = choice?.delta
        val reasoning = delta?.reasoning ?: delta?.reasoningContent
        if (!reasoning.isNullOrEmpty()) out.add(AgentEvent.Thinking(reasoning.length))
        for (call in delta?.toolCalls.orEmpty()) {
            val name = call.function?.name
            val arguments = call.function?.arguments
            if (!name.isNullOrEmpty()) out.add(AgentEvent.Tool(name, call.id))
            if (!arguments.isNullOrEmpty()) out.add(AgentEvent.ToolInput(arguments.length))
        }
        val content = delta?.content
        if (!content.isNullOrEmpty()) out.add(AgentEvent.Text(content.length))
        val finish = choice?.finishReason
        if (!finish.isNullOrEmpty()) out.add(AgentEvent.Finish(pendingTools = finish == "tool_calls"))
        return out
    }
}
