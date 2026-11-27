package io.github.farhad1618.dotmind.adapters

import io.github.farhad1618.dotmind.ActivityTracker
import io.github.farhad1618.dotmind.Phase
import io.github.farhad1618.dotmind.ToolKind
import io.github.farhad1618.dotmind.adapters.anthropic.AnthropicContentBlock
import io.github.farhad1618.dotmind.adapters.anthropic.AnthropicDelta
import io.github.farhad1618.dotmind.adapters.anthropic.AnthropicStreamEvent
import io.github.farhad1618.dotmind.adapters.anthropic.AnthropicTranslator
import io.github.farhad1618.dotmind.adapters.anthropic.asAnthropicEvents
import io.github.farhad1618.dotmind.adapters.anthropic.followAnthropicStream
import io.github.farhad1618.dotmind.AgentEvent
import kotlinx.coroutines.flow.asFlow
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.runBlocking
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.jsonObject
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith

class AnthropicAdapterTest {
    private fun recordedTurn(): List<String> =
        javaClass.getResource("/anthropic-turn.jsonl")!!.readText().lines().filter { it.isNotBlank() }

    @Test
    fun thinkingServerSearchTextDone() = runBlocking {
        val tracker = ActivityTracker()
        val seen = tracker.record()
        val events = recordedTurn().map { Json.parseToJsonElement(it).jsonObject }
        followAnthropicStream(events.asFlow().asAnthropicEvents(), tracker)
        assertEquals(
            listOf("idle", "thinking", "tool:web_search", "thinking", "tool:run_sql", "thinking", "writing", "done"),
            seen,
        )
    }

    @Test
    fun aClientToolCallLeavesTheToolShowing() = runBlocking {
        val tracker = ActivityTracker()
        followAnthropicStream(
            listOf(
                AnthropicStreamEvent("message_start"),
                AnthropicStreamEvent("content_block_start", contentBlock = AnthropicContentBlock("tool_use", name = "bash", id = "t1")),
                AnthropicStreamEvent("content_block_delta", delta = AnthropicDelta("input_json_delta", partialJson = "{\"cmd\":\"ls\"}")),
                AnthropicStreamEvent("message_delta", delta = AnthropicDelta(stopReason = "tool_use")),
                AnthropicStreamEvent("message_stop"),
            ).asFlow(),
            tracker,
        )
        assertEquals(Phase.TOOL, tracker.current.phase)
        assertEquals(ToolKind.CODE, tracker.current.kind)
    }

    @Test
    fun aStreamThatThrowsShowsTheError() {
        val tracker = ActivityTracker()
        val broken = flow {
            emit(AnthropicStreamEvent("message_start"))
            throw IllegalStateException("overloaded")
        }
        assertFailsWith<IllegalStateException> { runBlocking { followAnthropicStream(broken, tracker) } }
        assertEquals(Phase.ERROR, tracker.current.phase)
    }

    @Test
    fun failedResultsAndErrorEventsAreRecognised() {
        val translate = AnthropicTranslator()
        val failed = AnthropicStreamEvent.decode(
            """{"type":"content_block_start","content_block":{"type":"web_search_tool_result","tool_use_id":"s","content":{"type":"web_search_tool_result_error","error_code":"unavailable"}}}""",
        )
        assertEquals(listOf<AgentEvent>(AgentEvent.ToolResult("s", error = true)), translate.translate(failed))
        val error = AnthropicStreamEvent.decode("""{"type":"error","error":{"type":"overloaded_error","message":"Overloaded"}}""")
        assertEquals(listOf<AgentEvent>(AgentEvent.Error("Overloaded")), translate.translate(error))
        assertEquals(
            listOf<AgentEvent>(AgentEvent.Finish(pendingTools = false)),
            translate.translate(AnthropicStreamEvent("message_stop")),
        )
    }
}
