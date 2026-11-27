package io.github.farhad1618.dotmind

import io.github.farhad1618.dotmind.pattern.CELLS
import com.sun.management.ThreadMXBean
import java.lang.management.ManagementFactory
import kotlin.test.Test
import kotlin.test.assertTrue

class AllocationTest {
    @Test
    fun framesDoNotAllocate() {
        val bean = ManagementFactory.getThreadMXBean() as ThreadMXBean
        val driver = IndicatorDriver()
        val values = FloatArray(CELLS)
        val color = DoubleArray(3)
        val scenes = Scene.entries
        driver.present(Activity(Phase.WRITING, progress = 10))
        repeat(2_000) { frame(driver, values, color, scenes, it) }
        val thread = Thread.currentThread().id
        val before = bean.getThreadAllocatedBytes(thread)
        repeat(20_000) { frame(driver, values, color, scenes, it) }
        val allocated = bean.getThreadAllocatedBytes(thread) - before
        assertTrue(allocated < 64_000, "allocated $allocated bytes over 20000 frames")
    }

    private fun frame(driver: IndicatorDriver, values: FloatArray, color: DoubleArray, scenes: List<Scene>, i: Int) {
        if (i % 500 == 0) driver.renderer.show(scenes[(i / 500) % scenes.size])
        driver.renderer.feed(i.toDouble())
        driver.advance(1.0 / 60)
        driver.renderer.sample(values)
        driver.renderer.colorInto(color)
    }
}
