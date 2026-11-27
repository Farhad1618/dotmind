package io.github.farhad1618.dotmind

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class IndicatorDriverTest {
    @Test
    fun theFirstStateIsShownWithoutAFade() {
        val driver = IndicatorDriver()
        assertTrue(driver.present(Activity(Phase.THINKING)))
        assertEquals(Scene.COMET, driver.scene)
        assertEquals(SceneColors[Scene.COMET], driver.renderer.color())
    }

    @Test
    fun anUnchangedStateIsIgnored() {
        val driver = IndicatorDriver()
        driver.present(Activity(Phase.WRITING, progress = 4))
        assertFalse(driver.present(Activity(Phase.WRITING, progress = 4)))
        assertTrue(driver.present(Activity(Phase.WRITING, progress = 8)))
    }

    @Test
    fun overridesAndPalettesApply() {
        val driver = IndicatorDriver()
        val ember = Rgb(1, 2, 3)
        driver.present(Activity(Phase.IDLE), sceneOverride = Scene.EMBER, palette = mapOf(Scene.EMBER to ember))
        assertEquals(Scene.EMBER, driver.scene)
        assertEquals(ember, driver.renderer.color())
    }

    @Test
    fun aStillFrameSettlesTheScene() {
        val driver = IndicatorDriver()
        driver.present(Activity(Phase.DONE), still = true)
        val settled = driver.renderer.sample()
        assertTrue(settled.count { it > 0.5f } == 7)
    }

    @Test
    fun hiddenIndicatorsSwitchWithoutAFade() {
        val driver = IndicatorDriver()
        driver.present(Activity(Phase.THINKING))
        driver.present(Activity(Phase.DONE), visible = false)
        assertEquals(SceneColors[Scene.CHECK], driver.renderer.color())
    }

    @Test
    fun framesAreCapped() {
        val a = IndicatorDriver()
        val b = IndicatorDriver()
        a.advance(5.0)
        b.advance(IndicatorDriver.MAX_FRAME_SECONDS)
        assertEquals(b.renderer.level, a.renderer.level)
    }
}
