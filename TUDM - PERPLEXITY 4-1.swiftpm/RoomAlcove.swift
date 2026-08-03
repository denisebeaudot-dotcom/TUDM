// ============================================================
// DENISEBEAUDOT — BUILD MARKER — alcove bump-out + point C
// 2026-08-03 18:27 EDT   branch: alcove-bumpout-point-c
// If you cannot see this line at the very top, this file did
// not load or the paste was truncated.
// ============================================================

import Foundation

// MARK: - RoomAlcove
//
// A generic room-level corner alcove. Spans TWO walls at a shared corner.
// Same skeleton for wood stove corners, corner fireplaces, reading nooks, corner
// bars. What lives inside is captured by the `payload` enum. Structural
// immutability contract applies: the alcove's declared geometry is the truth;
// walls REFERENCE alcoves via .alcoveOpening segments, they do not own them.

/// Which side of the host walls an alcove body occupies.
///
/// An INWARD alcove is a recess carved out of the room — it removes floor area
/// and both legs are measured inside the envelope.
///
/// An OUTWARD alcove is a bump-out. The body is tacked onto the far side of one
/// host wall, it ADDS floor area, and the host wall's segment across the
/// opening is removed. The room outline becomes an L. The leg on the other wall
/// is that wall's extension past the shared corner, not a run inside the room.
enum AlcoveProjection: String, Codable, Hashable, CaseIterable {
    /// Recess into the room. Original behaviour.
    case inward
    /// Bump-out through wallA. The wallA segment across the opening is removed.
    case outwardThroughWallA
    /// Bump-out through wallB. The wallB segment across the opening is removed.
    case outwardThroughWallB
    
    var label: String {
        switch self {
        case .inward: return "Recess (into room)"
        case .outwardThroughWallA: return "Bump-out through Wall A"
        case .outwardThroughWallB: return "Bump-out through Wall B"
        }
    }
    
    /// True when the alcove adds floor area rather than removing it.
    var isBumpOut: Bool { self != .inward }
    
    /// For a bump-out, whether wallA is the host wall being opened.
    /// Nil for an inward recess, which opens no wall.
    var hostWallIsA: Bool? {
        switch self {
        case .inward: return nil
        case .outwardThroughWallA: return true
        case .outwardThroughWallB: return false
        }
    }
}

/// Which two walls a corner alcove sits between, and how far it extends along each.
///
/// The alcove is anchored at the corner shared by wallA and wallB. `footprintA`
/// is how far the alcove extends along wallA measured from that shared corner.
/// `footprintB` is the equivalent along wallB. Together they define the platform
/// footprint at the corner.
///
/// Example (Family Room wood stove, inward recess):
///   wallA = Wall 3 id, footprintA = 53.5
///   wallB = Wall 4 id, footprintB = 40.75
///
/// Example (Ina's Room bump-out through W3):
///   wallA = Wall 3 id, footprintA = 26.0
///   wallB = Wall 4 id, footprintB = 15.0
///   backWallC = 26.0, projection = .outwardThroughWallA
struct AlcoveCornerAnchor: Codable, Hashable {
    var wallA: UUID
    var footprintA: Double
    var wallB: UUID
    var footprintB: Double
    
    /// Step 7c — the declared BACK WALL length (point C), in inches.
    ///
    /// C starts at the endpoint of the LONGER of the two legs and runs
    /// perpendicular to that wall. Its far end is the derived third point D.
    /// The footprint then closes as the quadrilateral O -> A -> D -> B.
    /// See AlcovePlanGeometry.swift for the full rule.
    ///
    /// `nil` means the back wall has not been measured yet. Every consumer
    /// treats nil as "fall back to the short leg", which reproduces the plain
    /// rectangular footprint the app drew before point C existed — so locked
    /// alcoves authored earlier are never silently re-drawn. Declaring a C is
    /// always an explicit, deliberate act.
    var backWallC: Double? = nil
    
    /// Which side of the host walls the alcove body sits on.
    ///
    /// `.inward` is the original behaviour: the alcove eats into the room, like
    /// the family-room wood stove corner. `.outwardThroughWallA` / `.WallB` are
    /// bump-outs — the body is tacked onto the OUTSIDE of the named wall and
    /// adds floor area. In a bump-out the host wall's segment across the
    /// opening is removed, and the other leg is that wall's extension past the
    /// shared corner.
    ///
    /// Defaults to `.inward` so every alcove authored before bump-outs existed
    /// keeps its current geometry.
    var projection: AlcoveProjection = .inward
    
    /// How far along the host wall the opening starts, measured from the anchor
    /// end, in inches. Zero — the default — pins the alcove to the shared
    /// corner, which is the original behaviour.
    ///
    /// A positive offset floats the alcove out into the middle of the host wall.
    /// The body then has wall on BOTH sides of the opening, and the leg on the
    /// other wall stops being a run along that wall: it becomes a free side
    /// return. `isFloating` reports which case you are in.
    ///
    /// Only meaningful for bump-outs, which have a single host wall. An inward
    /// corner recess ignores it.
    var openingOffset: Double = 0
    
    /// Which end of each wall the anchor sits at. A wall runs left→right in its
    /// own coordinates; a corner alcove terminates at one end. `.corner` means
    /// the platform touches the far-right end of the wall (station = totalWidth);
    /// `.origin` means the platform touches the far-left end (station = 0).
    var anchorA: WallEnd = .corner
    var anchorB: WallEnd = .corner
    
    enum WallEnd: String, Codable, Hashable {
        case origin
        case corner
    }
    
    init(
        wallA: UUID,
        footprintA: Double,
        wallB: UUID,
        footprintB: Double,
        backWallC: Double? = nil,
        projection: AlcoveProjection = .inward,
        openingOffset: Double = 0,
        anchorA: WallEnd = .corner,
        anchorB: WallEnd = .corner
    ) {
        self.wallA = wallA
        self.footprintA = footprintA
        self.wallB = wallB
        self.footprintB = footprintB
        self.backWallC = backWallC
        self.projection = projection
        self.openingOffset = openingOffset
        self.anchorA = anchorA
        self.anchorB = anchorB
    }
    
    enum CodingKeys: String, CodingKey {
        case wallA, footprintA, wallB, footprintB, backWallC, projection, openingOffset, anchorA, anchorB
    }
    
    /// Explicit decode so anchors written before point C existed still load.
    /// Every optional-or-defaulted key goes through decodeIfPresent; only the
    /// two wall references and two footprints are genuinely required.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.wallA = try c.decode(UUID.self, forKey: .wallA)
        self.footprintA = try c.decode(Double.self, forKey: .footprintA)
        self.wallB = try c.decode(UUID.self, forKey: .wallB)
        self.footprintB = try c.decode(Double.self, forKey: .footprintB)
        self.backWallC = try c.decodeIfPresent(Double.self, forKey: .backWallC)
        self.projection = try c.decodeIfPresent(AlcoveProjection.self, forKey: .projection) ?? .inward
        self.openingOffset = try c.decodeIfPresent(Double.self, forKey: .openingOffset) ?? 0
        self.anchorA = try c.decodeIfPresent(WallEnd.self, forKey: .anchorA) ?? .corner
        self.anchorB = try c.decodeIfPresent(WallEnd.self, forKey: .anchorB) ?? .corner
    }
    
    /// Encode C only when it has been declared, so untouched alcoves keep a
    /// byte-identical JSON shape and diffs stay readable.
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(wallA, forKey: .wallA)
        try c.encode(footprintA, forKey: .footprintA)
        try c.encode(wallB, forKey: .wallB)
        try c.encode(footprintB, forKey: .footprintB)
        try c.encodeIfPresent(backWallC, forKey: .backWallC)
        // Only write projection when it departs from the default, so untouched
        // inward alcoves keep a byte-identical JSON shape.
        if projection != .inward {
            try c.encode(projection, forKey: .projection)
        }
        if openingOffset != 0 {
            try c.encode(openingOffset, forKey: .openingOffset)
        }
        try c.encode(anchorA, forKey: .anchorA)
        try c.encode(anchorB, forKey: .anchorB)
    }
}

// MARK: - Platform

enum PlatformShape: String, CaseIterable, Codable, Hashable {
    case flatRectangular = "Flat Rectangular"
    case convexCurvedFront = "Convex Curved Front"
    case concaveCurvedFront = "Concave Curved Front"
    case chamferedCorners = "Chamfered Corners"
}

struct AlcovePlatform: Codable, Hashable {
    /// Height of the platform above finish floor, in inches.
    var height: Double = 12
    var shape: PlatformShape = .flatRectangular
    var material: AlcoveMaterial = .redBrick
}

// MARK: - Columns

/// One of the flanking columns of a corner alcove. In the wood stove case, this
/// is SC9 or SC10. Columns stand ON the platform at the inboard end of the
/// alcove's declared footprint on each wall.
struct AlcoveColumnSpec: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var label: String = ""
    var width: Double = 8
    var depth: Double = 9.25
    var height: Double = 84
    var material: AlcoveMaterial = .redBrick
    var notes: String = ""
}

// MARK: - Back element

enum BackElementStyle: String, CaseIterable, Codable, Hashable {
    case concaveCurved = "Concave Curved"
    case convexCurved = "Convex Curved"
    case flat = "Flat"
    case mitered = "Mitered"
}

/// The back surface between the two flanking columns. In the wood stove case,
/// a concave curved feed-brick wall arcing between SC9's outer face and SC10's
/// outer face. Spans exactly the distance between the columns; no wrap-around.
struct AlcoveBackSpec: Codable, Hashable {
    var style: BackElementStyle = .concaveCurved
    var height: Double = 84
    var material: AlcoveMaterial = .feedBrick
    var notes: String = ""
}

// MARK: - Material

enum AlcoveMaterial: String, CaseIterable, Codable, Hashable {
    case redBrick = "Red Brick"
    case feedBrick = "Feed Brick"
    case naturalStone = "Natural Stone"
    case paintedDrywall = "Painted Drywall"
    case wood = "Wood"
    case tile = "Tile"
    case other = "Other"
}

// MARK: - Payload

/// What lives inside the alcove. Each case carries only the fields that make
/// sense for that payload type. Add new cases as new alcove types are needed
/// (fireplace insert, seating nook, corner bar) — not before.
enum AlcovePayload: Codable, Hashable {
    case empty
    case woodStove(WoodStoveSpec)
    
    // Discriminator for Codable
    private enum PayloadKind: String, Codable {
        case empty
        case woodStove
    }
    
    private enum CodingKeys: String, CodingKey {
        case kind
        case woodStove
    }
    
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let kind = try c.decodeIfPresent(PayloadKind.self, forKey: .kind) ?? .empty
        switch kind {
        case .empty:
            self = .empty
        case .woodStove:
            let spec = try c.decodeIfPresent(WoodStoveSpec.self, forKey: .woodStove) ?? WoodStoveSpec()
            self = .woodStove(spec)
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .empty:
            try c.encode(PayloadKind.empty, forKey: .kind)
        case .woodStove(let spec):
            try c.encode(PayloadKind.woodStove, forKey: .kind)
            try c.encode(spec, forKey: .woodStove)
        }
    }
}

struct WoodStoveSpec: Codable, Hashable {
    var modelName: String = ""
    var manufacturer: String = ""
    var stoveWidth: Double = 24
    var stoveDepth: Double = 22
    var stoveHeight: Double = 32
    var flueDiameter: Double = 6
    var clearanceRating: String = ""   // e.g. "12in rear, 18in side"
    var hearthExtension: Double = 16   // required non-combustible pad projection in front
    var notes: String = ""
}

// MARK: - RoomAlcove

struct RoomAlcove: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String = ""
    var notes: String = ""
    
    /// Which two walls this alcove sits between, and how far it extends along each.
    var anchor: AlcoveCornerAnchor
    
    var platform: AlcovePlatform = AlcovePlatform()
    var columnA: AlcoveColumnSpec = AlcoveColumnSpec(label: "Column A")
    var columnB: AlcoveColumnSpec = AlcoveColumnSpec(label: "Column B")
    var back: AlcoveBackSpec = AlcoveBackSpec()
    var payload: AlcovePayload = .empty
    
    /// Same immutability signal as WallSpec.isLocked (G5). Once a real alcove is
    /// modeled, mark it locked so later editors and the render pipeline treat
    /// its geometry as ground truth.
    var isLocked: Bool = false
    
    init(
        id: UUID = UUID(),
        name: String = "",
        notes: String = "",
        anchor: AlcoveCornerAnchor,
        platform: AlcovePlatform = AlcovePlatform(),
        columnA: AlcoveColumnSpec = AlcoveColumnSpec(label: "Column A"),
        columnB: AlcoveColumnSpec = AlcoveColumnSpec(label: "Column B"),
        back: AlcoveBackSpec = AlcoveBackSpec(),
        payload: AlcovePayload = .empty,
        isLocked: Bool = false
    ) {
        self.id = id
        self.name = name
        self.notes = notes
        self.anchor = anchor
        self.platform = platform
        self.columnA = columnA
        self.columnB = columnB
        self.back = back
        self.payload = payload
        self.isLocked = isLocked
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name, notes, anchor, platform, columnA, columnB, back, payload, isLocked
    }
    
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.name = try c.decodeIfPresent(String.self, forKey: .name) ?? ""
        self.notes = try c.decodeIfPresent(String.self, forKey: .notes) ?? ""
        self.anchor = try c.decode(AlcoveCornerAnchor.self, forKey: .anchor)
        self.platform = try c.decodeIfPresent(AlcovePlatform.self, forKey: .platform) ?? AlcovePlatform()
        self.columnA = try c.decodeIfPresent(AlcoveColumnSpec.self, forKey: .columnA) ?? AlcoveColumnSpec(label: "Column A")
        self.columnB = try c.decodeIfPresent(AlcoveColumnSpec.self, forKey: .columnB) ?? AlcoveColumnSpec(label: "Column B")
        self.back = try c.decodeIfPresent(AlcoveBackSpec.self, forKey: .back) ?? AlcoveBackSpec()
        self.payload = try c.decodeIfPresent(AlcovePayload.self, forKey: .payload) ?? .empty
        self.isLocked = try c.decodeIfPresent(Bool.self, forKey: .isLocked) ?? false
    }
}
