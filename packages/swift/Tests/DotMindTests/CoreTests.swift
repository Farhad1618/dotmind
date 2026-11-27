import XCTest
@testable import DotMindCore

final class CoreTests: XCTestCase {
    func testToolNamesMapToTheKindOfWorkTheyDo() {
        let cases: [String: ToolKind] = [
            "web_search": .search,
            "file_search": .search,
            "searchDocs": .search,
            "run_sql": .database,
            "query_clickhouse": .database,
            "web_fetch": .browse,
            "navigate": .browse,
            "bash": .code,
            "code_interpreter": .code,
            "str_replace_based_edit_tool": .file,
            "read_file": .file,
            "calculate_margin": .compute,
            "get_weather": .generic,
        ]
        for (name, kind) in cases { XCTAssertEqual(classifyTool(name), kind, name) }
        XCTAssertEqual(classifyTool("get_weather", overrides: ["get_weather": .browse]), .browse)
        XCTAssertEqual(classifyTool(nil), .generic)
    }

    func testToolTokensSplitCamelCaseAndSeparators() {
        XCTAssertEqual(toolTokens("searchDocs"), ["search", "docs"])
        XCTAssertEqual(toolTokens("lookupCustomer-v2"), ["lookup", "customer", "v2"])
        XCTAssertEqual(humanizeTool("get_weather"), "get weather")
    }

    func testLabelsFollowTheActivity() {
        XCTAssertEqual(labelFor(.thinking), "Thinking")
        XCTAssertEqual(labelFor(Activity(phase: .tool, kind: .search)), "Searching")
        XCTAssertEqual(labelFor(Activity(phase: .tool, tool: "get_weather", kind: .generic)), "Using get weather")
        XCTAssertEqual(labelFor(Activity(phase: .tool, kind: .search), labels: [.tool(.search): "Buscando"]), "Buscando")
        XCTAssertEqual(labelFor(Activity(phase: .writing, label: "Drafting reply")), "Drafting reply")
        XCTAssertEqual(
            labelFor(Activity(phase: .tool, tool: "get_weather", kind: .generic), labels: [.tool(.generic): "Working"]),
            "Working"
        )
    }

    func testEachPhasePicksAScene() {
        XCTAssertEqual(sceneFor(.thinking), .comet)
        XCTAssertEqual(sceneFor(Activity(phase: .tool, kind: .search)), .radar)
        XCTAssertEqual(sceneFor(Activity(phase: .tool, kind: .database)), .stack)
        XCTAssertEqual(sceneFor(.writing), .type)
        XCTAssertEqual(sceneFor(.done), .check)
        XCTAssertEqual(sceneFor(.using("web_search")), .radar)
    }

    func testEveryPatternFills64FiniteValuesInRange() {
        var out = [Double](repeating: 0, count: dotCount)
        for scene in SceneName.allCases {
            for t in [0, 0.3, 1.7, 12.5, 400] {
                scene.render(at: t, into: &out, context: PatternContext(energy: 0.8, progress: 137))
                for value in out {
                    XCTAssertTrue(value.isFinite && value >= 0 && value <= 1.6, "\(scene)@\(t): \(value)")
                }
            }
        }
    }

    func testTheWritingSceneLightsMoreDotsAsTextArrives() {
        func lit(_ progress: Double) -> Int {
            SceneName.type.render(at: 0.1, context: PatternContext(energy: 0.5, progress: progress)).filter { $0 > 0.3 }.count
        }
        XCTAssertLessThan(lit(0), lit(40))
        XCTAssertLessThan(lit(40), lit(120))
    }

    func testFasterTextMakesTheRendererLivelier() {
        var renderer = DotRenderer(scene: .type)
        var progress = 0.0
        renderer.feed(progress)
        for _ in 0..<60 {
            renderer.step(1.0 / 60.0)
            progress += 1
            renderer.feed(progress)
        }
        let slow = renderer.level
        for _ in 0..<60 {
            renderer.step(1.0 / 60.0)
            progress += 8
            renderer.feed(progress)
        }
        XCTAssertGreaterThan(renderer.level, slow)
        for _ in 0..<180 { renderer.step(1.0 / 60.0) }
        XCTAssertLessThan(renderer.level, 0.5)
    }

    func testSwitchingScenesCrossFadesInsteadOfCutting() {
        var renderer = DotRenderer(scene: .check)
        renderer.step(2)
        let before = renderer.sample()
        renderer.show(.cross)
        renderer.step(0.1)
        let mid = renderer.sample()
        let target = SceneName.cross.render(
            at: 0.1 * (0.6 + 0.6 * renderer.level),
            context: PatternContext(energy: renderer.level, progress: 0)
        )
        let differsFromBoth = mid.indices.contains { abs(mid[$0] - before[$0]) > 0.05 && abs(mid[$0] - target[$0]) > 0.05 }
        XCTAssertTrue(differsFromBoth)
    }

    func testColoursBlendDuringACrossFade() {
        var renderer = DotRenderer(scene: .check)
        renderer.show(.cross)
        XCTAssertEqual(renderer.color, SceneName.check.defaultColor)
        renderer.step(0.175)
        XCTAssertEqual(renderer.color.red, (70 + 255) / 2, accuracy: 0.001)
        renderer.step(1)
        XCTAssertEqual(renderer.color, SceneName.cross.defaultColor)
    }

    func testEachSceneStartsCountingProgressWhenShown() {
        var renderer = DotRenderer(scene: .comet)
        renderer.feed(400)
        renderer.show(.type, instant: true)
        XCTAssertEqual(renderer.sample().filter { $0 > 0.3 }.count, 1)
        renderer.feed(440)
        XCTAssertGreaterThan(renderer.sample().filter { $0 > 0.3 }.count, 1)
    }
}
