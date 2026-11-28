package io.github.farhad1618.dotmind

import io.github.farhad1618.dotmind.pattern.CELLS
import io.github.farhad1618.dotmind.pattern.GRID
import io.github.farhad1618.dotmind.pattern.PatternContext
import io.github.farhad1618.dotmind.pattern.Patterns
import kotlin.test.Test
import kotlin.test.assertContentEquals
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class LooksTest {
    private val newScenes = listOf(
        Scene.NEURAL, Scene.MAGNIFIER, Scene.GLYPH, Scene.SORT, Scene.ROCKET, Scene.VERIFIED,
        Scene.BUG, Scene.BLOCKS, Scene.SCAN,
    )

    private fun tool(kind: ToolKind) = Activity(Phase.TOOL, kind = kind)

    @Test
    fun newToolKindsAreRecognisedWithoutChangingOlderOnes() {
        val cases = mapOf(
            "translate_text" to ToolKind.TRANSLATE,
            "localizeStrings" to ToolKind.TRANSLATE,
            "i18n_sync" to ToolKind.TRANSLATE,
            "set_locale" to ToolKind.TRANSLATE,
            "deploy_service" to ToolKind.DEPLOY,
            "kubectl_apply" to ToolKind.DEPLOY,
            "helm_upgrade" to ToolKind.DEPLOY,
            "publish_release" to ToolKind.DEPLOY,
            "rollout_canary" to ToolKind.DEPLOY,
            "debugger_step" to ToolKind.DEBUG,
            "set_breakpoint" to ToolKind.DEBUG,
            "parse_traceback" to ToolKind.DEBUG,
            "inspect_element" to ToolKind.DEBUG,
            "inspect_page" to ToolKind.BROWSE,
            "i18n_lookup" to ToolKind.SEARCH,
            "run_deploy_script" to ToolKind.CODE,
            "get_weather" to ToolKind.GENERIC,
        )
        for ((name, kind) in cases) assertEquals(kind, classifyTool(name), name)
    }

    @Test
    fun newKindsHaveDefaultLabels() {
        assertEquals("Translating", labelFor(tool(ToolKind.TRANSLATE)))
        assertEquals("Deploying", labelFor(tool(ToolKind.DEPLOY)))
        assertEquals("Debugging", labelFor(tool(ToolKind.DEBUG)))
    }

    @Test
    fun everyNewPatternStaysInRangeAndAnimates() {
        val out = FloatArray(CELLS)
        for (scene in newScenes) {
            val seen = HashSet<String>()
            var lit = 0
            for (t in doubleArrayOf(0.0, 0.3, 0.5, 1.7, 2.9, 4.1, 12.5, 400.0)) {
                for (progress in doubleArrayOf(0.0, 137.0)) {
                    Patterns[scene].render(t, out, PatternContext(0.8, progress))
                    for (v in out) assertTrue(v.isFinite() && v >= 0f && v <= 1.5f, "${scene.id}@$t: $v")
                    if (out.any { it > 0.5f }) lit++
                    seen += out.joinToString(",") { "%.2f".format(it) }
                }
            }
            assertTrue(seen.size > 3, "${scene.id} animates")
            assertTrue(lit >= 12, "${scene.id} lights something most of the time: $lit")
        }
    }

    @Test
    fun newPatternsAreDeterministic() {
        val a = FloatArray(CELLS)
        val b = FloatArray(CELLS)
        for (scene in newScenes) {
            Patterns[scene].render(7.77, a, PatternContext(0.8, 0.0))
            Patterns[scene].render(7.77, b, PatternContext(0.8, 0.0))
            assertContentEquals(a, b, scene.id)
        }
    }

    @Test
    fun theSortSceneEndsOnAnAscendingStaircase() {
        val out = FloatArray(CELLS)
        Patterns[Scene.SORT].render(0.16 * 38 + 0.05, out, PatternContext(0.8, 0.0))
        val heights = (0 until GRID).map { x -> (0 until GRID).count { y -> out[y * GRID + x] > 0f } }
        assertEquals(listOf(1, 2, 3, 4, 5, 6, 7, 8), heights)
    }

    @Test
    fun sceneKeyNamesTheState() {
        assertEquals("thinking", sceneKey(Activity(Phase.THINKING)).id)
        assertEquals("tool:generic", sceneKey(Activity(Phase.TOOL)).id)
        assertEquals("tool:debug", sceneKey(tool(ToolKind.DEBUG)).id)
    }

    @Test
    fun looksMapStatesToScenes() {
        assertEquals(Scene.COMET, sceneFor(Activity(Phase.THINKING)))
        assertEquals(Scene.GLYPH, sceneFor(tool(ToolKind.TRANSLATE)))
        assertEquals(Scene.ROCKET, sceneFor(tool(ToolKind.DEPLOY)))
        assertEquals(Scene.BUG, sceneFor(tool(ToolKind.DEBUG)))

        assertEquals(Scene.NEURAL, sceneFor(Activity(Phase.THINKING), Look.ICONS))
        assertEquals(Scene.MAGNIFIER, sceneFor(tool(ToolKind.SEARCH), Look.ICONS))
        assertEquals(Scene.GLYPH, sceneFor(tool(ToolKind.TRANSLATE), Look.ICONS))
        assertEquals(Scene.SORT, sceneFor(tool(ToolKind.COMPUTE), Look.ICONS))
        assertEquals(Scene.ROCKET, sceneFor(tool(ToolKind.DEPLOY), Look.ICONS))
        assertEquals(Scene.VERIFIED, sceneFor(Activity(Phase.DONE), Look.ICONS))
        assertEquals(Scene.TYPE, sceneFor(Activity(Phase.WRITING), Look.ICONS))
        assertEquals(Scene.STACK, sceneFor(tool(ToolKind.DATABASE), Look.ICONS))

        assertEquals(Scene.BUG, sceneFor(tool(ToolKind.DEBUG), Look.PIXEL))
        assertEquals(Scene.BLOCKS, sceneFor(tool(ToolKind.CODE), Look.PIXEL))
        assertEquals(Scene.SCAN, sceneFor(tool(ToolKind.SEARCH), Look.PIXEL))
        assertEquals(Scene.COMET, sceneFor(Activity(Phase.THINKING), Look.PIXEL))
    }

    @Test
    fun everyLookCoversEveryState() {
        assertEquals(SceneKey.entries.toSet(), CLASSIC_SCENES.keys)
        for (look in Look.entries) {
            for (key in SceneKey.entries) {
                val activity = if (key.id.startsWith("tool:")) {
                    tool(ToolKind.fromId(key.id.removePrefix("tool:")))
                } else {
                    Activity(Phase.fromId(key.id))
                }
                assertEquals(key, sceneKey(activity))
                sceneFor(activity, look)
            }
        }
        assertEquals(DotShape.SQUARE, Look.PIXEL.definition.shape)
        assertEquals(DotShape.DOT, Look.ICONS.definition.shape)
        assertTrue(Look.ICONS.definition.aura)
        assertTrue(!Look.CLASSIC.definition.aura)
        assertTrue(!Look.PIXEL.definition.aura)
    }

    @Test
    fun sceneOverridesBeatTheLookTable() {
        assertEquals(Scene.EMBER, sceneFor(Activity(Phase.THINKING), Look.ICONS, mapOf(SceneKey.THINKING to Scene.EMBER)))
        assertEquals(Scene.MAGNIFIER, sceneFor(tool(ToolKind.SEARCH), Look.PIXEL, mapOf(SceneKey.TOOL_SEARCH to Scene.MAGNIFIER)))
        assertEquals(Scene.SORT, sceneFor(tool(ToolKind.FILE), Look.CLASSIC, mapOf(SceneKey.TOOL_FILE to Scene.SORT)))
        assertEquals(Scene.SCAN, sceneFor(tool(ToolKind.SEARCH), Look.PIXEL, mapOf(SceneKey.THINKING to Scene.EMBER)))
        assertEquals(Look.CLASSIC, Look.fromId("nope"))
        assertEquals(Scene.COMET, sceneFor(Activity(Phase.THINKING), Look.fromId("nope")))
    }

    @Test
    fun shapeGeometryMatchesTheSpec() {
        assertEquals(0.68, DotShape.DOT.size)
        assertEquals(0.14, DotShape.DOT.baseAlpha)
        assertEquals(0.24, DotShape.DOT.wellCorner)
        assertEquals(0.8, DotShape.SQUARE.size)
        assertEquals(0.22, DotShape.SQUARE.corner)
        assertEquals(0.2, DotShape.SQUARE.baseAlpha)
        assertEquals(0.14, DotShape.SQUARE.wellCorner)
        assertEquals(DotShape.DOT, DotShape.fromId("hexagon"))
        val side = 56.0
        assertEquals(DotGeometry.radius(side), DotGeometry.half(side, DotShape.DOT), 1e-12)
        val half = DotGeometry.half(side, DotShape.SQUARE)
        assertEquals(DotGeometry.step(side) * 0.4, half, 1e-12)
        assertEquals(half * 2 * 0.22, DotGeometry.cornerRadius(half, DotShape.SQUARE), 1e-12)
    }

    @Test
    fun theDriverFollowsTheLookAndItsOverrides() {
        val driver = IndicatorDriver()
        driver.present(Activity(Phase.THINKING), look = Look.ICONS)
        assertEquals(Scene.NEURAL, driver.scene)
        assertEquals(SceneColors[Scene.NEURAL], driver.renderer.color())
        driver.present(Activity(Phase.THINKING), look = Look.ICONS, scenes = mapOf(SceneKey.THINKING to Scene.ORBIT))
        assertEquals(Scene.ORBIT, driver.scene)
        driver.present(Activity(Phase.THINKING), sceneOverride = Scene.PULSE, look = Look.ICONS, scenes = mapOf(SceneKey.THINKING to Scene.ORBIT))
        assertEquals(Scene.PULSE, driver.scene)
    }
}
