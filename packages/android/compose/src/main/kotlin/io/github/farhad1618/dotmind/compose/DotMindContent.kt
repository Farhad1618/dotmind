package io.github.farhad1618.dotmind.compose

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.semantics.LiveRegionMode
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.liveRegion
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.isSpecified
import androidx.compose.ui.unit.sp
import io.github.farhad1618.dotmind.Phase
import io.github.farhad1618.dotmind.Rgb
import kotlin.time.Duration
import kotlin.time.DurationUnit

private val STATIC_PHASES = setOf(Phase.IDLE, Phase.DONE, Phase.ERROR)

@Composable
internal fun DotMindContent(
    host: IndicatorHost,
    variant: DotMindVariant,
    size: Dp,
    colors: DotMindColors,
    textStyle: TextStyle,
    shimmerDuration: Duration,
    modifier: Modifier,
) {
    val label = host.label
    val description = host.description
    val fontSize = if (textStyle.fontSize.isSpecified) textStyle.fontSize else 15.sp
    val em = with(LocalDensity.current) { fontSize.toDp() }
    val shell = if (variant == DotMindVariant.Pill) {
        Modifier
            .background(colors.background, CircleShape)
            .border(1.dp, colors.edge, CircleShape)
            .padding(start = em * 0.35f, top = em * 0.35f, bottom = em * 0.35f, end = if (label.isEmpty()) em * 0.35f else em * 1.15f)
    } else {
        Modifier
    }
    Row(
        modifier = modifier
            .clearAndSetSemantics {
                contentDescription = description
                liveRegion = LiveRegionMode.Polite
            }
            .then(shell),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(em * 0.6f),
    ) {
        DotMatrix(host, size, colors.well)
        if (label.isNotEmpty()) {
            val animated = host.phase !in STATIC_PHASES
            val seconds = shimmerDuration.toDouble(DurationUnit.SECONDS)
            ShimmerLabel(
                text = label,
                style = textStyle,
                ink = colors.ink,
                peak = colors.peak,
                glow = host.glow.toColor(),
                position = { shimmerPosition(animated, host.still, seconds) { host.shimmerClock } },
            )
        }
    }
}

private fun Rgb.toColor(): Color = Color(red = (red / 255).toFloat(), green = (green / 255).toFloat(), blue = (blue / 255).toFloat())
