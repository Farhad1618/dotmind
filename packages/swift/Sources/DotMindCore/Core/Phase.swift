public enum Phase: String, CaseIterable, Codable, Hashable, Sendable {
    case idle
    case thinking
    case tool
    case writing
    case waiting
    case error
    case done
}
