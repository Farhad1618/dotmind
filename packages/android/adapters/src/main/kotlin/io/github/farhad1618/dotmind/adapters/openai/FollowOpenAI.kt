package io.github.farhad1618.dotmind.adapters.openai

import io.github.farhad1618.dotmind.ActivityTracker
import io.github.farhad1618.dotmind.adapters.followWith
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import kotlinx.serialization.json.JsonObject

public suspend fun followOpenAIResponses(
    events: Flow<OpenAIResponsesEvent>,
    tracker: ActivityTracker = ActivityTracker(),
): ActivityTracker = events.followWith(OpenAIResponsesTranslator(), tracker)

public suspend fun followChatCompletions(
    chunks: Flow<ChatCompletionChunk>,
    tracker: ActivityTracker = ActivityTracker(),
): ActivityTracker = chunks.followWith(ChatCompletionsTranslator(), tracker)

public fun Flow<JsonObject>.asOpenAIResponsesEvents(): Flow<OpenAIResponsesEvent> = map { OpenAIResponsesEvent.decode(it) }

public fun Flow<JsonObject>.asChatCompletionChunks(): Flow<ChatCompletionChunk> = map { ChatCompletionChunk.decode(it) }
