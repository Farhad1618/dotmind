package io.github.farhad1618.dotmind.compose

import androidx.compose.foundation.text.BasicText
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.drawWithCache
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.BlendMode
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.CompositingStrategy
import androidx.compose.ui.graphics.drawscope.translate
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.style.TextOverflow

private const val BAND = 2.6f
private const val TRAVEL = BAND - 1f

@Composable
internal fun ShimmerLabel(
    text: String,
    style: TextStyle,
    ink: Color,
    peak: Color,
    glow: Color,
    position: () -> Float,
    modifier: Modifier = Modifier,
) {
    BasicText(
        text = text,
        style = style.copy(color = ink),
        maxLines = 1,
        softWrap = false,
        overflow = TextOverflow.Ellipsis,
        modifier = modifier
            .graphicsLayer { compositingStrategy = CompositingStrategy.Offscreen }
            .drawWithCache {
                val band = size.width * BAND
                val brush = Brush.horizontalGradient(
                    0f to ink,
                    0.38f to ink,
                    0.47f to peak,
                    0.52f to glow,
                    0.62f to ink,
                    1f to ink,
                    startX = 0f,
                    endX = band,
                )
                val bandSize = Size(band, size.height)
                onDrawWithContent {
                    drawContent()
                    translate(left = -TRAVEL * size.width * position()) {
                        drawRect(brush = brush, size = bandSize, blendMode = BlendMode.SrcIn)
                    }
                }
            },
    )
}

internal inline fun shimmerPosition(animated: Boolean, still: Boolean, seconds: Double, clock: () -> Double): Float = when {
    !animated -> 1f
    still -> 0.5f
    seconds <= 0.0 -> 0.5f
    else -> {
        val cycle = (clock() / seconds) % 1.0
        (1.3 - 1.6 * cycle).toFloat()
    }
}
