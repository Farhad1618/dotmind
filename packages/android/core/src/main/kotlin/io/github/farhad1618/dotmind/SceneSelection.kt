package io.github.farhad1618.dotmind

public fun sceneFor(
    activity: Activity,
    look: Look = Look.CLASSIC,
    overrides: Map<SceneKey, Scene> = emptyMap(),
): Scene {
    val key = sceneKey(activity)
    return overrides[key] ?: look.definition.scenes[key] ?: CLASSIC_SCENES.getValue(key)
}

public fun sceneForTool(kind: ToolKind): Scene = CLASSIC_SCENES.getValue(LabelKey.forTool(kind))
