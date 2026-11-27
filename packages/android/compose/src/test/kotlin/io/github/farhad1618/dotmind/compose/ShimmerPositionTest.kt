package io.github.farhad1618.dotmind.compose

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Test

class ShimmerPositionTest {
    @Test
    fun staticPhasesStayPlainUnderReducedMotion() {
        var read = false
        assertEquals(1f, shimmerPosition(animated = false, still = true, seconds = 2.4) { read = true; 0.0 })
        assertFalse(read)
    }

    @Test
    fun staticPhasesNeverReadTheClock() {
        var read = false
        assertEquals(1f, shimmerPosition(animated = false, still = false, seconds = 2.4) { read = true; 0.0 })
        assertFalse(read)
    }

    @Test
    fun animatedPhasesHoldTheMiddleUnderReducedMotion() {
        var read = false
        assertEquals(0.5f, shimmerPosition(animated = true, still = true, seconds = 2.4) { read = true; 0.0 })
        assertFalse(read)
    }

    @Test
    fun durationSetsTheSweepSpeed() {
        assertEquals(1.3f, shimmerPosition(animated = true, still = false, seconds = 2.4) { 0.0 }, 1e-6f)
        assertEquals(0.5f, shimmerPosition(animated = true, still = false, seconds = 2.4) { 1.2 }, 1e-6f)
        assertEquals(0.5f, shimmerPosition(animated = true, still = false, seconds = 1.0) { 0.5 }, 1e-6f)
        assertEquals(1.3f, shimmerPosition(animated = true, still = false, seconds = 1.0) { 1.0 }, 1e-6f)
    }
}
