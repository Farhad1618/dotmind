package io.github.farhad1618.dotmind

public enum class Look(public val id: String) {
    CLASSIC("classic"),
    ICONS("icons"),
    PIXEL("pixel");

    public val definition: LookDefinition get() = LOOKS.getValue(this)

    public companion object {
        public fun fromId(id: String?): Look = entries.firstOrNull { it.id == id } ?: CLASSIC
    }
}
