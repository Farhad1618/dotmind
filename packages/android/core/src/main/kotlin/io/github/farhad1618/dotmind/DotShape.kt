package io.github.farhad1618.dotmind

public enum class DotShape(
    public val id: String,
    public val size: Double,
    public val corner: Double,
    public val baseAlpha: Double,
    public val wellCorner: Double,
) {
    DOT("dot", size = 0.68, corner = 0.5, baseAlpha = 0.14, wellCorner = 0.24),
    SQUARE("square", size = 0.8, corner = 0.22, baseAlpha = 0.2, wellCorner = 0.14);

    public companion object {
        public fun fromId(id: String?): DotShape = entries.firstOrNull { it.id == id } ?: DOT
    }
}
