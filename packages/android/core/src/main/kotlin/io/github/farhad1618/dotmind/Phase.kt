package io.github.farhad1618.dotmind

public enum class Phase(public val id: String) {
    IDLE("idle"),
    THINKING("thinking"),
    TOOL("tool"),
    WRITING("writing"),
    WAITING("waiting"),
    ERROR("error"),
    DONE("done");

    public companion object {
        public fun fromId(id: String): Phase = entries.first { it.id == id }
    }
}
