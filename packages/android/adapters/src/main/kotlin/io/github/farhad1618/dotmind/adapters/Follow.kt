package io.github.farhad1618.dotmind.adapters

import io.github.farhad1618.dotmind.ActivityTracker
import io.github.farhad1618.dotmind.AgentEvent
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.flow.Flow

public suspend fun <E> Flow<E>.followWith(
    translator: StreamTranslator<E>,
    tracker: ActivityTracker = ActivityTracker(),
): ActivityTracker {
    try {
        collect { event -> tracker.pushAll(translator.translate(event)) }
    } catch (cancelled: CancellationException) {
        throw cancelled
    } catch (failure: Throwable) {
        tracker.push(AgentEvent.Error(failure.message ?: failure.toString()))
        throw failure
    }
    return tracker
}
