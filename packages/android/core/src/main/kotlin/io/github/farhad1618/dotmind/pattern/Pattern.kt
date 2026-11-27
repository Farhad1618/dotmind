package io.github.farhad1618.dotmind.pattern

public class PatternContext(
    public var energy: Double = 0.0,
    public var progress: Double = 0.0,
)

public fun interface Pattern {
    public fun render(t: Double, out: FloatArray, context: PatternContext)
}
