package io.github.farhad1618.dotmind.adapters

import kotlinx.serialization.json.Json

public val StreamJson: Json = Json {
    ignoreUnknownKeys = true
    explicitNulls = false
    coerceInputValues = true
}
