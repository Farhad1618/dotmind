package io.github.farhad1618.dotmind

import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import java.util.concurrent.CopyOnWriteArraySet

public class ActivityTracker(private val tools: Map<String, ToolKind> = emptyMap()) {
    private val lock = Any()
    private val state = MutableStateFlow(Activity(Phase.IDLE, progress = 0))
    private val listeners = CopyOnWriteArraySet<(Activity) -> Unit>()
    private val openTools = LinkedHashMap<String, String>()

    public val activity: StateFlow<Activity> = state.asStateFlow()

    public val current: Activity get() = state.value

    public fun subscribe(listener: (Activity) -> Unit): () -> Unit {
        synchronized(lock) {
            listeners.add(listener)
            listener(state.value)
        }
        return { listeners.remove(listener) }
    }

    public fun reset() {
        synchronized(lock) {
            openTools.clear()
            transition(Activity(Phase.IDLE, progress = 0))
        }
    }

    public fun push(event: AgentEvent) {
        synchronized(lock) { transition(next(event)) }
    }

    public fun pushAll(events: Iterable<AgentEvent>) {
        for (event in events) push(event)
    }

    private fun next(event: AgentEvent): Activity {
        val now = state.value
        val progress = now.progress ?: 0
        return when (event) {
            AgentEvent.Start -> {
                openTools.clear()
                Activity(Phase.THINKING, progress = progress)
            }
            is AgentEvent.Thinking -> Activity(Phase.THINKING, progress = progress + event.chars)
            is AgentEvent.Tool -> {
                event.id?.let { openTools[it] = event.name }
                Activity(Phase.TOOL, tool = event.name, kind = classifyTool(event.name, tools), progress = progress)
            }
            is AgentEvent.ToolInput -> now.copy(progress = progress + event.chars)
            is AgentEvent.ToolResult -> {
                event.id?.let { openTools.remove(it) }
                Activity(Phase.THINKING, progress = progress)
            }
            is AgentEvent.Text -> Activity(Phase.WRITING, progress = progress + event.chars)
            is AgentEvent.Approval ->
                Activity(Phase.WAITING, tool = event.name, kind = classifyTool(event.name, tools), progress = progress)
            is AgentEvent.Error -> Activity(Phase.ERROR, progress = progress)
            is AgentEvent.Finish -> if (!event.pendingTools) {
                Activity(Phase.DONE, progress = progress)
            } else {
                val last = openTools.values.lastOrNull() ?: now.tool
                Activity(Phase.TOOL, tool = last, kind = classifyTool(last, tools), progress = progress)
            }
        }
    }

    private fun transition(next: Activity) {
        val previous = state.value
        val same = previous.phase == next.phase && previous.tool == next.tool &&
            previous.kind == next.kind && previous.progress == next.progress
        if (same) return
        state.value = next
        for (listener in listeners) listener(next)
    }
}
