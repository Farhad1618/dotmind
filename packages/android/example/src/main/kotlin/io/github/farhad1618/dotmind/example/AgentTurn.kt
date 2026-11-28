package io.github.farhad1618.dotmind.example

import io.github.farhad1618.dotmind.ActivityTracker
import io.github.farhad1618.dotmind.AgentEvent
import kotlinx.coroutines.delay

internal data class Beat(val event: AgentEvent, val line: String, val holdMillis: Long)

internal val TurnSteps: List<String> = listOf("Thinking", "Searching", "Running code", "Writing", "Done")

internal val ScriptedTurn: List<Beat> = buildList {
    add(Beat(AgentEvent.Start, "message_start", 500))
    repeat(5) { add(Beat(AgentEvent.Thinking(chars = 36), "thinking_delta +36", 320)) }
    add(Beat(AgentEvent.Tool("web_search", id = "toolu_01"), "tool_use web_search", 260))
    repeat(3) { add(Beat(AgentEvent.ToolInput(chars = 14), "input_json_delta +14", 220)) }
    add(Beat(AgentEvent.ToolInput(chars = 9), "input_json_delta +9", 1600))
    add(Beat(AgentEvent.ToolResult(id = "toolu_01"), "tool_result toolu_01", 300))
    repeat(3) { add(Beat(AgentEvent.Thinking(chars = 28), "thinking_delta +28", 300)) }
    add(Beat(AgentEvent.Tool("bash", id = "toolu_02"), "tool_use bash", 260))
    repeat(3) { add(Beat(AgentEvent.ToolInput(chars = 22), "input_json_delta +22", 220)) }
    add(Beat(AgentEvent.ToolInput(chars = 11), "input_json_delta +11", 1800))
    add(Beat(AgentEvent.ToolResult(id = "toolu_02"), "tool_result toolu_02", 300))
    repeat(14) { add(Beat(AgentEvent.Text(chars = 48), "text_delta +48", 210)) }
    add(Beat(AgentEvent.Finish(), "message_stop", 2600))
}

internal suspend fun playTurn(tracker: ActivityTracker, log: (String) -> Unit) {
    for (beat in ScriptedTurn) {
        tracker.push(beat.event)
        log(beat.line)
        delay(beat.holdMillis)
    }
}
