package io.github.farhad1618.dotmind.compose

import android.graphics.BlurMaskFilter
import android.graphics.Paint
import android.os.Build
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.drawIntoCanvas
import androidx.compose.ui.graphics.nativeCanvas
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import kotlin.math.abs
import kotlin.math.exp
import kotlin.math.max
import kotlin.math.min
import kotlin.math.sqrt

internal class AuraLayer(val blur: Dp, val spread: Dp, val alpha: Float, val bands: Int)

internal val PillAura: List<AuraLayer> = listOf(
    AuraLayer(blur = 72.dp, spread = 8.dp, alpha = 0.2f, bands = 18),
    AuraLayer(blur = 24.dp, spread = (-6).dp, alpha = 0.55f, bands = 10),
)

internal val WellAura: List<AuraLayer> = listOf(
    AuraLayer(blur = 18.dp, spread = 2.dp, alpha = 0.55f, bands = 10),
)

internal const val AURA_FADE_MILLIS: Int = 350

private const val BLUR_SDK: Int = 28

private const val SKIA_SIGMA_SCALE: Float = 0.57735f

internal fun Modifier.aura(
    host: IndicatorHost,
    layers: List<AuraLayer>,
    corner: Float,
    amount: () -> Float,
): Modifier {
    val paints = if (Build.VERSION.SDK_INT >= BLUR_SDK) arrayOfNulls<Paint>(layers.size) else null
    return drawBehind {
        host.frame
        val k = amount()
        if (k <= 0f) return@drawBehind
        val rgb = host.renderer.colorInto(host.auraColor)
        val radius = min(size.width, size.height) * corner
        for (index in layers.indices) {
            val layer = layers[index]
            if (paints == null) {
                drawAuraLayer(rgb, layer.alpha * k, layer.blur.toPx(), layer.spread.toPx(), layer.bands, radius)
            } else {
                val paint = paints[index] ?: blurPaint(layer.blur.toPx()).also { paints[index] = it }
                drawBlurredLayer(paint, rgb, layer.alpha * k, layer.spread.toPx(), radius)
            }
        }
    }
}

internal fun blurRadiusFor(blur: Float): Float = max(0.5f, (blur / 2 - 0.5f) / SKIA_SIGMA_SCALE)

private fun blurPaint(blur: Float): Paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
    style = Paint.Style.FILL
    maskFilter = BlurMaskFilter(blurRadiusFor(blur), BlurMaskFilter.Blur.NORMAL)
}

private fun DrawScope.drawBlurredLayer(paint: Paint, rgb: DoubleArray, alpha: Float, spread: Float, radius: Float) {
    if (alpha <= 0f) return
    val corner = max(0f, radius + spread)
    paint.color = rgba(rgb[0], rgb[1], rgb[2], alpha.toDouble()).toArgb()
    drawIntoCanvas { canvas ->
        canvas.nativeCanvas.drawRoundRect(-spread, -spread, size.width + spread, size.height + spread, corner, corner, paint)
    }
}

private fun DrawScope.drawAuraLayer(rgb: DoubleArray, alpha: Float, blur: Float, spread: Float, bands: Int, radius: Float) {
    val sigma = blur / 2
    val extent = spread + sigma * 3
    if (extent <= 0f || alpha <= 0f) return
    var outer = 0.0
    for (k in bands - 1 downTo 0) {
        val edge = extent * (k + 1) / bands
        val middle = extent * (k + 0.5f) / bands
        val target = alpha * (1 - normalCdf(((middle - spread) / sigma).toDouble()))
        val band = if (outer >= 1.0) 0.0 else 1 - (1 - target) / (1 - outer)
        outer = target
        if (band <= 0.0) continue
        drawRoundRect(
            color = rgba(rgb[0], rgb[1], rgb[2], band),
            topLeft = Offset(-edge, -edge),
            size = Size(size.width + edge * 2, size.height + edge * 2),
            cornerRadius = CornerRadius(radius + edge, radius + edge),
        )
    }
}

internal fun normalCdf(z: Double): Double = 0.5 * (1 + erf(z / sqrt(2.0)))

private fun erf(x: Double): Double {
    val t = 1 / (1 + 0.3275911 * abs(x))
    val poly = t * (0.254829592 + t * (-0.284496736 + t * (1.421413741 + t * (-1.453152027 + t * 1.061405429))))
    val y = 1 - poly * exp(-x * x)
    return if (x >= 0) y else -y
}
