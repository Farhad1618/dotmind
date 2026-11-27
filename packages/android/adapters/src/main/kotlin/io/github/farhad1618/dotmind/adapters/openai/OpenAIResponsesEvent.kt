package io.github.farhad1618.dotmind.adapters.openai

import io.github.farhad1618.dotmind.adapters.StreamJson
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.JsonObject

@Serializable
public data class OpenAIResponsesEvent(
    val type: String,
    val delta: String? = null,
    val item: OpenAIResponseItem? = null,
    val response: OpenAIResponse? = null,
    val message: String? = null,
) {
    public companion object {
        public fun decode(json: String): OpenAIResponsesEvent = StreamJson.decodeFromString(serializer(), json)

        public fun decode(json: JsonObject): OpenAIResponsesEvent = StreamJson.decodeFromJsonElement(serializer(), json)
    }
}

@Serializable
public data class OpenAIResponseItem(
    val type: String,
    val name: String? = null,
    val id: String? = null,
    @SerialName("call_id") val callId: String? = null,
    @SerialName("server_label") val serverLabel: String? = null,
)

@Serializable
public data class OpenAIResponse(
    val output: List<OpenAIResponseItem>? = null,
)
