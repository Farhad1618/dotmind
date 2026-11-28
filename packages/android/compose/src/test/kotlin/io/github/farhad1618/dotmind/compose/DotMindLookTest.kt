package io.github.farhad1618.dotmind.compose

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.semantics.LiveRegionMode
import androidx.compose.ui.semantics.SemanticsProperties
import androidx.compose.ui.test.SemanticsMatcher
import androidx.compose.ui.test.assert
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithContentDescription
import io.github.farhad1618.dotmind.Activity
import io.github.farhad1618.dotmind.DotShape
import io.github.farhad1618.dotmind.Look
import io.github.farhad1618.dotmind.Phase
import io.github.farhad1618.dotmind.Scene
import io.github.farhad1618.dotmind.SceneKey
import io.github.farhad1618.dotmind.ToolKind
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class DotMindLookTest {
    @get:Rule
    val rule = createComposeRule()

    private val polite = SemanticsMatcher.expectValue(SemanticsProperties.LiveRegion, LiveRegionMode.Polite)

    private fun options(look: Look, shape: DotShape? = null, aura: Boolean? = null, scenes: Map<SceneKey, Scene> = emptyMap()) =
        DotMindOptions(
            label = null,
            showLabel = true,
            labels = emptyMap(),
            palette = emptyMap(),
            scene = null,
            look = look,
            scenes = scenes,
            shape = shape ?: look.definition.shape,
            aura = aura ?: look.definition.aura,
        )

    @Test
    fun aLookPicksItsScenesShapeAndAura() {
        val host = IndicatorHost()
        host.present(Activity(Phase.TOOL, tool = "web_search", kind = ToolKind.SEARCH), options(Look.PIXEL), still = false)
        assertEquals(Scene.SCAN, host.renderer.scene)
        assertEquals(DotShape.SQUARE, host.shape)
        assertFalse(host.aura)
        host.present(Activity(Phase.THINKING), options(Look.ICONS), still = false)
        assertEquals(Scene.NEURAL, host.renderer.scene)
        assertEquals(DotShape.DOT, host.shape)
        assertTrue(host.aura)
    }

    @Test
    fun explicitOptionsBeatTheLook() {
        val host = IndicatorHost()
        host.present(
            Activity(Phase.THINKING),
            options(Look.ICONS, shape = DotShape.SQUARE, aura = false, scenes = mapOf(SceneKey.THINKING to Scene.ORBIT)),
            still = false,
        )
        assertEquals(Scene.ORBIT, host.renderer.scene)
        assertEquals(DotShape.SQUARE, host.shape)
        assertFalse(host.aura)
    }

    @Test
    fun switchingTheLookReskinsALiveIndicator() {
        var look by mutableStateOf(Look.CLASSIC)
        rule.mainClock.autoAdvance = false
        rule.setContent { DotMind(Phase.TOOL, look = look, variant = DotMindVariant.Pill) }
        rule.mainClock.advanceTimeBy(100)
        rule.onNodeWithContentDescription("Using a tool").assert(polite)
        rule.runOnIdle { look = Look.PIXEL }
        rule.mainClock.advanceTimeBy(500)
        rule.onNodeWithContentDescription("Using a tool").assert(polite)
    }

    @Test
    fun aBareIndicatorWithAnAuraAndSquareCellsComposes() {
        rule.mainClock.autoAdvance = false
        rule.setContent {
            DotMind(
                Activity(Phase.TOOL, tool = "debugger_step", kind = ToolKind.DEBUG),
                variant = DotMindVariant.Bare,
                look = Look.PIXEL,
                aura = true,
                showLabel = false,
            )
        }
        rule.mainClock.advanceTimeBy(500)
        rule.onNodeWithContentDescription("Debugging").assert(polite)
    }

    @Test
    fun theAuraFalloffFollowsAGaussian() {
        assertEquals(0.5, normalCdf(0.0), 1e-6)
        assertEquals(0.8413, normalCdf(1.0), 1e-3)
        assertEquals(0.1587, normalCdf(-1.0), 1e-3)
        assertTrue(normalCdf(4.0) > 0.9999)
    }
}
