public struct Activity: Codable, Hashable, Sendable {
    public var phase: Phase
    public var tool: String?
    public var kind: ToolKind?
    public var label: String?
    public var progress: Int?

    public init(
        phase: Phase = .idle,
        tool: String? = nil,
        kind: ToolKind? = nil,
        label: String? = nil,
        progress: Int? = nil
    ) {
        self.phase = phase
        self.tool = tool
        self.kind = kind
        self.label = label
        self.progress = progress
    }
}

extension Activity {
    public static let idle = Activity(phase: .idle)
    public static let thinking = Activity(phase: .thinking)
    public static let writing = Activity(phase: .writing)
    public static let waiting = Activity(phase: .waiting)
    public static let error = Activity(phase: .error)
    public static let done = Activity(phase: .done)

    public static func using(_ tool: String, overrides: [String: ToolKind] = [:]) -> Activity {
        Activity(phase: .tool, tool: tool, kind: classifyTool(tool, overrides: overrides))
    }
}
