public enum LabelKey: Hashable, Sendable {
    case idle
    case thinking
    case writing
    case waiting
    case error
    case done
    case tool(ToolKind)

    public init(_ activity: Activity) {
        switch activity.phase {
        case .idle: self = .idle
        case .thinking: self = .thinking
        case .tool: self = .tool(activity.kind ?? .generic)
        case .writing: self = .writing
        case .waiting: self = .waiting
        case .error: self = .error
        case .done: self = .done
        }
    }
}

public let defaultLabels: [LabelKey: String] = [
    .idle: "Ready",
    .thinking: "Thinking",
    .writing: "Writing",
    .waiting: "Waiting for you",
    .error: "Something went wrong",
    .done: "Done",
    .tool(.search): "Searching",
    .tool(.browse): "Browsing",
    .tool(.code): "Running code",
    .tool(.file): "Reading files",
    .tool(.database): "Querying data",
    .tool(.compute): "Calculating",
    .tool(.generic): "Using a tool",
]

public func labelFor(_ activity: Activity, labels: [LabelKey: String] = [:]) -> String {
    if let label = activity.label, !label.isEmpty { return label }
    let key = LabelKey(activity)
    if key == .tool(.generic), let tool = activity.tool, !tool.isEmpty, (labels[key] ?? "").isEmpty {
        return "Using \(humanizeTool(tool))"
    }
    return labels[key] ?? defaultLabels[key] ?? ""
}
