package io.github.farhad1618.dotmind

import io.github.farhad1618.dotmind.pattern.CELLS
import io.github.farhad1618.dotmind.pattern.PatternContext
import io.github.farhad1618.dotmind.pattern.Patterns
import kotlin.math.abs
import kotlin.test.Test
import kotlin.test.assertTrue

class PatternTest {
    @Test
    fun everyPatternFills64FiniteValuesInRange() {
        val out = FloatArray(CELLS)
        val context = PatternContext(0.8, 137.0)
        for (scene in Scene.entries) {
            for (t in doubleArrayOf(0.0, 0.3, 1.7, 12.5, 400.0)) {
                Patterns[scene].render(t, out, context)
                for (v in out) assertTrue(v.isFinite() && v >= 0f && v <= 1.6f, "${scene.id}@$t: $v")
            }
        }
    }

    @Test
    fun theWritingSceneLightsMoreDotsAsTextArrives() {
        fun lit(progress: Double): Int {
            val out = FloatArray(CELLS)
            Patterns[Scene.TYPE].render(0.1, out, PatternContext(0.5, progress))
            return out.count { it > 0.3f }
        }
        assertTrue(lit(0.0) < lit(40.0))
        assertTrue(lit(40.0) < lit(120.0))
    }

    @Test
    fun fasterTextMakesTheRendererLivelier() {
        val renderer = DotRenderer(Scene.TYPE)
        var progress = 0
        renderer.feed(progress)
        repeat(60) {
            renderer.step(1.0 / 60)
            progress += 1
            renderer.feed(progress)
        }
        val slow = renderer.level
        repeat(60) {
            renderer.step(1.0 / 60)
            progress += 8
            renderer.feed(progress)
        }
        assertTrue(renderer.level > slow, "${renderer.level} > $slow")
        repeat(180) { renderer.step(1.0 / 60) }
        assertTrue(renderer.level < 0.5, "calms down when text stops: ${renderer.level}")
    }

    @Test
    fun switchingScenesCrossFadesInsteadOfCutting() {
        val renderer = DotRenderer(Scene.CHECK)
        renderer.step(2.0)
        val before = renderer.sample().copyOf()
        renderer.show(Scene.CROSS)
        renderer.step(0.1)
        val mid = renderer.sample()
        val target = FloatArray(CELLS)
        Patterns[Scene.CROSS].render(0.1 * (0.6 + 0.6 * renderer.level), target, PatternContext(renderer.level, 0.0))
        val differsFromBoth = mid.indices.any { abs(mid[it] - before[it]) > 0.05f && abs(mid[it] - target[it]) > 0.05f }
        assertTrue(differsFromBoth)
    }

    @Test
    fun theColourBlendsWithTheScene() {
        val renderer = DotRenderer(Scene.CHECK)
        renderer.show(Scene.CROSS)
        renderer.step(0.35 / 2)
        val mixed = renderer.colorInto(DoubleArray(3))
        val from = SceneColors[Scene.CHECK]
        val to = SceneColors[Scene.CROSS]
        assertTrue(mixed[0] > from.red && mixed[0] < to.red)
        renderer.step(1.0)
        assertTrue(renderer.color() == to)
    }

    @Test
    fun eachSceneCountsProgressFromWhenItWasShown() {
        val renderer = DotRenderer(Scene.COMET)
        renderer.feed(400)
        renderer.show(Scene.TYPE, instant = true)
        val out = renderer.sample()
        val fresh = FloatArray(CELLS)
        Patterns[Scene.TYPE].render(0.0, fresh, PatternContext(0.3, 0.0))
        assertTrue(out.contentEquals(fresh))
    }
}
