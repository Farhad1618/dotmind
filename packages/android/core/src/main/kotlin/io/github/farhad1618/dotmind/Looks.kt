package io.github.farhad1618.dotmind

public data class LookDefinition(
    val scenes: Map<SceneKey, Scene>,
    val shape: DotShape,
    val aura: Boolean,
)

public val CLASSIC_SCENES: Map<SceneKey, Scene> = mapOf(
    SceneKey.IDLE to Scene.BREATHE,
    SceneKey.THINKING to Scene.COMET,
    SceneKey.WRITING to Scene.TYPE,
    SceneKey.WAITING to Scene.HALO,
    SceneKey.ERROR to Scene.CROSS,
    SceneKey.DONE to Scene.CHECK,
    SceneKey.TOOL_SEARCH to Scene.RADAR,
    SceneKey.TOOL_BROWSE to Scene.GLOBE,
    SceneKey.TOOL_CODE to Scene.CODE,
    SceneKey.TOOL_FILE to Scene.PAGES,
    SceneKey.TOOL_DATABASE to Scene.STACK,
    SceneKey.TOOL_COMPUTE to Scene.PRISM,
    SceneKey.TOOL_TRANSLATE to Scene.GLYPH,
    SceneKey.TOOL_DEPLOY to Scene.ROCKET,
    SceneKey.TOOL_DEBUG to Scene.BUG,
    SceneKey.TOOL_GENERIC to Scene.CIRCUIT,
)

public val LOOKS: Map<Look, LookDefinition> = mapOf(
    Look.CLASSIC to LookDefinition(scenes = emptyMap(), shape = DotShape.DOT, aura = false),
    Look.ICONS to LookDefinition(
        scenes = mapOf(
            SceneKey.THINKING to Scene.NEURAL,
            SceneKey.DONE to Scene.VERIFIED,
            SceneKey.TOOL_SEARCH to Scene.MAGNIFIER,
            SceneKey.TOOL_TRANSLATE to Scene.GLYPH,
            SceneKey.TOOL_COMPUTE to Scene.SORT,
            SceneKey.TOOL_DEPLOY to Scene.ROCKET,
        ),
        shape = DotShape.DOT,
        aura = true,
    ),
    Look.PIXEL to LookDefinition(
        scenes = mapOf(
            SceneKey.TOOL_DEBUG to Scene.BUG,
            SceneKey.TOOL_CODE to Scene.BLOCKS,
            SceneKey.TOOL_SEARCH to Scene.SCAN,
        ),
        shape = DotShape.SQUARE,
        aura = false,
    ),
)
