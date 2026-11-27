extension SceneName {
    public func render(at time: Double, into out: inout [Double], context: PatternContext) {
        precondition(out.count == Grid.cells, "dotmind patterns need a 64 value buffer")
        switch self {
        case .breathe: AmbientPatterns.breathe(time, &out)
        case .comet: AmbientPatterns.comet(time, &out)
        case .radar: ToolPatterns.radar(time, &out)
        case .globe: ToolPatterns.globe(time, &out)
        case .code: ToolPatterns.code(time, &out, context)
        case .pages: ToolPatterns.pages(time, &out)
        case .stack: ToolPatterns.stack(time, &out)
        case .prism: ToolPatterns.prism(time, &out)
        case .circuit: ToolPatterns.circuit(time, &out)
        case .type: StatusPatterns.type(time, &out, context)
        case .halo: StatusPatterns.halo(time, &out)
        case .cross: StatusPatterns.cross(time, &out)
        case .check: StatusPatterns.check(time, &out)
        case .ember: AmbientPatterns.ember(time, &out)
        case .orbit: AmbientPatterns.orbit(time, &out)
        case .serpent: AmbientPatterns.serpent(time, &out)
        case .pulse: AmbientPatterns.pulse(time, &out)
        }
    }

    func render(at time: Double, context: PatternContext) -> [Double] {
        var out = [Double](repeating: 0, count: Grid.cells)
        render(at: time, into: &out, context: context)
        return out
    }
}

public let dotGridSide = Grid.side
public let dotCount = Grid.cells
