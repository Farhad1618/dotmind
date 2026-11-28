public let classicScenes: [SceneKey: SceneName] = [
    .idle: .breathe,
    .thinking: .comet,
    .writing: .type,
    .waiting: .halo,
    .error: .cross,
    .done: .check,
    .tool(.search): .radar,
    .tool(.browse): .globe,
    .tool(.code): .code,
    .tool(.file): .pages,
    .tool(.database): .stack,
    .tool(.compute): .prism,
    .tool(.translate): .glyph,
    .tool(.deploy): .rocket,
    .tool(.debug): .bug,
    .tool(.generic): .circuit,
]

public let looks: [Look: LookDefinition] = [
    .classic: LookDefinition(),
    .icons: LookDefinition(
        scenes: [
            .thinking: .neural,
            .done: .verified,
            .tool(.search): .magnifier,
            .tool(.translate): .glyph,
            .tool(.compute): .sort,
            .tool(.deploy): .rocket,
        ],
        shape: .dot,
        aura: true
    ),
    .pixel: LookDefinition(
        scenes: [
            .tool(.debug): .bug,
            .tool(.code): .blocks,
            .tool(.search): .scan,
        ],
        shape: .square,
        aura: false
    ),
]
