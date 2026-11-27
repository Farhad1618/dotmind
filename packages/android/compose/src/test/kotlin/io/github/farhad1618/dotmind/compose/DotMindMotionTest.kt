package io.github.farhad1618.dotmind.compose

import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.ui.Modifier
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.unit.dp
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleOwner
import androidx.lifecycle.LifecycleRegistry
import androidx.lifecycle.compose.LocalLifecycleOwner
import io.github.farhad1618.dotmind.Activity
import io.github.farhad1618.dotmind.Phase
import io.github.farhad1618.dotmind.Scene
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class DotMindMotionTest {
    @get:Rule
    val rule = createComposeRule()

    private class Owner : LifecycleOwner {
        val registry = LifecycleRegistry(this)
        override val lifecycle: Lifecycle get() = registry
    }

    private fun show(host: IndicatorHost, owner: Owner) {
        rule.mainClock.autoAdvance = false
        rule.setContent {
            CompositionLocalProvider(LocalLifecycleOwner provides owner) {
                DotMindContent(host, DotMindVariant.Pill, 28.dp, DotMindDefaults.Colors, DotMindDefaults.LabelStyle, DotMindDefaults.ShimmerDuration, Modifier)
            }
        }
    }

    private fun options() = DotMindOptions(null, true, emptyMap(), emptyMap(), null)

    @Test
    fun framesRunWhileStartedAndPauseWhenBackgrounded() {
        val owner = Owner()
        val host = IndicatorHost()
        rule.runOnUiThread {
            owner.registry.currentState = Lifecycle.State.RESUMED
            host.present(Activity(Phase.THINKING), options(), still = false)
        }
        show(host, owner)
        rule.mainClock.advanceTimeBy(500)
        val running = host.frame
        assertTrue("frames advanced: $running", running > 10)
        rule.runOnUiThread { owner.registry.currentState = Lifecycle.State.CREATED }
        rule.mainClock.advanceTimeBy(100)
        val paused = host.frame
        rule.mainClock.advanceTimeBy(1_000)
        assertEquals(paused, host.frame)
        rule.runOnUiThread { owner.registry.currentState = Lifecycle.State.RESUMED }
        rule.mainClock.advanceTimeBy(500)
        assertTrue(host.frame > paused)
    }

    @Test
    fun reducedMotionHoldsAStillFramePerState() {
        val owner = Owner()
        val host = IndicatorHost()
        rule.runOnUiThread {
            owner.registry.currentState = Lifecycle.State.RESUMED
            host.present(Activity(Phase.DONE), options(), still = true)
        }
        show(host, owner)
        rule.mainClock.advanceTimeBy(100)
        val held = host.frame
        rule.mainClock.advanceTimeBy(2_000)
        assertEquals(held, host.frame)
        assertEquals(7, host.renderer.sample().count { it > 0.5f })
        rule.runOnUiThread { host.present(Activity(Phase.ERROR), options(), still = true) }
        rule.mainClock.advanceTimeBy(100)
        assertEquals(held + 1, host.frame)
        assertEquals(Scene.CROSS, host.renderer.scene)
    }
}
