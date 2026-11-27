package io.github.farhad1618.dotmind.adapters

import io.github.farhad1618.dotmind.ActivityTracker
import io.github.farhad1618.dotmind.Phase

fun ActivityTracker.record(): List<String> {
    val seen = mutableListOf<String>()
    subscribe { a ->
        val key = if (a.phase == Phase.TOOL || a.phase == Phase.WAITING) "${a.phase.id}:${a.tool}" else a.phase.id
        if (seen.lastOrNull() != key) seen.add(key)
    }
    return seen
}
