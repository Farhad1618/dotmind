package io.github.farhad1618.dotmind

public data class Activity(
    val phase: Phase,
    val tool: String? = null,
    val kind: ToolKind? = null,
    val label: String? = null,
    val progress: Int? = null,
)
