package io.github.farhad1618.dotmind.compose

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.semantics.LiveRegionMode
import androidx.compose.ui.semantics.SemanticsProperties
import androidx.compose.ui.test.SemanticsMatcher
import androidx.compose.ui.test.assert
import androidx.compose.ui.test.assertCountEquals
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onAllNodesWithText
import androidx.compose.ui.test.onChildren
import androidx.compose.ui.test.onNodeWithContentDescription
import io.github.farhad1618.dotmind.Activity
import io.github.farhad1618.dotmind.ActivityTracker
import io.github.farhad1618.dotmind.AgentEvent
import io.github.farhad1618.dotmind.LabelKey
import io.github.farhad1618.dotmind.Phase
import io.github.farhad1618.dotmind.ToolKind
import org.junit.Before
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class DotMindSemanticsTest {
    @get:Rule
    val rule = createComposeRule()

    private val polite = SemanticsMatcher.expectValue(SemanticsProperties.LiveRegion, LiveRegionMode.Polite)

    private fun settle() {
        rule.mainClock.advanceTimeBy(100)
    }

    @Before
    fun manualClock() {
        rule.mainClock.autoAdvance = false
    }

    @Test
    fun theLabelIsAPoliteLiveRegionAndTheDotsAreHidden() {
        rule.setContent { DotMind(Activity(Phase.TOOL, tool = "web_search", kind = ToolKind.SEARCH)) }
        settle()
        rule.onNodeWithContentDescription("Searching").assert(polite)
        rule.onAllNodesWithText("Searching").assertCountEquals(0)
        rule.onNodeWithContentDescription("Searching").onChildren().assertCountEquals(0)
    }

    @Test
    fun aHiddenLabelIsStillAnnounced() {
        rule.setContent { DotMind(Phase.THINKING, showLabel = false, variant = DotMindVariant.Bare) }
        settle()
        rule.onNodeWithContentDescription("Thinking").assert(polite)
    }

    @Test
    fun customLabelsReplaceTheDefaults() {
        rule.setContent { DotMind(Phase.WRITING, labels = mapOf(LabelKey.WRITING to "Escribiendo")) }
        settle()
        rule.onNodeWithContentDescription("Escribiendo").assert(polite)
    }

    @Test
    fun aNewActivityIsAnnouncedOnTheNextFrame() {
        var phase by mutableStateOf(Phase.THINKING)
        rule.setContent { DotMind(phase) }
        settle()
        rule.onNodeWithContentDescription("Thinking").assert(polite)
        rule.runOnIdle { phase = Phase.WRITING }
        rule.mainClock.advanceTimeByFrame()
        rule.onNodeWithContentDescription("Writing").assert(polite)
    }

    @Test
    fun aTrackerDrivesTheAnnouncement() {
        val tracker = ActivityTracker()
        rule.setContent { DotMind(tracker) }
        settle()
        rule.onNodeWithContentDescription("Ready").assert(polite)
        rule.runOnIdle { tracker.pushAll(listOf(AgentEvent.Start, AgentEvent.Tool("run_sql", "q"))) }
        settle()
        rule.onNodeWithContentDescription("Querying data").assert(polite)
        rule.runOnIdle { tracker.push(AgentEvent.Finish()) }
        settle()
        rule.onNodeWithContentDescription("Done").assert(polite)
    }
}
