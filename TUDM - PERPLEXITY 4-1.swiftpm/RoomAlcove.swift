import Foundation

// MARK: - RoomAlcove
//
// A generic room-level corner alcove. Spans TWO walls at a shared corner.
// Same skeleton for wood stove corners, corner fireplaces, reading nooks, corner
// bars. What lives inside is captured by the `payload` enum. Structural
// immutability contract applies: the alcove's declared geometry is the truth;
// walls REFERENCE alcoves via .alcoveOpening segments, they do not own them.

/// Which two walls a corner alcove sits between, and how far it extends along each.
///
/// The alcove is anchored at the corner shared by wallA and wallB. `footprintA`
/// is how far the alcove extends along wallA measured from that shared corner.
/// `footprintB` is the equivalent along wallB. Together they define the platform
/// footprint at the corner.
///
/// Example (Family Room wood stove):
///   wallA = Wall 3 id, footprintA = 53.5
///   wallB = Wall 4 id, footprintB = 40.75
struct AlcoveCornerAnchor: Codable, Hashable {
    var wallA: UUID
    var footprintA: Double
    var wallB: UUID
    var footprintB: Double
    
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
