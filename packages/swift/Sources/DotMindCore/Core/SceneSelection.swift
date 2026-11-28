public typealias SceneKey = LabelKey

public func sceneKey(_ activity: Activity) -> SceneKey {
    SceneKey(activity)
}

public func sceneFor(
    _ activity: Activity,
    look: Look = .classic,
    overrides: [SceneKey: SceneName] = [:]
) -> SceneName {
    let key = sceneKey(activity)
    return overrides[key] ?? look.definition.scenes[key] ?? classicScenes[key] ?? .circuit
}
