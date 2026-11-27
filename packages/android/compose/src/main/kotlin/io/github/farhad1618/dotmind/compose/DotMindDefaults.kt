package io.github.farhad1618.dotmind.compose

import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlin.time.Duration
import kotlin.time.Duration.Companion.milliseconds

public object DotMindDefaults {
    public val Size: Dp = 28.dp

    public val ShimmerDuration: Duration = 2400.milliseconds

    public val Colors: DotMindColors = DotMindColors(
        background = Color(0xFF0B0B0C),
        edge = Color(0xFF26262A),
        well = Color(0xFF050506),
        ink = Color(0xFF8A8A92),
        peak = Color.White,
    )

    public val LabelStyle: TextStyle = TextStyle(
        fontSize = 15.sp,
        lineHeight = 18.sp,
        fontWeight = FontWeight.Medium,
    )
}
