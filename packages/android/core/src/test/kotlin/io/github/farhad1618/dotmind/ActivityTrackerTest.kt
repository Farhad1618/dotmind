package io.github.farhad1618.dotmind

import kotlinx.coroutines.flow.first
import kotlinx.coroutines.runBlocking
import kotlin.test.Test
import kotlin.test.assertEquals

class ActivityTrackerTest {
    @Test
    fun theTrackerFollowsAToolUsingTurn() {
        val tracker = ActivityTracker()
        val phases = mutableListOf<String>()
        tracker.subscribe { a -> phases.add(if (a.phase == Phase.TOOL) "tool:${a.kind?.id}" else a.phase.id) }
        tracker.pushAll(
            listOf(
                AgentEvent.Start,
                AgentEvent.Thinking(120),
                AgentEvent.Tool("web_search", "a"),
                AgentEvent.ToolResult("a"),
                AgentEvent.Text(40),
                AgentEvent.Text(40),
                AgentEvent.Finish(),
            ),
        )
        assertEquals(listOf("idle", "thinking", "tool:search", "writing", "done"), phases.distinct())
        assertEquals(200, tracker.current.progress)
    }

    @Test
    fun aTurnThatStopsToRunAClientToolStaysOnThatTool() {
        val tracker = ActivityTracker()
        tracker.pushAll(listOf(AgentEvent.Start, AgentEvent.Tool("run_sql", "x"), AgentEvent.Finish(pendingTools = true)))
        assertEquals(Phase.TOOL, tracker.current.phase)
        assertEquals(ToolKind.DATABASE, tracker.current.kind)
    }

    @Test
    fun overridesClassifyByExactName() {
        val tracker = ActivityTracker(mapOf("lookup_customer" to ToolKind.DATABASE))
        tracker.push(AgentEvent.Tool("lookup_customer", "1"))
        assertEquals(ToolKind.DATABASE, tracker.current.kind)
        tracker.push(AgentEvent.ToolResult("1"))
        assertEquals(Phase.THINKING, tracker.current.phase)
    }

    @Test
    fun toolInputKeepsTheToolAndCountsProgress() {
        val tracker = ActivityTracker()
        tracker.pushAll(listOf(AgentEvent.Start, AgentEvent.Tool("bash", "t"), AgentEvent.ToolInput(12)))
        assertEquals(Activity(Phase.TOOL, tool = "bash", kind = ToolKind.CODE, progress = 12), tracker.current)
    }

    @Test
    fun approvalWaitsAndErrorFails() {
        val tracker = ActivityTracker()
        tracker.push(AgentEvent.Approval("deploy_config", "ap1"))
        assertEquals(Phase.WAITING, tracker.current.phase)
        assertEquals("deploy_config", tracker.current.tool)
        tracker.push(AgentEvent.Error("boom"))
        assertEquals(Phase.ERROR, tracker.current.phase)
    }

    @Test
    fun repeatedStatesDoNotNotifyAndResetReturnsToIdle() {
        val tracker = ActivityTracker()
        var calls = 0
        val unsubscribe = tracker.subscribe { calls++ }
        tracker.push(AgentEvent.Start)
        tracker.push(AgentEvent.Thinking())
        assertEquals(2, calls)
        tracker.reset()
        assertEquals(Activity(Phase.IDLE, progress = 0), tracker.current)
        unsubscribe()
        tracker.push(AgentEvent.Start)
        assertEquals(3, calls)
    }

    @Test
    fun aSubscriberRacingPushesEndsOnTheLatestActivity() {
        repeat(200) {
            val tracker = ActivityTracker()
            val start = java.util.concurrent.CountDownLatch(1)
            val pusher = Thread {
                start.await()
                repeat(50) { tracker.push(AgentEvent.Thinking(chars = 1)) }
            }
            pusher.start()
            var seen: Activity? = null
            start.countDown()
            tracker.subscribe { seen = it }
            pusher.join()
            assertEquals(tracker.current, seen)
        }
    }

    @Test
    fun theStateFlowCarriesTheLatestActivity() = runBlocking {
        val tracker = ActivityTracker()
        tracker.pushAll(listOf(AgentEvent.Start, AgentEvent.Text(5)))
        assertEquals(Activity(Phase.WRITING, progress = 5), tracker.activity.first())
    }
}
