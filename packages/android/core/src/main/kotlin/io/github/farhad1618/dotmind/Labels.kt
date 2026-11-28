package io.github.farhad1618.dotmind

public val DEFAULT_LABELS: Map<LabelKey, String> = mapOf(
    LabelKey.IDLE to "Ready",
    LabelKey.THINKING to "Thinking",
    LabelKey.WRITING to "Writing",
    LabelKey.WAITING to "Waiting for you",
    LabelKey.ERROR to "Something went wrong",
    LabelKey.DONE to "Done",
    LabelKey.TOOL_SEARCH to "Searching",
    LabelKey.TOOL_BROWSE to "Browsing",
    LabelKey.TOOL_CODE to "Running code",
    LabelKey.TOOL_FILE to "Reading files",
    LabelKey.TOOL_DATABASE to "Querying data",
    LabelKey.TOOL_COMPUTE to "Calculating",
    LabelKey.TOOL_TRANSLATE to "Translating",
    LabelKey.TOOL_DEPLOY to "Deploying",
    LabelKey.TOOL_DEBUG to "Debugging",
    LabelKey.TOOL_GENERIC to "Using a tool",
)

public fun labelFor(activity: Activity, labels: Map<LabelKey, String> = emptyMap()): String {
    activity.label?.takeIf { it.isNotEmpty() }?.let { return it }
    val key = LabelKey.forPhase(activity.phase, activity.kind)
    val tool = activity.tool
    if (key == LabelKey.TOOL_GENERIC && !tool.isNullOrEmpty() && labels[LabelKey.TOOL_GENERIC].isNullOrEmpty()) {
        return "Using ${humanizeTool(tool)}"
    }
    return labels[key] ?: DEFAULT_LABELS.getValue(key)
}
