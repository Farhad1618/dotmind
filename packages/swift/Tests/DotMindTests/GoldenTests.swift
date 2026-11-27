import XCTest
@testable import DotMindCore

final class GoldenTests: XCTestCase {
    private var fixture: GoldenFixture!

    override func setUpWithError() throws {
        fixture = try GoldenFixture.load()
    }

    func testEveryPatternFrameMatchesTheReference() throws {
        XCTAssertEqual(fixture.frames.count, SceneName.allCases.count * 8)
        var out = [Double](repeating: 0, count: dotCount)
        for frame in fixture.frames {
            let scene = try XCTUnwrap(SceneName(rawValue: frame.scene), frame.scene)
            scene.render(at: frame.t, into: &out, context: PatternContext(energy: frame.energy, progress: frame.progress))
            assertClose(out, frame.values, "\(frame.scene) t=\(frame.t) progress=\(frame.progress)")
        }
    }

    func testToolNamesClassifyLikeTheReference() {
        for tool in fixture.tools {
            XCTAssertEqual(classifyTool(tool.name).rawValue, tool.kind, tool.name)
        }
    }

    func testActivitiesPickTheReferenceSceneAndLabel() {
        for entry in fixture.scenes {
            XCTAssertEqual(sceneFor(entry.activity).rawValue, entry.scene, "\(entry.activity)")
            XCTAssertEqual(labelFor(entry.activity), entry.label, "\(entry.activity)")
        }
    }

    func testEnergyFollowsTheProgressRateLikeTheReference() {
        var renderer = DotRenderer(scene: .type)
        var progress = 0.0
        var samples: [(frame: Int, energy: Double, values: [Double])] = []
        renderer.feed(progress)
        for i in 0..<240 {
            renderer.step(1.0 / 60.0)
            if i < 120 {
                progress += i < 60 ? 1 : 8
                renderer.feed(progress)
            }
            if i % 20 == 19 { samples.append((i + 1, renderer.level, renderer.sample())) }
        }
        XCTAssertEqual(samples.count, fixture.energy.count)
        for (sample, expected) in zip(samples, fixture.energy) {
            XCTAssertEqual(sample.frame, expected.frame)
            XCTAssertEqual(sample.energy, expected.energy, accuracy: fixture.tolerance, "frame \(expected.frame)")
            assertClose(sample.values, expected.values, "energy frame \(expected.frame)")
        }
    }

    private func assertClose(_ actual: [Double], _ expected: [Double], _ message: String, line: UInt = #line) {
        XCTAssertEqual(actual.count, expected.count, message, line: line)
        for (index, pair) in zip(actual, expected).enumerated() where abs(pair.0 - pair.1) > fixture.tolerance {
            XCTFail("\(message) [\(index)]: \(pair.0) != \(pair.1)", line: line)
        }
    }
}
