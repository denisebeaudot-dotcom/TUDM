import Foundation

// MARK: - LockedWall

/// A read-only projection of a WallSpec.
///
/// Purpose (G1 — structural immutability contract):
/// - WallSpec is the mutable model that lives in the store and is edited by
///   WallFormView. Every other consumer of a wall (elevation builder, RealityKit
///   scene, worksheet, render frame exporter, registry bridge, push view) only
///   ever needs to READ wall data. If any of those consumers accidentally
///   mutated wall structure, the immutability contract would be broken silently.
/// - LockedWall exposes every field of WallSpec as a get-only computed
///   property. No setters. No mutating methods. Callers cannot change structural
///   data through this type at compile time.
/// - Build one with `wallSpec.locked`. That is the only entry point.
///
/// If a downstream reader needs a field that isn't exposed here, add it as a
/// get-only computed property. Never add a setter.
struct LockedWall: Identifiable, Hashable {
    private let wall: WallSpec
    
    fileprivate init(_ wall: WallSpec) {
        self.wall = wall
    }
    
    // MARK: Identity
    
    var id: UUID { wall.id }
    
    // MARK: Metadata
    
    var name: String { wall.name }
    var ruleSet: String { wall.ruleSet }
    var notes: String { wall.notes }
    
    // MARK: Structural dimensions
    
    var totalWidth: Double { wall.totalWidth }
    var segments: [WallSegment] { wall.segments }
    
    // MARK: Chain shorthand (derived from segments on save)
    
    var chainString: String { wall.chainString }
    var verticalChainString: String { wall.verticalChainString }
    
    // MARK: Overrides
    
    var usesOverrides: Bool { wall.usesOverrides }
    var overrides: RoomDefaults? { wall.overrides }
    
    // MARK: Lock state
    
    /// When true, this wall's structural data is permanently locked. Consumers
    /// that intend to mutate a WallSpec should refuse to touch it unless a
    /// deliberate unlock has been performed. LockedWall itself is always
    /// read-only regardless of this flag; the flag is a data-level assertion
    /// carried alongside the wall so it survives round-trip through JSON.
    var isLocked: Bool { wall.isLocked }
    
    // MARK: Mirrored computed properties
    
    /// Sum of segment widths. Should equal totalWidth for a valid wall.
    var segmentTotal: Double { wall.segmentTotal }
    
    /// True when segments sum to totalWidth within tolerance.
    var matchesTotalWidth: Bool { wall.matchesTotalWidth }
}

// MARK: - WallSpec bridge

extension WallSpec {
    /// The read-only projection of this wall. Use this to pass a wall to any
    /// consumer that only needs to read structural data.
    ///
    /// Legitimate mutation of a WallSpec goes through
    /// `InteriorAuthorityStore.updateWall(...)` from `WallFormView`.
    /// All other call sites should take `LockedWall`.
    var locked: LockedWall { LockedWall(self) }
}
