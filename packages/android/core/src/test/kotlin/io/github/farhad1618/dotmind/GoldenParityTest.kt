package io.github.farhad1618.dotmind

import io.github.farhad1618.dotmind.pattern.CELLS
import io.github.farhad1618.dotmind.pattern.PatternContext
import io.github.farhad1618.dotmind.pattern.Patterns
import kotlinx.serialization.json.jsonObject
import kotlin.math.abs
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue
import kotlin.test.fail

class GoldenParityTest {
    private val tolerance = GoldenFixture.tolerance

    @Test
    fun everyFrameMatchesTheReference() {
        val frames = GoldenFixture.list("frames")
        assertEquals(Scene.entries.size * 8, frames.size)
        val out = FloatArray(CELLS)
        for (frame in frames) {
            val scene = Scene.fromId(GoldenFixture.string(frame, "scene")!!)
            val t = GoldenFixture.double(frame, "t")
            val context = PatternContext(GoldenFixture.double(frame, "energy"), GoldenFixture.double(frame, "progress"))
            Patterns[scene].render(t, out, context)
            assertClose(GoldenFixture.values(frame), out, "${scene.id} t=$t progress=${context.progress}")
        }
    }

    @Test
    fun everyToolNameMapsToTheReferenceKind() {
        for (entry in GoldenFixture.list("tools")) {
            val name = GoldenFixture.string(entry, "name")!!
            assertEquals(ToolKind.fromId(GoldenFixture.string(entry, "kind")!!), classifyTool(name), name)
        }
    }

    @Test
    fun everyActivityPicksTheReferenceSceneAndLabel() {
        for (entry in GoldenFixture.list("scenes")) {
            val raw = entry.getValue("activity").jsonObject
            val activity = Activity(
                phase = Phase.fromId(GoldenFixture.string(raw, "phase")!!),
                tool = GoldenFixture.string(raw, "tool"),
                kind = GoldenFixture.string(raw, "kind")?.let(ToolKind::fromId),
            )
            assertEquals(Scene.fromId(GoldenFixture.string(entry, "scene")!!), sceneFor(activity), activity.toString())
            assertEquals(GoldenFixture.string(entry, "label"), labelFor(activity), activity.toString())
        }
    }

    @Test
    fun energyAndFramesFollowTheReferenceClock() {
        val samples = GoldenFixture.list("energy")
        val renderer = DotRenderer(Scene.TYPE)
        val out = FloatArray(CELLS)
        var progress = 0
        var next = 0
        renderer.feed(progress)
        for (i in 0 until 240) {
            renderer.step(1.0 / 60)
            if (i < 120) {
                progress += if (i < 60) 1 else 8
                renderer.feed(progress)
            }
            if (i % 20 == 19) {
                val expected = samples[next++]
                assertEquals(GoldenFixture.int(expected, "frame"), i + 1)
                val energy = GoldenFixture.double(expected, "energy")
                assertTrue(abs(energy - renderer.level) <= tolerance, "energy at ${i + 1}: ${renderer.level} vs $energy")
                assertClose(GoldenFixture.values(expected), renderer.sample(out), "energy frame ${i + 1}")
            }
        }
        assertEquals(samples.size, next)
    }

    private fun assertClose(expected: DoubleArray, actual: FloatArray, where: String) {
        assertEquals(CELLS, expected.size, where)
        for (i in 0 until CELLS) {
            if (abs(expected[i] - actual[i]) > tolerance) fail("$where cell $i: expected ${expected[i]} got ${actual[i]}")
        }
    }
}
