package io.github.farhad1618.dotmind.adapters

import io.github.farhad1618.dotmind.AgentEvent

public fun interface StreamTranslator<E> {
    public fun translate(event: E): List<AgentEvent>
}
