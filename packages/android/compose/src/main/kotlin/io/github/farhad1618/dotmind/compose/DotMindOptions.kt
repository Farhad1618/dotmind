package io.github.farhad1618.dotmind.compose

import io.github.farhad1618.dotmind.Activity
import io.github.farhad1618.dotmind.LabelKey
import io.github.farhad1618.dotmind.Rgb
import io.github.farhad1618.dotmind.Scene
import io.github.farhad1618.dotmind.labelFor

internal data class DotMindOptions(
    val label: String?,
    val showLabel: Boolean,
    val labels: Map<LabelKey, String>,
    val palette: Map<Scene, Rgb>,
    val scene: Scene?,
) {
    fun visibleLabel(activity: Activity): String = if (!showLabel) "" else label ?: labelFor(activity, labels)

    fun spokenLabel(activity: Activity): String = visibleLabel(activity).ifEmpty { labelFor(activity, labels) }
}
