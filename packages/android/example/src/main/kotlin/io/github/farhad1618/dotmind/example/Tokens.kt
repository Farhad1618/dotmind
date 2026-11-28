package io.github.farhad1618.dotmind.example

import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.em
import androidx.compose.ui.unit.sp

internal object Tokens {
    val Stage = Color(0xFF121213)
    val Panel = Color(0xFF0D0D0E)
    val Well = Color(0xFF0C0C0D)
    val Rule = Color(0xFF232327)
    val Ink = Color(0xFFECECEF)
    val InkDim = Color(0xFF8A8A92)
    val InkFaint = Color(0xFF55555C)
    val Chip = Color(0xFF1A1A1D)
    val ChipOn = Color(0xFF26263A)
    val Accent = Color(0xFF8F7DFF)

    val Eyebrow = TextStyle(
        fontFamily = FontFamily.Monospace,
        fontSize = 11.sp,
        lineHeight = 14.sp,
        letterSpacing = 0.18.em,
        color = InkFaint,
    )

    val Title = TextStyle(
        fontSize = 32.sp,
        lineHeight = 36.sp,
        fontWeight = FontWeight.SemiBold,
        letterSpacing = (-0.03).em,
        color = Ink,
    )

    val Heading = TextStyle(
        fontSize = 20.sp,
        lineHeight = 26.sp,
        fontWeight = FontWeight.SemiBold,
        letterSpacing = (-0.01).em,
        color = Ink,
    )

    val Body = TextStyle(
        fontSize = 15.sp,
        lineHeight = 23.sp,
        color = InkDim,
    )

    val Code = TextStyle(
        fontFamily = FontFamily.Monospace,
        fontSize = 12.sp,
        lineHeight = 19.sp,
        color = InkDim,
    )

    val Caption = TextStyle(
        fontFamily = FontFamily.Monospace,
        fontSize = 11.sp,
        lineHeight = 14.sp,
        color = InkFaint,
    )

    val ChipText = TextStyle(
        fontFamily = FontFamily.Monospace,
        fontSize = 11.sp,
        lineHeight = 11.sp,
        letterSpacing = 0.06.em,
    )

    val HeroLabel = TextStyle(
        fontSize = 24.sp,
        lineHeight = 28.sp,
        fontWeight = FontWeight.Medium,
    )

    val RowLabel = TextStyle(
        fontSize = 15.sp,
        lineHeight = 18.sp,
        fontWeight = FontWeight.Medium,
    )
}
