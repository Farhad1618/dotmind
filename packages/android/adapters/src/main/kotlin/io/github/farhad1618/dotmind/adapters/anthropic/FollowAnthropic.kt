package io.github.farhad1618.dotmind.adapters.anthropic

import io.github.farhad1618.dotmind.ActivityTracker
import io.github.farhad1618.dotmind.adapters.followWith
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import kotlinx.serialization.json.JsonObject

public suspend fun followAnthropicStream(
    events: Flow<AnthropicStreamEvent>,
    tracker: ActivityTracker = ActivityTracker(),
): ActivityTracker = events.followWith(AnthropicTranslator(), tracker)

public fun Flow<JsonObject>.asAnthropicEvents(): Flow<AnthropicStreamEvent> = map { AnthropicStreamEvent.decode(it) }
