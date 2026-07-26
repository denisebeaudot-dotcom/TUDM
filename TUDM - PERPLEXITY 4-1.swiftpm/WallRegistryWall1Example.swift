import Foundation

/// Corrected Wall 1 source of truth.
///
///     C1=8in | Z1=43in | C2=8in | Z2=12.75in | Z3A=5in | Z3B=96in | Z3C=5in | Z4=12.75in | C3=8in | Z5=39.5in | C4=8in
///     Total = 246in
///
/// Z2 and Z4 are wall returns and are never absorbed into the window unit.
/// Z3B stays 96in x 60in with a 22 / 52 / 22 panel split.
///
/// Kept in sync with `WallRegistrySync/wall_1_registry.json` and
/// `Integration/PerplexityWallPush/examples/wall1_registry_example.json`.
enum WallRegistryWall1Example {
    static let expectedTotalWidth: Double = 246

    static let lockedRules = [
        "Window Z3B is code-locked at 96in x 60in with a 22/52/22 panel split. This is enforced by WindowLockLibrary.wall1Z3B and cannot be changed at runtime.",
        "C1 and C4 terminate Wall 1. Nothing on this wall extends past them.",
        "Columns are 8in wide x 9.25in deep.",
        "Open shelves are 9.25in deep and align with the column depth.",
        "Shelves attach directly between the flanking columns. No bookcase boxes, no inset built-ins, no side panels.",
        "No base cabinets on Wall 1.",
        "Shelves read as boards, not as cabinets or bookcases.",
        "Z2 and Z4 are flush wall returns, 12.75in each, in plain plaster with no seams.",
        "Wall returns stay flat and quiet. Structures, openings, casing, and shelves never absorb a wall return.",
        "Clear wall returns beside the window remain separate locked zones and are not absorbed into the window unit.",
        "Columns read more structurally defined than the wall returns.",
        "The window carries 5in casing all around. Z3A and Z3C are its 5in vertical legs.",
        "Window frame and mullions are white.",
        "Side lights carry a grid pattern. The center window panel stays clear.",
        "Global IDs are continuous across the room.",
        "Photoreal rendering uses a persistent structural lock rule.",
        "Renderer may color, texture, shadow, and enhance lines only inside the measured framework."
    ]

    private static let shelfNote = """
    Open shelves only, 9.25in deep, aligned with the column depth. Boards attach directly \
    between the flanking columns. No bookcase box, no inset built-in, no side panels, no base cabinet.
    """

    private static let wallReturnNote = """
    Wall return, flush with the wall plane. Plain plaster, no seams. Stays flat and quiet and is \
    never absorbed into the window unit, its casing, the columns, or the shelves.
    """

    private static let casingNote = "5in casing. The window carries 5in casing all around. Painted white."

    static func make(updatedAt: Date = Date()) -> WallRegistryEnvelope {
        WallRegistryEnvelope(
            roomId: "family_room",
            wallId: "W1",
            expectedTotalWidth: expectedTotalWidth,
            updatedAt: updatedAt,
            segments: [
                .init(
                    globalId: "C1",
                    localId: "W1-C1",
                    kind: .column,
                    label: "Outer left column",
                    width: 8,
                    notes: "Terminates Wall 1 on the left. 8in wide x 9.25in deep. Reads more structurally defined than the wall returns."
                ),
                .init(
                    globalId: "Z1",
                    localId: "W1-Z1",
                    kind: .shelf,
                    label: "Left open shelf bay",
                    width: 43,
                    notes: shelfNote
                ),
                .init(
                    globalId: "C2",
                    localId: "W1-C2",
                    kind: .column,
                    label: "Inner left column",
                    width: 8,
                    notes: "8in wide x 9.25in deep. Flanks the left shelf bay and the left wall return."
                ),
                .init(
                    globalId: "Z2",
                    localId: "W1-Z2",
                    kind: .return,
                    label: "Left wall return",
                    width: 12.75,
                    notes: wallReturnNote
                ),
                .init(
                    globalId: "Z3A",
                    localId: "W1-Z3A",
                    kind: .casing,
                    label: "Left window casing",
                    width: 5,
                    notes: casingNote
                ),
                Self.wall1WindowSegment(),
                .init(
                    globalId: "Z3C",
                    localId: "W1-Z3C",
                    kind: .casing,
                    label: "Right window casing",
                    width: 5,
                    notes: casingNote
                ),
                .init(
                    globalId: "Z4",
                    localId: "W1-Z4",
                    kind: .return,
                    label: "Right wall return",
                    width: 12.75,
                    notes: wallReturnNote
                ),
                .init(
                    globalId: "C3",
                    localId: "W1-C3",
                    kind: .column,
                    label: "Inner right column",
                    width: 8,
                    notes: "8in wide x 9.25in deep. Flanks the right wall return and the right shelf bay."
                ),
                .init(
                    globalId: "Z5",
                    localId: "W1-Z5",
                    kind: .shelf,
                    label: "Right open shelf bay",
                    width: 39.5,
                    notes: shelfNote
                ),
                .init(
                    globalId: "C4",
                    localId: "W1-C4",
                    kind: .column,
                    label: "Outer right column",
                    width: 8,
                    notes: "Terminates Wall 1 on the right. 8in wide x 9.25in deep. Reads more structurally defined than the wall returns."
                )
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
    
    /// Constructs the Z3B window segment straight from the code-frozen
    /// WindowLock. This is the ONLY place in the app that writes the
    /// Z3B window's numeric values, so drift is structurally impossible
    /// unless the lock itself is edited in WindowLockLibrary.
    private static func wall1WindowSegment() -> WallRegistryEnvelope.WallSegment {
        let lock = WindowLockLibrary.wall1Z3B
        let panelString = lock.panelSplit.map { String(Int($0)) }.joined(separator: "/")
        let notes = "\(Int(lock.width))in x \(Int(lock.height))in window (code-locked, WindowLock \(lock.version)). Panel split \(panelString)in. Side lights carry a grid pattern. Center panel stays clear with no grid. Frame and mullions are white."
        return .init(
            globalId: lock.globalId,
            localId: "W1-\(lock.globalId)",
            kind: .window,
            label: "Main window unit",
            width: lock.width,
            height: lock.height,
            panelSplit: lock.panelSplit,
            notes: notes
        )
    }
}
