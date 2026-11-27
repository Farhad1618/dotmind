package io.github.farhad1618.dotmind.adapters

import io.github.farhad1618.dotmind.ActivityTracker
import io.github.farhad1618.dotmind.Phase
import io.github.farhad1618.dotmind.ToolKind
import io.github.farhad1618.dotmind.adapters.openai.ChatCompletionChunk
import io.github.farhad1618.dotmind.adapters.openai.OpenAIResponsesEvent
import io.github.farhad1618.dotmind.adapters.openai.asChatCompletionChunks
import io.github.farhad1618.dotmind.adapters.openai.asOpenAIResponsesEvents
import io.github.farhad1618.dotmind.adapters.openai.followChatCompletions
import io.github.farhad1618.dotmind.adapters.openai.followOpenAIResponses
import kotlinx.coroutines.flow.asFlow
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.runBlocking
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.jsonObject
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith

class OpenAIAdapterTest {
    private fun objects(vararg json: String) = json.map { Json.parseToJsonElement(it).jsonObject }.asFlow()

    @Test
    fun responsesReasoningWebSearchFunctionCallPending() = runBlocking {
        val tracker = ActivityTracker()
        val seen = tracker.record()
        followOpenAIResponses(
            objects(
                """{"type":"response.created"}""",
                """{"type":"response.output_item.added","item":{"type":"reasoning"}}""",
                """{"type":"response.reasoning_summary_text.delta","delta":"Looking up"}""",
                """{"type":"response.output_item.added","item":{"type":"web_search_call","id":"ws"}}""",
                """{"type":"response.output_item.done","item":{"type":"web_search_call","id":"ws"}}""",
                """{"type":"response.output_item.added","item":{"type":"message"}}""",
                """{"type":"response.output_text.delta","delta":"Here is"}""",
                """{"type":"response.output_item.added","item":{"type":"function_call","name":"read_file","call_id":"c1"}}""",
                """{"type":"response.function_call_arguments.delta","delta":"{\"path\""}""",
                """{"type":"response.completed","response":{"output":[{"type":"message"},{"type":"function_call","name":"read_file"}]}}""",
            ).asOpenAIResponsesEvents(),
            tracker,
        )
        assertEquals(listOf("idle", "thinking", "tool:web_search", "thinking", "writing", "tool:read_file"), seen)
        assertEquals(ToolKind.FILE, tracker.current.kind)
    }

    @Test
    fun responsesApprovalThenAnswerFinishes() = runBlocking {
        val tracker = ActivityTracker()
        val seen = tracker.record()
        followOpenAIResponses(
            listOf(
                OpenAIResponsesEvent.decode("""{"type":"response.created"}"""),
                OpenAIResponsesEvent.decode("""{"type":"response.output_item.added","item":{"type":"code_interpreter_call","id":"ci"}}"""),
                OpenAIResponsesEvent.decode("""{"type":"response.output_item.done","item":{"type":"code_interpreter_call","id":"ci"}}"""),
                OpenAIResponsesEvent.decode("""{"type":"response.output_item.added","item":{"type":"mcp_approval_request","name":"deploy_config","id":"ap1"}}"""),
                OpenAIResponsesEvent.decode("""{"type":"response.output_item.added","item":{"type":"message"}}"""),
                OpenAIResponsesEvent.decode("""{"type":"response.output_text.delta","delta":"Done."}"""),
                OpenAIResponsesEvent.decode("""{"type":"response.completed","response":{"output":[{"type":"message"}]}}"""),
            ).asFlow(),
            tracker,
        )
        assertEquals(
            listOf("idle", "thinking", "tool:code_interpreter", "thinking", "waiting:deploy_config", "writing", "done"),
            seen,
        )
    }

    @Test
    fun chatCompletionsReasoningThenToolCalls() = runBlocking {
        val tracker = ActivityTracker()
        val seen = tracker.record()
        followChatCompletions(
            objects(
                """{"choices":[{"delta":{"reasoning_content":"hmm"}}]}""",
                """{"choices":[{"delta":{"content":"Let me check."}}]}""",
                """{"choices":[{"delta":{"tool_calls":[{"id":"1","function":{"name":"search_docs","arguments":""}}]}}]}""",
                """{"choices":[{"delta":{"tool_calls":[{"function":{"arguments":"{\"q\":\"x\"}"}}]}}]}""",
                """{"choices":[{"delta":{},"finish_reason":"tool_calls"}]}""",
            ).asChatCompletionChunks(),
            tracker,
        )
        assertEquals(listOf("idle", "thinking", "writing", "tool:search_docs"), seen)
    }

    @Test
    fun chatCompletionsStopFinishesAndNullsAreTolerated() = runBlocking {
        val tracker = ActivityTracker()
        followChatCompletions(
            listOf(
                ChatCompletionChunk.decode("""{"choices":[{"delta":{"content":null,"reasoning":"x"},"finish_reason":null}]}"""),
                ChatCompletionChunk.decode("""{"choices":[{"delta":{"content":"Hi"}}]}"""),
                ChatCompletionChunk.decode("""{"choices":[{"delta":{},"finish_reason":"stop"}]}"""),
            ).asFlow(),
            tracker,
        )
        assertEquals(Phase.DONE, tracker.current.phase)
        assertEquals(3, tracker.current.progress)
    }

    @Test
    fun aChunkStreamThatThrowsShowsTheError() {
        val tracker = ActivityTracker()
        val broken = flow {
            emit(ChatCompletionChunk.decode("""{"choices":[{"delta":{"content":"a"}}]}"""))
            throw IllegalStateException("socket closed")
        }
        assertFailsWith<IllegalStateException> { runBlocking { followChatCompletions(broken, tracker) } }
        assertEquals(Phase.ERROR, tracker.current.phase)
    }
}
