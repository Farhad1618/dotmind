package io.github.farhad1618.dotmind.compose

import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.unit.Dp
import io.github.farhad1618.dotmind.Activity
import io.github.farhad1618.dotmind.ActivityTracker
import io.github.farhad1618.dotmind.DotShape
import io.github.farhad1618.dotmind.LabelKey
import io.github.farhad1618.dotmind.Look
import io.github.farhad1618.dotmind.Phase
import io.github.farhad1618.dotmind.Rgb
import io.github.farhad1618.dotmind.Scene
import io.github.farhad1618.dotmind.SceneKey
import io.github.farhad1618.dotmind.ToolKind
import kotlin.time.Duration

@Composable
public fun DotMind(
    activity: Activity,
    modifier: Modifier = Modifier,
    variant: DotMindVariant = DotMindVariant.Pill,
    size: Dp = DotMindDefaults.Size,
    label: String? = null,
    showLabel: Boolean = true,
    labels: Map<LabelKey, String> = emptyMap(),
    palette: Map<Scene, Rgb> = emptyMap(),
    scene: Scene? = null,
    look: Look = Look.CLASSIC,
    shape: DotShape? = null,
    scenes: Map<SceneKey, Scene> = emptyMap(),
    aura: Boolean? = null,
    reducedMotion: Boolean? = null,
    colors: DotMindColors = DotMindDefaults.Colors,
    textStyle: TextStyle = DotMindDefaults.LabelStyle,
    shimmerDuration: Duration = DotMindDefaults.ShimmerDuration,
) {
    val options = dotMindOptions(label, showLabel, labels, palette, scene, look, shape, scenes, aura)
    val systemReduced = rememberSystemReducedMotion()
    val still = reducedMotion ?: systemReduced
    val host = remember { IndicatorHost() }
    host.present(activity, options, still)
    DotMindContent(host, variant, size, colors, textStyle, shimmerDuration, modifier)
}

@Composable
public fun DotMind(
    phase: Phase,
    modifier: Modifier = Modifier,
    variant: DotMindVariant = DotMindVariant.Pill,
    size: Dp = DotMindDefaults.Size,
    label: String? = null,
    showLabel: Boolean = true,
    labels: Map<LabelKey, String> = emptyMap(),
    palette: Map<Scene, Rgb> = emptyMap(),
    scene: Scene? = null,
    look: Look = Look.CLASSIC,
    shape: DotShape? = null,
    scenes: Map<SceneKey, Scene> = emptyMap(),
    aura: Boolean? = null,
    reducedMotion: Boolean? = null,
    colors: DotMindColors = DotMindDefaults.Colors,
    textStyle: TextStyle = DotMindDefaults.LabelStyle,
    shimmerDuration: Duration = DotMindDefaults.ShimmerDuration,
) {
    val activity = remember(phase) { Activity(phase) }
    DotMind(
        activity = activity,
        modifier = modifier,
        variant = variant,
        size = size,
        label = label,
        showLabel = showLabel,
        labels = labels,
        palette = palette,
        scene = scene,
        look = look,
        shape = shape,
        scenes = scenes,
        aura = aura,
        reducedMotion = reducedMotion,
        colors = colors,
        textStyle = textStyle,
        shimmerDuration = shimmerDuration,
    )
}

@Composable
public fun DotMind(
    tracker: ActivityTracker,
    modifier: Modifier = Modifier,
    variant: DotMindVariant = DotMindVariant.Pill,
    size: Dp = DotMindDefaults.Size,
    label: String? = null,
    showLabel: Boolean = true,
    labels: Map<LabelKey, String> = emptyMap(),
    palette: Map<Scene, Rgb> = emptyMap(),
    scene: Scene? = null,
    look: Look = Look.CLASSIC,
    shape: DotShape? = null,
    scenes: Map<SceneKey, Scene> = emptyMap(),
    aura: Boolean? = null,
    reducedMotion: Boolean? = null,
    colors: DotMindColors = DotMindDefaults.Colors,
    textStyle: TextStyle = DotMindDefaults.LabelStyle,
    shimmerDuration: Duration = DotMindDefaults.ShimmerDuration,
) {
    val options = dotMindOptions(label, showLabel, labels, palette, scene, look, shape, scenes, aura)
    val systemReduced = rememberSystemReducedMotion()
    val still = reducedMotion ?: systemReduced
    val host = remember(tracker) { IndicatorHost() }
    host.present(tracker.current, options, still)
    val latestOptions by rememberUpdatedState(options)
    val latestStill by rememberUpdatedState(still)
    LaunchedEffect(tracker, host) {
        tracker.activity.collect { activity -> host.present(activity, latestOptions, latestStill) }
    }
    DotMindContent(host, variant, size, colors, textStyle, shimmerDuration, modifier)
}

private fun dotMindOptions(
    label: String?,
    showLabel: Boolean,
    labels: Map<LabelKey, String>,
    palette: Map<Scene, Rgb>,
    scene: Scene?,
    look: Look,
    shape: DotShape?,
    scenes: Map<SceneKey, Scene>,
    aura: Boolean?,
): DotMindOptions = DotMindOptions(
    label = label,
    showLabel = showLabel,
    labels = labels,
    palette = palette,
    scene = scene,
    look = look,
    scenes = scenes,
    shape = shape ?: look.definition.shape,
    aura = aura ?: look.definition.aura,
)

@Composable
public fun rememberActivityTracker(tools: Map<String, ToolKind> = emptyMap()): ActivityTracker =
    remember { ActivityTracker(tools) }
