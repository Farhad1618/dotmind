package io.github.farhad1618.dotmind

public enum class ToolKind(public val id: String) {
    SEARCH("search"),
    BROWSE("browse"),
    CODE("code"),
    FILE("file"),
    DATABASE("database"),
    COMPUTE("compute"),
    GENERIC("generic");

    public companion object {
        public fun fromId(id: String): ToolKind = entries.first { it.id == id }
    }
}
