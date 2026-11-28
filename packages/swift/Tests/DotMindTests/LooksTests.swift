import XCTest
@testable import DotMindCore

final class LooksTests: XCTestCase {
    private let iconScenes: [SceneName] = [.neural, .magnifier, .glyph, .sort, .rocket, .verified]
    private let pixelScenes: [SceneName] = [.bug, .blocks, .scan]

    func testNewToolNamesClassifyAsTranslateDeployAndDebug() {
        let cases: [String: ToolKind] = [
            "translate_text": .translate,
            "localizeStrings": .translate,
            "i18n_lookup": .search,
            "set_locale": .translate,
            "deploy_service": .deploy,
            "publish_release": .deploy,
            "kubectl_apply": .deploy,
            "helm": .deploy,
            "debugger": .debug,
            "set_breakpoint": .debug,
            "inspect_element": .debug,
            "read_stacktrace": .file,
        ]
        for (name, kind) in cases { XCTAssertEqual(classifyTool(name), kind, name) }
    }

    func testNewKindsHaveLabels() {
        XCTAssertEqual(labelFor(Activity(phase: .tool, kind: .translate)), "Translating")
        XCTAssertEqual(labelFor(Activity(phase: .tool, kind: .deploy)), "Deploying")
        XCTAssertEqual(labelFor(Activity(phase: .tool, kind: .debug)), "Debugging")
    }

    func testEveryNewPatternStaysInRangeOverManyFrames() {
        var out = [Double](repeating: 0, count: dotCount)
        for scene in iconScenes + pixelScenes {
            var lit = false
            for step in 0..<1200 {
                let t = Double(step) * 0.037
                scene.render(at: t, into: &out, context: PatternContext(energy: 0.8, progress: 137))
                for value in out {
                    XCTAssertTrue(value.isFinite && value >= 0 && value <= 1.5, "\(scene)@\(t): \(value)")
                }
                lit = lit || out.contains { $0 > 0.85 }
            }
            XCTAssertTrue(lit, "\(scene) never lights a dot")
        }
    }

    func testEveryStateHasAClassicScene() {
        for phase in Phase.allCases where phase != .tool {
            XCTAssertNotNil(classicScenes[sceneKey(Activity(phase: phase))], phase.rawValue)
        }
        for kind in ToolKind.allCases {
            XCTAssertNotNil(classicScenes[.tool(kind)], kind.rawValue)
        }
        XCTAssertEqual(classicScenes.count, Phase.allCases.count - 1 + ToolKind.allCases.count)
    }

    func testSceneKeysFollowThePhaseAndKind() {
        XCTAssertEqual(sceneKey(.thinking), .thinking)
        XCTAssertEqual(sceneKey(Activity(phase: .tool, kind: .deploy)), .tool(.deploy))
        XCTAssertEqual(sceneKey(Activity(phase: .tool)), .tool(.generic))
    }

    func testLooksMapStatesToTheirScenes() {
        XCTAssertEqual(sceneFor(.thinking, look: .icons), .neural)
        XCTAssertEqual(sceneFor(.done, look: .icons), .verified)
        XCTAssertEqual(sceneFor(Activity(phase: .tool, kind: .search), look: .icons), .magnifier)
        XCTAssertEqual(sceneFor(Activity(phase: .tool, kind: .compute), look: .icons), .sort)
        XCTAssertEqual(sceneFor(Activity(phase: .tool, kind: .deploy), look: .icons), .rocket)
        XCTAssertEqual(sceneFor(.writing, look: .icons), .type)
        XCTAssertEqual(sceneFor(Activity(phase: .tool, kind: .code), look: .pixel), .blocks)
        XCTAssertEqual(sceneFor(Activity(phase: .tool, kind: .search), look: .pixel), .scan)
        XCTAssertEqual(sceneFor(Activity(phase: .tool, kind: .debug), look: .pixel), .bug)
        XCTAssertEqual(sceneFor(.thinking, look: .pixel), .comet)
        XCTAssertEqual(sceneFor(Activity(phase: .tool, kind: .translate)), .glyph)
        XCTAssertEqual(sceneFor(Activity(phase: .tool, kind: .debug)), .bug)
    }

    func testOverridesBeatTheLookAndTheLookBeatsClassic() {
        let search = Activity(phase: .tool, kind: .search)
        XCTAssertEqual(sceneFor(search, look: .icons, overrides: [.tool(.search): .orbit]), .orbit)
        XCTAssertEqual(sceneFor(search, look: .icons, overrides: [.thinking: .orbit]), .magnifier)
        XCTAssertEqual(sceneFor(.writing, look: .pixel, overrides: [.writing: .serpent]), .serpent)
        XCTAssertEqual(sceneFor(.idle, look: .icons), .breathe)
    }

    func testUnknownLookNamesFallBackToClassic() {
        XCTAssertEqual(Look.named("pixel"), .pixel)
        XCTAssertEqual(Look.named("sparkly"), .classic)
        XCTAssertEqual(Look.named(nil), .classic)
    }

    func testLooksCarryTheirShapeAndAura() {
        XCTAssertEqual(Look.classic.definition.shape, .dot)
        XCTAssertFalse(Look.classic.definition.aura)
        XCTAssertEqual(Look.icons.definition.shape, .dot)
        XCTAssertTrue(Look.icons.definition.aura)
        XCTAssertEqual(Look.pixel.definition.shape, .square)
        XCTAssertFalse(Look.pixel.definition.aura)
    }

    func testShapesMatchTheSpecGeometry() {
        XCTAssertEqual(DotShape.dot.geometry.size, 0.68)
        XCTAssertEqual(DotShape.dot.geometry.base, 0.14)
        XCTAssertEqual(DotShape.dot.geometry.well, 0.24)
        XCTAssertEqual(DotShape.square.geometry.size, 0.8)
        XCTAssertEqual(DotShape.square.geometry.corner, 0.22)
        XCTAssertEqual(DotShape.square.geometry.base, 0.2)
        XCTAssertEqual(DotShape.square.geometry.well, 0.14)
    }

    func testLineWalksEveryCellBetweenTwoPoints() {
        let path = GridPoint.line(GridPoint(0, 5), GridPoint(3, 3))
        XCTAssertEqual(path.first, GridPoint(0, 5))
        XCTAssertEqual(path.last, GridPoint(3, 3))
        XCTAssertEqual(path.count, 4)
    }
}
