package io.github.farhad1618.dotmind.adapters.anthropic

import io.github.farhad1618.dotmind.adapters.StreamJson
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonObject

@Serializable
public data class AnthropicStreamEvent(
    val type: String,
    val index: Int? = null,
    @SerialName("content_block") val contentBlock: AnthropicContentBlock? = null,
    val delta: AnthropicDelta? = null,
    val error: AnthropicError? = null,
) {
    public companion object {
        public fun decode(json: String): AnthropicStreamEvent = StreamJson.decodeFromString(serializer(), json)

        public fun decode(json: JsonObject): AnthropicStreamEvent = StreamJson.decodeFromJsonElement(serializer(), json)
    }
}

@Serializable
public data class AnthropicContentBlock(
    val type: String,
    val name: String? = null,
    val id: String? = null,
    @SerialName("tool_use_id") val toolUseId: String? = null,
    @SerialName("is_error") val isError: Boolean? = null,
    val content: JsonElement? = null,
)

@Serializable
public data class AnthropicDelta(
    val type: String? = null,
    val text: String? = null,
    val thinking: String? = null,
    @SerialName("partial_json") val partialJson: String? = null,
    @SerialName("stop_reason") val stopReason: String? = null,
)

@Serializable
public data class AnthropicError(
    val type: String? = null,
    val message: String? = null,
)
