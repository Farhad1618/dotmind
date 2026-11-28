public enum Look: String, CaseIterable, Codable, Hashable, Sendable {
    case classic
    case icons
    case pixel

    public static func named(_ name: String?) -> Look {
        name.flatMap(Look.init(rawValue:)) ?? .classic
    }

    public var definition: LookDefinition {
        looks[self] ?? LookDefinition()
    }
}

public struct LookDefinition: Hashable, Sendable {
    public var scenes: [SceneKey: SceneName]
    public var shape: DotShape
    public var aura: Bool

    public init(scenes: [SceneKey: SceneName] = [:], shape: DotShape = .dot, aura: Bool = false) {
        self.scenes = scenes
        self.shape = shape
        self.aura = aura
    }
}
