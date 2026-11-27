package io.github.farhad1618.dotmind

import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.double
import kotlinx.serialization.json.int
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import java.io.File

object GoldenFixture {
    val root: JsonObject by lazy {
        val path = System.getProperty("dotmind.golden") ?: error("dotmind.golden system property is not set")
        Json.parseToJsonElement(File(path).readText()).jsonObject
    }

    val tolerance: Double get() = root.getValue("tolerance").jsonPrimitive.double

    fun list(name: String): List<JsonObject> = root.getValue(name).jsonArray.map { it.jsonObject }

    fun values(entry: JsonObject): DoubleArray =
        (entry.getValue("values") as JsonArray).map { it.jsonPrimitive.double }.toDoubleArray()

    fun double(entry: JsonObject, key: String): Double = entry.getValue(key).jsonPrimitive.double

    fun int(entry: JsonObject, key: String): Int = entry.getValue(key).jsonPrimitive.int

    fun string(entry: JsonObject, key: String): String? = entry[key]?.jsonPrimitive?.content
}
