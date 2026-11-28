public enum ToolKind: String, CaseIterable, Codable, Hashable, Sendable {
    case search
    case browse
    case code
    case file
    case database
    case compute
    case translate
    case deploy
    case debug
    case generic
}
