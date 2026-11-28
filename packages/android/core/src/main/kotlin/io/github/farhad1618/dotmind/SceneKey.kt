package io.github.farhad1618.dotmind

public typealias SceneKey = LabelKey

public fun sceneKey(activity: Activity): SceneKey = LabelKey.forPhase(activity.phase, activity.kind)
