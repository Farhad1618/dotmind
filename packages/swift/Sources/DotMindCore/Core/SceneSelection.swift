public func sceneFor(_ activity: Activity) -> SceneName {
    switch activity.phase {
    case .idle: .breathe
    case .thinking: .comet
    case .tool: toolScene(activity.kind ?? .generic)
    case .writing: .type
    case .waiting: .halo
    case .error: .cross
    case .done: .check
    }
}

private func toolScene(_ kind: ToolKind) -> SceneName {
    switch kind {
    case .search: .radar
    case .browse: .globe
    case .code: .code
    case .file: .pages
    case .database: .stack
    case .compute: .prism
    case .generic: .circuit
    }
}
