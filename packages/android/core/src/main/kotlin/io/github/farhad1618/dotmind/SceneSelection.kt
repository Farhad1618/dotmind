package io.github.farhad1618.dotmind

public fun sceneFor(activity: Activity): Scene = when (activity.phase) {
    Phase.IDLE -> Scene.BREATHE
    Phase.THINKING -> Scene.COMET
    Phase.TOOL -> sceneForTool(activity.kind ?: ToolKind.GENERIC)
    Phase.WRITING -> Scene.TYPE
    Phase.WAITING -> Scene.HALO
    Phase.ERROR -> Scene.CROSS
    Phase.DONE -> Scene.CHECK
}

public fun sceneForTool(kind: ToolKind): Scene = when (kind) {
    ToolKind.SEARCH -> Scene.RADAR
    ToolKind.BROWSE -> Scene.GLOBE
    ToolKind.CODE -> Scene.CODE
    ToolKind.FILE -> Scene.PAGES
    ToolKind.DATABASE -> Scene.STACK
    ToolKind.COMPUTE -> Scene.PRISM
    ToolKind.GENERIC -> Scene.CIRCUIT
}
