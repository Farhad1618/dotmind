private let classificationRules: [(kind: ToolKind, words: [String])] = [
    (.search, ["search", "find", "lookup", "grep", "retriev", "rag", "google", "bing", "glob"]),
    (.database, ["sql", "db", "database", "table", "query", "clickhouse", "postgres", "bigquery", "snowflake", "mongo", "redis"]),
    (.browse, ["browse", "browser", "navigate", "fetch", "url", "scrape", "crawl", "http", "page", "click", "screenshot", "computer", "web"]),
    (.code, ["code", "exec", "run", "python", "bash", "shell", "terminal", "sandbox", "eval", "interpreter", "script", "notebook"]),
    (.file, ["file", "read", "write", "edit", "fs", "doc", "pdf", "upload", "download", "save", "replace", "editor", "ls", "dir"]),
    (.compute, ["calc", "math", "compute", "sum", "stat", "analy", "chart", "plot", "forecast"]),
]

public func classifyTool(_ name: String?, overrides: [String: ToolKind] = [:]) -> ToolKind {
    guard let name, !name.isEmpty else { return .generic }
    if let own = overrides[name] { return own }
    let tokens = toolTokens(name)
    for rule in classificationRules where tokens.contains(where: { matches($0, rule.words) }) {
        return rule.kind
    }
    return .generic
}

public func humanizeTool(_ name: String) -> String {
    toolTokens(name).joined(separator: " ")
}

func toolTokens(_ name: String) -> [String] {
    var tokens: [String] = []
    var current = String.UnicodeScalarView()
    for scalar in splitCamelCase(name).lowercased().unicodeScalars {
        if isLowerOrDigit(scalar) {
            current.append(scalar)
        } else if !current.isEmpty {
            tokens.append(String(current))
            current = String.UnicodeScalarView()
        }
    }
    if !current.isEmpty { tokens.append(String(current)) }
    return tokens
}

private func matches(_ token: String, _ words: [String]) -> Bool {
    words.contains { word in token == word || (word.count > 3 && token.hasPrefix(word)) }
}

private func splitCamelCase(_ name: String) -> String {
    var result = String.UnicodeScalarView()
    var previous: Unicode.Scalar?
    for scalar in name.unicodeScalars {
        if let previous, isLowerOrDigit(previous), isUpper(scalar) {
            result.append("_")
        }
        result.append(scalar)
        previous = scalar
    }
    return String(result)
}

private func isLowerOrDigit(_ scalar: Unicode.Scalar) -> Bool {
    ("a"..."z").contains(scalar) || ("0"..."9").contains(scalar)
}

private func isUpper(_ scalar: Unicode.Scalar) -> Bool {
    ("A"..."Z").contains(scalar)
}
