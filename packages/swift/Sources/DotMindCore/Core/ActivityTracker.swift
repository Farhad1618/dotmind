import Combine

@MainActor
public final class ActivityTracker: ObservableObject {
    @Published public private(set) var activity = Activity(phase: .idle, progress: 0)

    private let tools: [String: ToolKind]
    private var openTools: [(id: String, name: String)] = []

    nonisolated public init(tools: [String: ToolKind] = [:]) {
        self.tools = tools
    }

    public func reset() {
        openTools.removeAll()
        set(Activity(phase: .idle, progress: 0))
    }

    public func push<Events: Sequence>(contentsOf events: Events) where Events.Element == AgentEvent {
        for event in events { push(event) }
    }

    public func push(_ event: AgentEvent) {
        let progress = activity.progress ?? 0
        switch event {
        case .start:
            openTools.removeAll()
            set(Activity(phase: .thinking, progress: progress))
        case let .thinking(chars):
            set(Activity(phase: .thinking, progress: progress + chars))
        case let .tool(name, id):
            if let id, !id.isEmpty { open(id, name) }
            set(Activity(phase: .tool, tool: name, kind: kind(of: name), progress: progress))
        case let .toolInput(chars):
            var next = activity
            next.progress = progress + chars
            set(next)
        case let .toolResult(id, _):
            if let id, !id.isEmpty { openTools.removeAll { $0.id == id } }
            set(Activity(phase: .thinking, progress: progress))
        case let .text(chars):
            set(Activity(phase: .writing, progress: progress + chars))
        case let .approval(name, _):
            set(Activity(phase: .waiting, tool: name, kind: kind(of: name), progress: progress))
        case .error:
            set(Activity(phase: .error, progress: progress))
        case let .finish(pendingTools):
            finish(pendingTools: pendingTools, progress: progress)
        }
    }

    private func finish(pendingTools: Bool, progress: Int) {
        guard pendingTools else { return set(Activity(phase: .done, progress: progress)) }
        let last = openTools.last?.name ?? activity.tool
        set(Activity(phase: .tool, tool: last, kind: kind(of: last), progress: progress))
    }

    private func open(_ id: String, _ name: String) {
        if let index = openTools.firstIndex(where: { $0.id == id }) {
            openTools[index].name = name
        } else {
            openTools.append((id, name))
        }
    }

    private func kind(of name: String?) -> ToolKind {
        classifyTool(name, overrides: tools)
    }

    private func set(_ next: Activity) {
        let previous = activity
        let unchanged = previous.phase == next.phase
            && previous.tool == next.tool
            && previous.kind == next.kind
            && previous.progress == next.progress
        if unchanged { return }
        activity = next
    }
}
