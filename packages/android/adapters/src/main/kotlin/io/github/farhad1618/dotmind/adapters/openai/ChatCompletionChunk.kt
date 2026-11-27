package io.github.farhad1618.dotmind.adapters.openai

import io.github.farhad1618.dotmind.adapters.StreamJson
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.JsonObject

@Serializable
public data class ChatCompletionChunk(
    val choices: List<ChatCompletionChoice>? = null,
) {
    public companion object {
        public fun decode(json: String): ChatCompletionChunk = StreamJson.decodeFromString(serializer(), json)

        public fun decode(json: JsonObject): ChatCompletionChunk = StreamJson.decodeFromJsonElement(serializer(), json)
    }
}

@Serializable
public data class ChatCompletionChoice(
    val delta: ChatCompletionDelta? = null,
    @SerialName("finish_reason") val finishReason: String? = null,
)

@Serializable
public data class ChatCompletionDelta(
    val content: String? = null,
    val reasoning: String? = null,
    @SerialName("reasoning_content") val reasoningContent: String? = null,
    @SerialName("tool_calls") val toolCalls: List<ChatCompletionToolCall>? = null,
)

@Serializable
public data class ChatCompletionToolCall(
    val index: Int? = null,
    val id: String? = null,
    val function: ChatCompletionFunction? = null,
)

@Serializable
public data class ChatCompletionFunction(
    val name: String? = null,
    val arguments: String? = null,
)
