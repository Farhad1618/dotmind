package io.github.farhad1618.dotmind.compose

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.boundsInWindow
import androidx.compose.ui.layout.onGloballyPositioned
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.unit.Dp
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.compose.LocalLifecycleOwner
import androidx.lifecycle.compose.currentStateAsState
import io.github.farhad1618.dotmind.DotShape
import kotlin.math.roundToInt

private val WellShapes: Map<DotShape, RoundedCornerShape> =
    DotShape.entries.associateWith { RoundedCornerShape((it.wellCorner * 100).roundToInt()) }

@Composable
internal fun DotMatrix(host: IndicatorHost, size: Dp, well: Color, aura: Modifier = Modifier) {
    val lifecycle by LocalLifecycleOwner.current.lifecycle.currentStateAsState()
    val running = host.visible && !host.still && lifecycle.isAtLeast(Lifecycle.State.STARTED)
    val shape = host.shape
    FrameLoop(host, running)
    Canvas(
        modifier = Modifier
            .size(size)
            .then(aura)
            .clip(WellShapes.getValue(shape))
            .background(well)
            .clearAndSetSemantics {}
            .onGloballyPositioned { coordinates ->
                val bounds = coordinates.boundsInWindow()
                host.visible = bounds.width > 0f && bounds.height > 0f
            },
    ) {
        host.frame
        drawDots(host.renderer, host.values, host.color, shape)
    }
}
