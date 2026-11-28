import Foundation
import DotMindCore

struct GoldenFixture: Decodable {
    struct Frame: Decodable {
        var scene: String
        var t: Double
        var progress: Double
        var energy: Double
        var values: [Double]
    }

    struct Tool: Decodable {
        var name: String
        var kind: String
    }

    struct SceneCase: Decodable {
        var activity: Activity
        var scene: String
        var label: String
    }

    struct LookCase: Decodable {
        var activity: Activity
        var look: String
        var scene: String
        var label: String
    }

    struct EnergySample: Decodable {
        var frame: Int
        var energy: Double
        var values: [Double]
    }

    var tolerance: Double
    var frames: [Frame]
    var tools: [Tool]
    var scenes: [SceneCase]
    var looks: [LookCase]
    var energy: [EnergySample]

    static func load(filePath: String = #filePath) throws -> GoldenFixture {
        var url = URL(fileURLWithPath: filePath)
        for _ in 0..<5 { url.deleteLastPathComponent() }
        let data = try Data(contentsOf: url.appendingPathComponent("spec/golden.json"))
        return try JSONDecoder().decode(GoldenFixture.self, from: data)
    }
}
