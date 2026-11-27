public enum DotMindVariant: Hashable, Sendable {
    case pill
    case bare
}

public enum DotMindLabel: Hashable, Sendable {
    case automatic
    case text(String)
    case hidden
}
