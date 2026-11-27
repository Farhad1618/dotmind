package io.github.farhad1618.dotmind

import kotlin.test.Test
import kotlin.test.assertEquals

class ClassificationTest {
    @Test
    fun toolNamesMapToTheKindOfWorkTheyDo() {
        val cases = mapOf(
            "web_search" to ToolKind.SEARCH,
            "file_search" to ToolKind.SEARCH,
            "searchDocs" to ToolKind.SEARCH,
            "run_sql" to ToolKind.DATABASE,
            "query_clickhouse" to ToolKind.DATABASE,
            "web_fetch" to ToolKind.BROWSE,
            "navigate" to ToolKind.BROWSE,
            "bash" to ToolKind.CODE,
            "code_interpreter" to ToolKind.CODE,
            "str_replace_based_edit_tool" to ToolKind.FILE,
            "read_file" to ToolKind.FILE,
            "calculate_margin" to ToolKind.COMPUTE,
            "get_weather" to ToolKind.GENERIC,
        )
        for ((name, kind) in cases) assertEquals(kind, classifyTool(name), name)
        assertEquals(ToolKind.BROWSE, classifyTool("get_weather", mapOf("get_weather" to ToolKind.BROWSE)))
        assertEquals(ToolKind.GENERIC, classifyTool(null))
    }

    @Test
    fun tokensSplitOnCamelCaseAndSeparators() {
        assertEquals(listOf("search", "docs"), toolTokens("searchDocs"))
        assertEquals(listOf("get", "weather"), toolTokens("get-weather"))
        assertEquals("lookup customer", humanizeTool("lookupCustomer"))
    }

    @Test
    fun labelsFollowTheActivity() {
        assertEquals("Thinking", labelFor(Activity(Phase.THINKING)))
        assertEquals("Searching", labelFor(Activity(Phase.TOOL, kind = ToolKind.SEARCH)))
        assertEquals("Using get weather", labelFor(Activity(Phase.TOOL, tool = "get_weather", kind = ToolKind.GENERIC)))
        assertEquals(
            "Buscando",
            labelFor(Activity(Phase.TOOL, kind = ToolKind.SEARCH), mapOf(LabelKey.TOOL_SEARCH to "Buscando")),
        )
        assertEquals("Drafting reply", labelFor(Activity(Phase.WRITING, label = "Drafting reply")))
        assertEquals(
            "Tool",
            labelFor(Activity(Phase.TOOL, tool = "get_weather"), mapOf(LabelKey.TOOL_GENERIC to "Tool")),
        )
    }

    @Test
    fun eachPhasePicksAScene() {
        assertEquals(Scene.COMET, sceneFor(Activity(Phase.THINKING)))
        assertEquals(Scene.RADAR, sceneFor(Activity(Phase.TOOL, kind = ToolKind.SEARCH)))
        assertEquals(Scene.STACK, sceneFor(Activity(Phase.TOOL, kind = ToolKind.DATABASE)))
        assertEquals(Scene.TYPE, sceneFor(Activity(Phase.WRITING)))
        assertEquals(Scene.CHECK, sceneFor(Activity(Phase.DONE)))
    }
}
