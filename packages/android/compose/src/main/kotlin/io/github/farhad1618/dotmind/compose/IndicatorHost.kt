package io.github.farhad1618.dotmind.compose

import androidx.compose.runtime.Stable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableDoubleStateOf
import androidx.compose.runtime.mutableLongStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.runtime.snapshots.Snapshot
import io.github.farhad1618.dotmind.Activity
import io.github.farhad1618.dotmind.DotGeometry
import io.github.farhad1618.dotmind.DotRenderer
import io.github.farhad1618.dotmind.IndicatorDriver
import io.github.farhad1618.dotmind.Phase
import io.github.farhad1618.dotmind.Rgb
import io.github.farhad1618.dotmind.SceneColors
import io.github.farhad1618.dotmind.pattern.CELLS

@Stable
internal class IndicatorHost(private val driver: IndicatorDriver = IndicatorDriver()) {
    val renderer: DotRenderer get() = driver.renderer
    val values: FloatArray = FloatArray(CELLS)
    val color: DoubleArray = DoubleArray(3)

    var frame: Long by mutableLongStateOf(0L)
        private set
    var shimmerClock: Double by mutableDoubleStateOf(0.0)
        private set
    var visible: Boolean by mutableStateOf(true)
    var still: Boolean by mutableStateOf(false)
        private set
    var label: String by mutableStateOf("")
        private set
    var description: String by mutableStateOf("")
        private set
    var phase: Phase by mutableStateOf(Phase.IDLE)
        private set
    var glow: Rgb by mutableStateOf(DotGeometry.glow(SceneColors[renderer.scene]))
        private set

    fun present(activity: Activity, options: DotMindOptions, still: Boolean) {
        Snapshot.withoutReadObservation {
            this.still = still
            if (driver.present(activity, options.scene, options.palette, visible, still)) frame++
            label = options.visibleLabel(activity)
            description = options.spokenLabel(activity)
            phase = activity.phase
            glow = DotGeometry.glow(options.palette[driver.scene] ?: SceneColors[driver.scene])
        }
    }

    fun tick(dt: Double) {
        driver.advance(dt)
        shimmerClock += dt
        frame++
    }
}
