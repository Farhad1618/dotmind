package io.github.farhad1618.dotmind

private val RULES: List<Pair<ToolKind, List<String>>> = listOf(
    ToolKind.SEARCH to listOf("search", "find", "lookup", "grep", "retriev", "rag", "google", "bing", "glob"),
    ToolKind.DATABASE to listOf(
        "sql", "db", "database", "table", "query", "clickhouse", "postgres", "bigquery", "snowflake", "mongo", "redis",
    ),
    ToolKind.BROWSE to listOf(
        "browse", "browser", "navigate", "fetch", "url", "scrape", "crawl", "http", "page", "click", "screenshot",
        "computer", "web",
    ),
    ToolKind.CODE to listOf(
        "code", "exec", "run", "python", "bash", "shell", "terminal", "sandbox", "eval", "interpreter", "script",
        "notebook",
    ),
    ToolKind.FILE to listOf(
        "file", "read", "write", "edit", "fs", "doc", "pdf", "upload", "download", "save", "replace", "editor", "ls",
        "dir",
    ),
    ToolKind.COMPUTE to listOf("calc", "math", "compute", "sum", "stat", "analy", "chart", "plot", "forecast"),
)

private val CAMEL_BOUNDARY = Regex("([a-z0-9])([A-Z])")
private val SEPARATORS = Regex("[^a-z0-9]+")

public fun toolTokens(name: String): List<String> =
    name.replace(CAMEL_BOUNDARY, "$1_$2")
        .lowercase()
        .split(SEPARATORS)
        .filter { it.isNotEmpty() }

public fun classifyTool(name: String?, overrides: Map<String, ToolKind> = emptyMap()): ToolKind {
    if (name.isNullOrEmpty()) return ToolKind.GENERIC
    overrides[name]?.let { return it }
    val tokens = toolTokens(name)
    for ((kind, words) in RULES) {
        if (tokens.any { token -> words.any { word -> token == word || (word.length > 3 && token.startsWith(word)) } }) {
            return kind
        }
    }
    return ToolKind.GENERIC
}

public fun humanizeTool(name: String): String = toolTokens(name).joinToString(" ")
