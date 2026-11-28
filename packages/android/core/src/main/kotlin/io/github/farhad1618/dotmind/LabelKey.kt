package io.github.farhad1618.dotmind

public enum class LabelKey(public val id: String) {
    IDLE("idle"),
    THINKING("thinking"),
    WRITING("writing"),
    WAITING("waiting"),
    ERROR("error"),
    DONE("done"),
    TOOL_SEARCH("tool:search"),
    TOOL_BROWSE("tool:browse"),
    TOOL_CODE("tool:code"),
    TOOL_FILE("tool:file"),
    TOOL_DATABASE("tool:database"),
    TOOL_COMPUTE("tool:compute"),
    TOOL_TRANSLATE("tool:translate"),
    TOOL_DEPLOY("tool:deploy"),
    TOOL_DEBUG("tool:debug"),
    TOOL_GENERIC("tool:generic");

    public companion object {
        public fun fromId(id: String): LabelKey = entries.first { it.id == id }

        public fun forTool(kind: ToolKind): LabelKey = when (kind) {
            ToolKind.SEARCH -> TOOL_SEARCH
            ToolKind.BROWSE -> TOOL_BROWSE
            ToolKind.CODE -> TOOL_CODE
            ToolKind.FILE -> TOOL_FILE
            ToolKind.DATABASE -> TOOL_DATABASE
            ToolKind.COMPUTE -> TOOL_COMPUTE
            ToolKind.TRANSLATE -> TOOL_TRANSLATE
            ToolKind.DEPLOY -> TOOL_DEPLOY
            ToolKind.DEBUG -> TOOL_DEBUG
            ToolKind.GENERIC -> TOOL_GENERIC
        }

        public fun forPhase(phase: Phase, kind: ToolKind? = null): LabelKey = when (phase) {
            Phase.IDLE -> IDLE
            Phase.THINKING -> THINKING
            Phase.TOOL -> forTool(kind ?: ToolKind.GENERIC)
            Phase.WRITING -> WRITING
            Phase.WAITING -> WAITING
            Phase.ERROR -> ERROR
            Phase.DONE -> DONE
        }
    }
}
