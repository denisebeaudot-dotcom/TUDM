import Foundation

// MARK: - LockedAlcove

/// A read-only projection of a RoomAlcove. Mirrors the LockedWall pattern (G1):
/// downstream consumers that only read alcove data should take this type so
/// mutation is impossible at compile time.
///
/// Build one with `alcove.locked`. That is the only entry point.
struct LockedAlcove: Identifiable, Hashable {
    private let alcove: RoomAlcove
    
    fileprivate init(_ alcove: RoomAlcove) {
        self.alcove = alcove
    }
    
    // MARK: Identity
    
    var id: UUID { alcove.id }
    
    // MARK: Metadata
    
    var name: String { alcove.name }
    var notes: String { alcove.notes }
    
    // MARK: Structural anchors
    
    var anchor: AlcoveCornerAnchor { alcove.anchor }
    var platform: AlcovePlatform { alcove.platform }
    var columnA: AlcoveColumnSpec { alcove.columnA }
    var columnB: AlcoveColumnSpec { alcove.columnB }
    var back: AlcoveBackSpec { alcove.back }
    var payload: AlcovePayload { alcove.payload }
    
    // MARK: Lock state
    
    /// Same semantics as WallSpec.isLocked (G5). Downstream editors should
    /// refuse to mutate a locked alcove without a deliberate unlock.
    var isLocked: Bool { alcove.isLocked }
}

// MARK: - RoomAlcove bridge

extension RoomAlcove {
    /// The read-only projection of this alcove. Pass this to any consumer that
    /// only needs to read alcove data (elevation builder, RealityKit scene,
    /// worksheet, registry bridge, render frame exporter).
    ///
    /// Legitimate mutation goes through InteriorAuthorityStore.updateAlcove(...).
    /// All other call sites should take `LockedAlcove`.
    var locked: LockedAlcove { LockedAlcove(self) }
}
