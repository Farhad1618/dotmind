package io.github.farhad1618.dotmind

import kotlin.math.min

public class IndicatorDriver(public val renderer: DotRenderer = DotRenderer()) {
    private var presented = false
    private var lastActivity: Activity? = null
    private var lastScene: Scene? = null
    private var lastColor: Rgb? = null
    private var lastStill = false

    public val scene: Scene get() = renderer.scene

    public fun present(
        activity: Activity,
        sceneOverride: Scene? = null,
        palette: Map<Scene, Rgb> = emptyMap(),
        visible: Boolean = true,
        still: Boolean = false,
        look: Look = Look.CLASSIC,
        scenes: Map<SceneKey, Scene> = emptyMap(),
    ): Boolean {
        val scene = sceneOverride ?: sceneFor(activity, look, scenes)
        val color = palette[scene] ?: SceneColors[scene]
        if (presented && activity == lastActivity && scene == lastScene && color == lastColor && still == lastStill) {
            return false
        }
        renderer.feed(activity.progress)
        renderer.show(scene, color, instant = !visible || !presented)
        if (still) {
            renderer.step(STILL_SETTLE)
            renderer.step(STILL_HOLD)
        }
        presented = true
        lastActivity = activity
        lastScene = scene
        lastColor = color
        lastStill = still
        return true
    }

    public fun advance(dt: Double) {
        renderer.step(min(MAX_FRAME_SECONDS, dt.coerceAtLeast(0.0)))
    }

    public fun invalidate() {
        presented = false
    }

    public companion object {
        public const val MAX_FRAME_SECONDS: Double = 0.05
        private const val STILL_SETTLE = 1.2
        private const val STILL_HOLD = 0.5
    }
}
