package io.github.farhad1618.dotmind

import io.github.farhad1618.dotmind.pattern.CELLS
import io.github.farhad1618.dotmind.pattern.PatternContext
import io.github.farhad1618.dotmind.pattern.Patterns
import kotlin.math.exp
import kotlin.math.max
import kotlin.math.min

public class DotRenderer(scene: Scene = Scene.BREATHE, color: Rgb = SceneColors[scene]) {
    private var current = RenderLayer(scene, color)
    private var previous = RenderLayer(scene, color)
    private var blending = false
    private var blend = 1.0
    private val currentValues = FloatArray(CELLS)
    private val previousValues = FloatArray(CELLS)
    private val context = PatternContext()
    private var energy = 0.3
    private var rate = 0.0
    private var hasLastProgress = false
    private var lastProgress = 0.0
    private var lastProgressAt = 0.0
    private var synthetic = 0.0
    private var clock = 0.0
    private var hasProgress = false

    public val scene: Scene get() = current.scene

    public val level: Double get() = energy

    public fun show(scene: Scene, color: Rgb = SceneColors[scene], instant: Boolean = false) {
        if (scene == current.scene) {
            current.color = color
            return
        }
        val origin = progressNow()
        if (instant) {
            blending = false
            blend = 1.0
        } else {
            val outgoing = current
            current = previous
            previous = outgoing
            blending = true
            blend = 0.0
        }
        current.reset(scene, color, origin)
    }

    public fun feed(progress: Int?) {
        if (progress == null) clearProgress() else feed(progress.toDouble())
    }

    public fun clearProgress() {
        hasProgress = false
    }

    public fun feed(progress: Double) {
        hasProgress = true
        if (!hasLastProgress || progress < lastProgress) {
            hasLastProgress = true
            lastProgress = progress
            lastProgressAt = clock
            rate = 0.0
            current.origin = min(current.origin, progress)
            return
        }
        if (progress == lastProgress) return
        val dt = max(1.0 / 60, clock - lastProgressAt)
        val instant = (progress - lastProgress) / dt
        rate = rate * 0.7 + instant * 0.3
        lastProgress = progress
        lastProgressAt = clock
    }

    public fun step(dt: Double) {
        clock += dt
        if (clock - lastProgressAt > STALL_SECONDS) rate *= exp(-dt * 3)
        val target = (0.3 + rate / 160).coerceIn(0.3, 1.5)
        energy += (target - energy) * (1 - exp(-dt * 6))
        val speed = 0.6 + 0.6 * energy
        current.time += dt * speed
        if (blending) previous.time += dt * speed
        synthetic += dt * SYNTHETIC_CHARS_PER_SECOND * speed
        if (blending) {
            blend = min(1.0, blend + dt / BLEND_SECONDS)
            if (blend >= 1) blending = false
        }
    }

    public fun sample(out: FloatArray = FloatArray(CELLS)): FloatArray {
        val now = progressNow()
        render(current, currentValues, now)
        if (!blending) {
            currentValues.copyInto(out)
            return out
        }
        render(previous, previousValues, now)
        val k = easedBlend()
        for (i in 0 until CELLS) out[i] = (previousValues[i] * (1 - k) + currentValues[i] * k).toFloat()
        return out
    }

    public fun color(): Rgb = if (blending) previous.color.mix(current.color, easedBlend()) else current.color

    public fun colorInto(out: DoubleArray): DoubleArray {
        val target = current.color
        if (!blending) {
            out[0] = target.red
            out[1] = target.green
            out[2] = target.blue
            return out
        }
        val from = previous.color
        val k = easedBlend()
        out[0] = from.red + (target.red - from.red) * k
        out[1] = from.green + (target.green - from.green) * k
        out[2] = from.blue + (target.blue - from.blue) * k
        return out
    }

    private fun render(layer: RenderLayer, values: FloatArray, now: Double) {
        context.energy = energy
        context.progress = max(0.0, now - layer.origin)
        Patterns[layer.scene].render(layer.time, values, context)
    }

    private fun progressNow(): Double = if (hasProgress) (if (hasLastProgress) lastProgress else 0.0) else synthetic

    private fun easedBlend(): Double = blend * blend * (3 - 2 * blend)

    private companion object {
        const val BLEND_SECONDS = 0.35
        const val STALL_SECONDS = 0.45
        const val SYNTHETIC_CHARS_PER_SECOND = 40.0
    }
}
