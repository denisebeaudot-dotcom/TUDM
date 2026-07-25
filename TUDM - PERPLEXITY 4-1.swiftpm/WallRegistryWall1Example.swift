import Foundation

/// Corrected Wall 1 source of truth.
///
///     C1=8in | Z1=43in | C2=8in | Z2=12.75in | Z3A=5in | Z3B=96in | Z3C=5in | Z4=12.75in | C3=8in | Z5=39.5in | C4=8in
///     Total = 246in
///
/// Z2 and Z4 are clear wall returns and are never absorbed into the window unit.
/// Z3B stays 96in x 60in with a 22 / 52 / 22 panel split.
///
/// Kept in sync with `Integration/PerplexityWallPush/examples/wall1_registry_example.json`.
enum WallRegistryWall1Example {
    static let expectedTotalWidth: Double = 246

    static let lockedRules = [
        "Clear wall returns beside the window remain separate locked zones and are not absorbed into the window unit.",
        "Global IDs are continuous across the room.",
        "Photoreal rendering uses a persistent structural lock rule.",
        "Renderer may color, texture, shadow, and enhance lines only inside the measured framework."
    ]

    static func make(updatedAt: Date = Date()) -> WallRegistryEnvelope {
        WallRegistryEnvelope(
            roomId: "family_room",
            wallId: "W1",
            expectedTotalWidth: expectedTotalWidth,
            updatedAt: updatedAt,
            segments: [
                .init(globalId: "C1", localId: "W1-C1", kind: .column, label: "Outer left column", width: 8),
                .init(globalId: "Z1", localId: "W1-Z1", kind: .bookcase, label: "Left bookcase bay", width: 43),
                .init(globalId: "C2", localId: "W1-C2", kind: .column, label: "Inner left column", width: 8),
                .init(
                    globalId: "Z2",
                    localId: "W1-Z2",
                    kind: .return,
                    label: "Left clear wall return",
                    width: 12.75,
                    notes: "Must remain clear and separate from the window unit."
                ),
                .init(globalId: "Z3A", localId: "W1-Z3A", kind: .casing, label: "Left window casing/trim", width: 5),
                .init(
                    globalId: "Z3B",
                    localId: "W1-Z3B",
                    kind: .window,
                    label: "Main window unit",
                    width: 96,
                    height: 60,
                    panelSplit: [22, 52, 22],
                    notes: "Center panel clear/no mullions. Side panels use vertical mullions only."
                ),
                .init(globalId: "Z3C", localId: "W1-Z3C", kind: .casing, label: "Right window casing/trim", width: 5),
                .init(
                    globalId: "Z4",
                    localId: "W1-Z4",
                    kind: .return,
                    label: "Right clear wall return",
                    width: 12.75,
                    notes: "Must remain clear and separate from the window unit."
                ),
                .init(globalId: "C3", localId: "W1-C3", kind: .column, label: "Inner right column", width: 8),
                .init(globalId: "Z5", localId: "W1-Z5", kind: .bookcase, label: "Right bookcase bay", width: 39.5),
                .init(globalId: "C4", localId: "W1-C4", kind: .column, label: "Outer right column", width: 8)
            ],
            vertical: VerticalReferences(
                ceilingHeight: 96,
                beamBottom: 88,
                beamZoneHeight: 8,
                sillOrBaseReference: 20,
                windowHead: 80,
                headerTop: 85
            ),
            rules: lockedRules
        )
    }
}
