import Foundation

// MARK: - Project / Room / Wall Models

struct Project: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var clientName: String
    var location: String
    var notes: String
    var rooms: [Room]
    /// Free-text notes per design-process phase, keyed by DesignPhase.rawValue.
    /// Optional so old projects decoded from JSON without this field still work.
    var phaseNotes: [String: String]?
    
    init(
        id: UUID = UUID(),
        name: String = "",
        clientName: String = "",
        location: String = "",
        notes: String = "",
        rooms: [Room] = [],
        phaseNotes: [String: String]? = nil
    ) {
        self.id = id
        self.name = name
        self.clientName = clientName
        self.location = location
        self.notes = notes
        self.rooms = rooms
        self.phaseNotes = phaseNotes
    }
}

struct Room: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var notes: String
    var defaults: RoomDefaults
    var wallSpecs: [WallSpec]
    var beams: [RoomBeam]
    /// Step 7 — room-level corner alcoves (wood stove, corner fireplace, nook, bar).
    /// Alcoves are first-class room children; walls reference them via .alcoveOpening segments.
    var alcoves: [RoomAlcove]
    
    init(
        id: UUID = UUID(),
        name: String = "",
        notes: String = "",
        defaults: RoomDefaults = .rgrstDefaults,
        wallSpecs: [WallSpec] = [],
        beams: [RoomBeam] = [],
        alcoves: [RoomAlcove] = []
    ) {
        self.id = id
        self.name = name
        self.notes = notes
        self.defaults = defaults
        self.wallSpecs = wallSpecs
        self.beams = beams
        self.alcoves = alcoves
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name, notes, defaults, wallSpecs, beams, alcoves
    }
    
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.name = try c.decodeIfPresent(String.self, forKey: .name) ?? ""
        self.notes = try c.decodeIfPresent(String.self, forKey: .notes) ?? ""
        self.defaults = try c.decodeIfPresent(RoomDefaults.self, forKey: .defaults) ?? .rgrstDefaults
        self.wallSpecs = try c.decodeIfPresent([WallSpec].self, forKey: .wallSpecs) ?? []
        self.beams = try c.decodeIfPresent([RoomBeam].self, forKey: .beams) ?? []
        self.alcoves = try c.decodeIfPresent([RoomAlcove].self, forKey: .alcoves) ?? []
    }
}

struct WallSpec: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var totalWidth: Double
    var ruleSet: String
    var notes: String
    
    /// Shorthand *derived from* `segments`. Rebuilt on every save via
    /// `ChainTokenTable.chainString(for:)`, so it can never describe a wall the segments do not.
    /// Treat it as display/entry sugar, never as input to rendering.
    var chainString: String
    var verticalChainString: String

    /// The authoritative wall description. Elevations, the 3D preview, the worksheet, the manifest,
    /// and the Perplexity registry payload are all built from this list.
    var segments: [WallSegment]

    var usesOverrides: Bool
    var overrides: RoomDefaults?
    
    /// When true, this wall's structural data is permanently locked. LockedWall
    /// respects this flag; mutation attempts should be treated as programmer
    /// error. Seed walls that represent real construction (e.g. Wall 1) set this
    /// to true so the alcove subsystem and future editors can't accidentally
    /// mutate them.
    var isLocked: Bool = false
    
    init(
        id: UUID = UUID(),
        name: String = "",
        totalWidth: Double = 246,
        ruleSet: String = "RGRST",
        notes: String = "",
        chainString: String = "",
        verticalChainString: String = "",
        segments: [WallSegment] = [],
        usesOverrides: Bool = false,
        overrides: RoomDefaults? = nil,
        isLocked: Bool = false
    ) {
        self.id = id
        self.name = name
        self.totalWidth = totalWidth
        self.ruleSet = ruleSet
        self.notes = notes
        self.chainString = chainString
        self.verticalChainString = verticalChainString
        self.segments = segments
        self.usesOverrides = usesOverrides
        self.overrides = overrides
        self.isLocked = isLocked
    }
    
    var segmentTotal: Double {
        segments.reduce(0) { $0 + $1.resolvedWidth }
    }
    
    var matchesTotalWidth: Bool {
        abs(segmentTotal - totalWidth) < 0.01
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name, totalWidth, ruleSet, notes
        case chainString, verticalChainString
        case segments, usesOverrides, overrides, isLocked
    }
    
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.name = try c.decodeIfPresent(String.self, forKey: .name) ?? ""
        self.totalWidth = try c.decodeIfPresent(Double.self, forKey: .totalWidth) ?? 246
        self.ruleSet = try c.decodeIfPresent(String.self, forKey: .ruleSet) ?? "RGRST"
        self.notes = try c.decodeIfPresent(String.self, forKey: .notes) ?? ""
        self.chainString = try c.decodeIfPresent(String.self, forKey: .chainString) ?? ""
        self.verticalChainString = try c.decodeIfPresent(String.self, forKey: .verticalChainString) ?? ""
        self.segments = try c.decodeIfPresent([WallSegment].self, forKey: .segments) ?? []
        self.usesOverrides = try c.decodeIfPresent(Bool.self, forKey: .usesOverrides) ?? false
        self.overrides = try c.decodeIfPresent(RoomDefaults.self, forKey: .overrides)
        self.isLocked = try c.decodeIfPresent(Bool.self, forKey: .isLocked) ?? false
    }
}

// MARK: - Structure Defaults

struct RoomDefaults: Codable, Hashable {
    var ceilingHeight: Double
    var crownHeight: Double
    var baseboardHeight: Double
    var beamHeight: Double
    var beamRangeAFF: String
    var columnWidth: Double
    var columnDepth: Double
    var columnHeight: Double
    
    static let rgrstDefaults = RoomDefaults(
        ceilingHeight: 120,
        crownHeight: 6,
        baseboardHeight: 8,
        beamHeight: 12,
        beamRangeAFF: "96-108",
        columnWidth: 12,
        columnDepth: 6,
        columnHeight: 120
    )
}

// MARK: - Segment Kinds

enum SegmentKind: String, CaseIterable, Codable, Hashable {
    case wall = "Wall"
    case wallSpace = "Wall Space"
    case returnZone = "Return Zone"
    case column = "Column"
    case bookcase = "Bookcase"
    case shelf = "Shelf"
    case beam = "Beam"
    case casing = "Casing"
    case trim = "Trim"
    case baseboard = "Baseboard"
    case crown = "Crown"
    case windowUnit = "Window Unit"
    case door = "Door"
    case opening = "Opening"
    // Step 7 — a station range on this wall is claimed by a room-level alcove.
    // The alcove itself lives on Room.alcoves and is referenced via WallSegment.alcoveRef.
    case alcoveOpening = "Alcove Opening"
}

// MARK: - Openings

enum OpeningCategory: String, CaseIterable, Codable, Hashable {
    case window = "Window"
    case door = "Door"
    case generic = "Generic"
}

enum WindowStyle: String, CaseIterable, Codable, Hashable {
    case picture = "Picture"
    case casement = "Casement"
    case doubleHung = "Double Hung"
    case singleHung = "Single Hung"
    case awning = "Awning"
    case hopper = "Hopper"
    case slider = "Slider"
    case fixed = "Fixed"
    case bay = "Bay"
    case bow = "Bow"
    case arched = "Arched"
    case transom = "Transom"
    case clerestory = "Clerestory"
    case tilt = "Tilt"
    case jalousie = "Jalousie"
    case custom = "Custom"
}

enum DoorStyle: String, CaseIterable, Codable, Hashable {
    case single = "Single"
    case double = "Double"
    case pocket = "Pocket"
    case cased = "Cased"
    case sliding = "Sliding"
    case french = "French"
    case bifold = "Bifold"
    case barn = "Barn"
    case dutch = "Dutch"
}

enum OpeningHanding: String, CaseIterable, Codable, Hashable {
    case none = "None"
    case left = "Left"
    case right = "Right"
    case center = "Center"
}

enum WindowGlazing: String, CaseIterable, Codable, Hashable {
    case single = "Single"
    case double = "Double"
    case triple = "Triple"
    case tempered = "Tempered"
    case laminated = "Laminated"
    case obscure = "Obscure"
    case leaded = "Leaded"
    case stained = "Stained"
}

enum WindowFrameMaterial: String, CaseIterable, Codable, Hashable {
    case wood = "Wood"
    case vinyl = "Vinyl"
    case aluminum = "Aluminum"
    case fiberglass = "Fiberglass"
    case clad = "Clad"
    case steel = "Steel"
    case composite = "Composite"
}

enum PanelOperation: String, CaseIterable, Codable, Hashable {
    case fixed = "Fixed"
    case operable = "Operable"
    case casementLeft = "Casement L"
    case casementRight = "Casement R"
    case awning = "Awning"
    case hopper = "Hopper"
    case slidingLeft = "Sliding L"
    case slidingRight = "Sliding R"
    case doubleHungUpper = "DH Upper"
    case doubleHungLower = "DH Lower"
}

enum MullionLayoutPreset: String, CaseIterable, Codable, Hashable {
    case none = "None"
    case grid = "Grid"
    case custom = "Custom"
}

// A single vertical panel/lite within a window unit.
struct WindowPanel: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var label: String = ""
    var widthShare: Double = 1     // relative share within the unit (unitless)
    var operation: PanelOperation = .fixed
    // Muntin grid inside this panel: number of horizontal muntins and vertical muntins.
    var muntinRows: Int = 0        // horizontal bars → rows of lites
    var muntinCols: Int = 0        // vertical bars → columns of lites
    // When true, the unit-level muntin pattern (opening.muntinsRows × opening.muntinsCols)
    // is applied inside this specific panel. Off means clear glass.
    var hasMuntinGrid: Bool = true
    // When true, mullions may appear on this panel's edges (adjacency rule: a mullion is
    // drawn between two panels only if BOTH panels have hasMullions == true).
    var hasMullions: Bool = true
    
    init(
        id: UUID = UUID(),
        label: String = "",
        widthShare: Double = 1,
        operation: PanelOperation = .fixed,
        muntinRows: Int = 0,
        muntinCols: Int = 0,
        hasMuntinGrid: Bool = true,
        hasMullions: Bool = true
    ) {
        self.id = id
        self.label = label
        self.widthShare = widthShare
        self.operation = operation
        self.muntinRows = muntinRows
        self.muntinCols = muntinCols
        self.hasMuntinGrid = hasMuntinGrid
        self.hasMullions = hasMullions
    }
    
    enum CodingKeys: String, CodingKey {
        case id, label, widthShare, operation, muntinRows, muntinCols, hasMuntinGrid, hasMullions, hasLeftMullion, hasRightMullion
    }
    
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.label = try c.decodeIfPresent(String.self, forKey: .label) ?? ""
        self.widthShare = try c.decodeIfPresent(Double.self, forKey: .widthShare) ?? 1
        self.operation = try c.decodeIfPresent(PanelOperation.self, forKey: .operation) ?? .fixed
        self.muntinRows = try c.decodeIfPresent(Int.self, forKey: .muntinRows) ?? 0
        self.muntinCols = try c.decodeIfPresent(Int.self, forKey: .muntinCols) ?? 0
        self.hasMuntinGrid = try c.decodeIfPresent(Bool.self, forKey: .hasMuntinGrid) ?? true
        // Migrate from old per-side toggles: if either side was true, treat this panel as mullions ON.
        let hasMullionsDirect = try c.decodeIfPresent(Bool.self, forKey: .hasMullions)
        let legacyLeft = try c.decodeIfPresent(Bool.self, forKey: .hasLeftMullion)
        let legacyRight = try c.decodeIfPresent(Bool.self, forKey: .hasRightMullion)
        if let direct = hasMullionsDirect {
            self.hasMullions = direct
        } else if legacyLeft != nil || legacyRight != nil {
            self.hasMullions = (legacyLeft ?? true) || (legacyRight ?? true)
        } else {
            self.hasMullions = true
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(label, forKey: .label)
        try c.encode(widthShare, forKey: .widthShare)
        try c.encode(operation, forKey: .operation)
        try c.encode(muntinRows, forKey: .muntinRows)
        try c.encode(muntinCols, forKey: .muntinCols)
        try c.encode(hasMuntinGrid, forKey: .hasMuntinGrid)
        try c.encode(hasMullions, forKey: .hasMullions)
    }
}

struct OpeningSpec: Codable, Hashable {
    // Core category
    var category: OpeningCategory = .window
    var windowStyle: WindowStyle? = .picture
    var doorStyle: DoorStyle? = nil
    
    // Rough opening dimensions and placement
    var openingWidth: Double = 48
    var openingHeight: Double = 48
    var sillOrBottomAFF: Double = 24
    
    // Casing (trim around the outside of the unit)
    var casingLeft: Double = 3
    var casingRight: Double = 3
    var casingHead: Double = 3
    var casingBottom: Double = 3      // NEW: bottom casing / base trim below the unit
    var casingWidth: Double = 3.5     // face width of the casing profile
    var topCasingIsCrown: Bool = false
    var wallSpaceAboveUnit: Double = 0
    
    // Panels & subdivisions
    var panelCount: Int = 1
    var mullionsVertical: Int = 0      // vertical dividers between panels
    var mullionsHorizontal: Int = 0    // horizontal dividers (e.g. transom bar)
    var mullionWidth: Double = 2       // face width of each mullion
    var muntinsRows: Int = 0           // grid inside each panel (rows of lites)
    var muntinsCols: Int = 0           // grid inside each panel (cols of lites)
    var muntinWidth: Double = 0.75     // face width of each muntin bar
    var panels: [WindowPanel] = []     // optional per-panel overrides
    var mullionLayoutPreset: MullionLayoutPreset = .grid  // how mullions are placed
    // Per-seam mullion On/Off. For N panels there are N-1 seams; index i is between panel i and panel i+1.
    // If empty (legacy data) the renderer falls back to the per-panel hasMullions adjacency rule.
    var mullionSeams: [Bool] = []
    
    // Frame & material
    var frameWidth: Double = 2         // face width of the outer frame
    var jambDepth: Double = 4.5        // depth of jamb into wall
    var frameMaterial: WindowFrameMaterial = .wood
    var glazing: WindowGlazing = .double
    
    // Sill / stool / apron (mostly for window elevations)
    var sillProjection: Double = 1.5   // how far the exterior sill projects
    var interiorStoolProjection: Double = 1
    var apronHeight: Double = 3        // trim below the stool
    
    // Egress / performance / metadata
    var isEgress: Bool = false
    var hasScreens: Bool = false
    var uFactor: Double = 0
    var shgc: Double = 0
    var manufacturer: String = ""
    var modelNumber: String = ""
    
    // Door-specific extras (kept alongside so we don't need a second struct)
    var projectionDepth: Double = 0    // for bay/bow/oriel, or door swing depth
    var handing: OpeningHanding = .none
    var thresholdHeight: Double = 0
    
    var notes: String = ""
    
    var resolvedSegmentWidth: Double {
        openingWidth + casingLeft + casingRight
    }
    
    // MARK: Codable — tolerant of older saved data
    
    enum CodingKeys: String, CodingKey {
        case category, windowStyle, doorStyle
        case openingWidth, openingHeight, sillOrBottomAFF
        case casingLeft, casingRight, casingHead, casingBottom, casingWidth, topCasingIsCrown, wallSpaceAboveUnit
        case panelCount, mullionsVertical, mullionsHorizontal, mullionWidth
        case muntinsRows, muntinsCols, muntinWidth, panels, mullionLayoutPreset, mullionSeams
        case frameWidth, jambDepth, frameMaterial, glazing
        case sillProjection, interiorStoolProjection, apronHeight
        case isEgress, hasScreens, uFactor, shgc, manufacturer, modelNumber
        case projectionDepth, handing, thresholdHeight
        case notes
    }
    
    init(
        category: OpeningCategory = .window,
        windowStyle: WindowStyle? = .picture,
        doorStyle: DoorStyle? = nil,
        openingWidth: Double = 48,
        openingHeight: Double = 48,
        sillOrBottomAFF: Double = 24,
        casingLeft: Double = 3,
        casingRight: Double = 3,
        casingHead: Double = 3,
        casingBottom: Double = 3,
        casingWidth: Double = 3.5,
        topCasingIsCrown: Bool = false,
        wallSpaceAboveUnit: Double = 0,
        panelCount: Int = 1,
        mullionsVertical: Int = 0,
        mullionsHorizontal: Int = 0,
        mullionWidth: Double = 2,
        muntinsRows: Int = 0,
        muntinsCols: Int = 0,
        muntinWidth: Double = 0.75,
        panels: [WindowPanel] = [],
        mullionLayoutPreset: MullionLayoutPreset = .grid,
        frameWidth: Double = 2,
        jambDepth: Double = 4.5,
        frameMaterial: WindowFrameMaterial = .wood,
        glazing: WindowGlazing = .double,
        sillProjection: Double = 1.5,
        interiorStoolProjection: Double = 1,
        apronHeight: Double = 3,
        isEgress: Bool = false,
        hasScreens: Bool = false,
        uFactor: Double = 0,
        shgc: Double = 0,
        manufacturer: String = "",
        modelNumber: String = "",
        projectionDepth: Double = 0,
        handing: OpeningHanding = .none,
        thresholdHeight: Double = 0,
        notes: String = ""
    ) {
        self.category = category
        self.windowStyle = windowStyle
        self.doorStyle = doorStyle
        self.openingWidth = openingWidth
        self.openingHeight = openingHeight
        self.sillOrBottomAFF = sillOrBottomAFF
        self.casingLeft = casingLeft
        self.casingRight = casingRight
        self.casingHead = casingHead
        self.casingBottom = casingBottom
        self.casingWidth = casingWidth
        self.topCasingIsCrown = topCasingIsCrown
        self.wallSpaceAboveUnit = wallSpaceAboveUnit
        self.panelCount = panelCount
        self.mullionsVertical = mullionsVertical
        self.mullionsHorizontal = mullionsHorizontal
        self.mullionWidth = mullionWidth
        self.muntinsRows = muntinsRows
        self.muntinsCols = muntinsCols
        self.muntinWidth = muntinWidth
        self.panels = panels
        self.mullionLayoutPreset = mullionLayoutPreset
        self.frameWidth = frameWidth
        self.jambDepth = jambDepth
        self.frameMaterial = frameMaterial
        self.glazing = glazing
        self.sillProjection = sillProjection
        self.interiorStoolProjection = interiorStoolProjection
        self.apronHeight = apronHeight
        self.isEgress = isEgress
        self.hasScreens = hasScreens
        self.uFactor = uFactor
        self.shgc = shgc
        self.manufacturer = manufacturer
        self.modelNumber = modelNumber
        self.projectionDepth = projectionDepth
        self.handing = handing
        self.thresholdHeight = thresholdHeight
        self.notes = notes
    }
    
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.category = try c.decodeIfPresent(OpeningCategory.self, forKey: .category) ?? .window
        self.windowStyle = try c.decodeIfPresent(WindowStyle.self, forKey: .windowStyle) ?? .picture
        self.doorStyle = try c.decodeIfPresent(DoorStyle.self, forKey: .doorStyle)
        self.openingWidth = try c.decodeIfPresent(Double.self, forKey: .openingWidth) ?? 48
        self.openingHeight = try c.decodeIfPresent(Double.self, forKey: .openingHeight) ?? 48
        self.sillOrBottomAFF = try c.decodeIfPresent(Double.self, forKey: .sillOrBottomAFF) ?? 24
        self.casingLeft = try c.decodeIfPresent(Double.self, forKey: .casingLeft) ?? 3
        self.casingRight = try c.decodeIfPresent(Double.self, forKey: .casingRight) ?? 3
        self.casingHead = try c.decodeIfPresent(Double.self, forKey: .casingHead) ?? 3
        self.casingBottom = try c.decodeIfPresent(Double.self, forKey: .casingBottom) ?? 3
        self.casingWidth = try c.decodeIfPresent(Double.self, forKey: .casingWidth) ?? 3.5
        self.topCasingIsCrown = try c.decodeIfPresent(Bool.self, forKey: .topCasingIsCrown) ?? false
        self.wallSpaceAboveUnit = try c.decodeIfPresent(Double.self, forKey: .wallSpaceAboveUnit) ?? 0
        self.panelCount = try c.decodeIfPresent(Int.self, forKey: .panelCount) ?? 1
        self.mullionsVertical = try c.decodeIfPresent(Int.self, forKey: .mullionsVertical) ?? 0
        self.mullionsHorizontal = try c.decodeIfPresent(Int.self, forKey: .mullionsHorizontal) ?? 0
        self.mullionWidth = try c.decodeIfPresent(Double.self, forKey: .mullionWidth) ?? 2
        self.muntinsRows = try c.decodeIfPresent(Int.self, forKey: .muntinsRows) ?? 0
        self.muntinsCols = try c.decodeIfPresent(Int.self, forKey: .muntinsCols) ?? 0
        self.muntinWidth = try c.decodeIfPresent(Double.self, forKey: .muntinWidth) ?? 0.75
        self.panels = try c.decodeIfPresent([WindowPanel].self, forKey: .panels) ?? []
        self.mullionLayoutPreset = try c.decodeIfPresent(MullionLayoutPreset.self, forKey: .mullionLayoutPreset) ?? .grid
        self.mullionSeams = try c.decodeIfPresent([Bool].self, forKey: .mullionSeams) ?? []
        self.frameWidth = try c.decodeIfPresent(Double.self, forKey: .frameWidth) ?? 2
        self.jambDepth = try c.decodeIfPresent(Double.self, forKey: .jambDepth) ?? 4.5
        self.frameMaterial = try c.decodeIfPresent(WindowFrameMaterial.self, forKey: .frameMaterial) ?? .wood
        self.glazing = try c.decodeIfPresent(WindowGlazing.self, forKey: .glazing) ?? .double
        self.sillProjection = try c.decodeIfPresent(Double.self, forKey: .sillProjection) ?? 1.5
        self.interiorStoolProjection = try c.decodeIfPresent(Double.self, forKey: .interiorStoolProjection) ?? 1
        self.apronHeight = try c.decodeIfPresent(Double.self, forKey: .apronHeight) ?? 3
        self.isEgress = try c.decodeIfPresent(Bool.self, forKey: .isEgress) ?? false
        self.hasScreens = try c.decodeIfPresent(Bool.self, forKey: .hasScreens) ?? false
        self.uFactor = try c.decodeIfPresent(Double.self, forKey: .uFactor) ?? 0
        self.shgc = try c.decodeIfPresent(Double.self, forKey: .shgc) ?? 0
        self.manufacturer = try c.decodeIfPresent(String.self, forKey: .manufacturer) ?? ""
        self.modelNumber = try c.decodeIfPresent(String.self, forKey: .modelNumber) ?? ""
        self.projectionDepth = try c.decodeIfPresent(Double.self, forKey: .projectionDepth) ?? 0
        self.handing = try c.decodeIfPresent(OpeningHanding.self, forKey: .handing) ?? .none
        self.thresholdHeight = try c.decodeIfPresent(Double.self, forKey: .thresholdHeight) ?? 0
        self.notes = try c.decodeIfPresent(String.self, forKey: .notes) ?? ""
    }
}

// MARK: - Beam Positioning

enum BeamPosition: String, CaseIterable, Codable, Hashable {
    case onTopOfColumns = "On Top of Columns"
    case wedgedBetween = "Wedged Between"
    case ceilingHung = "Ceiling Hung"
}

// MARK: - Wall Variant

enum WallVariant: String, CaseIterable, Codable, Hashable {
    case full = "Full Wall"
    case kneeWall = "Knee / Half Wall"
    case cathedral = "Cathedral"
    case archedPartition = "Arched Partition"
    case passThrough = "Pass-Through Opening"
    case custom = "Custom"
}

// MARK: - Room Beam (column-anchored, spans across walls)

struct RoomBeam: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var label: String
    var fromColumnID: UUID
    var toColumnID: UUID
    var thickness: Double   // face dimension in plan (inches)
    var height: Double      // vertical dimension (inches)
    var position: BeamPosition
    
    init(
        id: UUID = UUID(),
        label: String = "",
        fromColumnID: UUID,
        toColumnID: UUID,
        thickness: Double = 6,
        height: Double = 12,
        position: BeamPosition = .onTopOfColumns
    ) {
        self.id = id
        self.label = label
        self.fromColumnID = fromColumnID
        self.toColumnID = toColumnID
        self.thickness = thickness
        self.height = height
        self.position = position
    }
}

// MARK: - Wall Segment

struct WallSegment: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var label: String
    var width: Double
    var kind: SegmentKind
    var note: String
    
    var opening: OpeningSpec?
    var shelfCount: Int?
    var shelfDepth: Double?          // inches; how far shelves project from wall
    var shelfThickness: Double?      // inches; plank thickness of each shelf (kind == .shelf)
    var shelfSpacedEvenly: Bool?     // when true, multiple shelves auto-distribute vertically
    var isFloorToCeiling: Bool?
    var isSharedCorner: Bool?        // only used when kind == .column; flags a corner column shared with an adjacent wall
    var beamPosition: BeamPosition?  // only used when kind == .beam
    var wallVariant: WallVariant?    // only used when kind == .wall or .wallSpace
    var kneeWallHeight: Double?      // inches AFF; only when wallVariant == .kneeWall
    var cathedralPeakHeight: Double? // inches AFF; only when wallVariant == .cathedral
    var cathedralPeakOffset: Double? // inches from wall left edge to peak; only when .cathedral
    var archRise: Double?            // inches; only when wallVariant == .archedPartition
    /// Step 7 — when kind == .alcoveOpening, this ties the segment's station
    /// range to a room-level RoomAlcove. The alcove itself lives on Room.alcoves.
    var alcoveRef: UUID?
    
    init(
        id: UUID = UUID(),
        label: String,
        width: Double,
        kind: SegmentKind,
        note: String = "",
        opening: OpeningSpec? = nil,
        shelfCount: Int? = nil,
        shelfDepth: Double? = nil,
        shelfThickness: Double? = nil,
        shelfSpacedEvenly: Bool? = nil,
        isFloorToCeiling: Bool? = nil,
        isSharedCorner: Bool? = nil,
        beamPosition: BeamPosition? = nil,
        wallVariant: WallVariant? = nil,
        kneeWallHeight: Double? = nil,
        cathedralPeakHeight: Double? = nil,
        cathedralPeakOffset: Double? = nil,
        archRise: Double? = nil,
        alcoveRef: UUID? = nil
    ) {
        self.id = id
        self.label = label
        self.width = width
        self.kind = kind
        self.note = note
        self.opening = opening
        self.shelfCount = shelfCount
        self.shelfDepth = shelfDepth
        self.shelfThickness = shelfThickness
        self.shelfSpacedEvenly = shelfSpacedEvenly
        self.isFloorToCeiling = isFloorToCeiling
        self.isSharedCorner = isSharedCorner
        self.beamPosition = beamPosition
        self.wallVariant = wallVariant
        self.kneeWallHeight = kneeWallHeight
        self.cathedralPeakHeight = cathedralPeakHeight
        self.cathedralPeakOffset = cathedralPeakOffset
        self.archRise = archRise
        self.alcoveRef = alcoveRef
    }
    
    enum CodingKeys: String, CodingKey {
        case id, label, width, kind, note
        case opening, shelfCount, shelfDepth, shelfThickness, shelfSpacedEvenly, isFloorToCeiling, isSharedCorner, beamPosition
        case wallVariant, kneeWallHeight, cathedralPeakHeight, cathedralPeakOffset, archRise
        case alcoveRef
    }
    
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.label = try c.decodeIfPresent(String.self, forKey: .label) ?? ""
        self.width = try c.decodeIfPresent(Double.self, forKey: .width) ?? 0
        self.kind = try c.decodeIfPresent(SegmentKind.self, forKey: .kind) ?? .wall
        self.note = try c.decodeIfPresent(String.self, forKey: .note) ?? ""
        self.opening = try c.decodeIfPresent(OpeningSpec.self, forKey: .opening)
        self.shelfCount = try c.decodeIfPresent(Int.self, forKey: .shelfCount)
        self.shelfDepth = try c.decodeIfPresent(Double.self, forKey: .shelfDepth)
        self.shelfThickness = try c.decodeIfPresent(Double.self, forKey: .shelfThickness)
        self.shelfSpacedEvenly = try c.decodeIfPresent(Bool.self, forKey: .shelfSpacedEvenly)
        self.isFloorToCeiling = try c.decodeIfPresent(Bool.self, forKey: .isFloorToCeiling)
        self.isSharedCorner = try c.decodeIfPresent(Bool.self, forKey: .isSharedCorner)
        self.beamPosition = try c.decodeIfPresent(BeamPosition.self, forKey: .beamPosition)
        self.wallVariant = try c.decodeIfPresent(WallVariant.self, forKey: .wallVariant)
        self.kneeWallHeight = try c.decodeIfPresent(Double.self, forKey: .kneeWallHeight)
        self.cathedralPeakHeight = try c.decodeIfPresent(Double.self, forKey: .cathedralPeakHeight)
        self.cathedralPeakOffset = try c.decodeIfPresent(Double.self, forKey: .cathedralPeakOffset)
        self.archRise = try c.decodeIfPresent(Double.self, forKey: .archRise)
        self.alcoveRef = try c.decodeIfPresent(UUID.self, forKey: .alcoveRef)
    }
    
    var resolvedWidth: Double {
        if let opening {
            return opening.resolvedSegmentWidth
        }
        return width
    }
    
    /// Family Room Wall 1, matching `WallRegistrySync/wall_1_registry.json`. Segment labels are the
    /// room's global structural IDs, so `WallRegistryBridge` emits C1 / Z1 / … / Z3A / Z3B / Z3C
    /// without renaming anything. The window's 5in casing supplies Z3A and Z3C.
    ///
    ///     C1=8 | Z1=43 | C2=8 | Z2=12.75 | Z3A=5 | Z3B=96 | Z3C=5 | Z4=12.75 | C3=8 | Z5=39.5 | C4=8  → 246
    ///
    /// The Z3 window's OpeningSpec is code-locked. See `wall1Z3BOpening()` below,
    /// which pulls all numeric values from `WindowLockLibrary.wall1Z3B`.
    
    /// Constructs the Z3 window OpeningSpec directly from the code-frozen
    /// WindowLock. Any place in the app that seeds or resets Wall 1's
    /// window should call this instead of hand-typing values, so drift
    /// is impossible without editing WindowLockLibrary.
    static func wall1Z3BOpening() -> OpeningSpec {
        let lock = WindowLockLibrary.wall1Z3B
        precondition(
            lock.panelSplit.count == 3,
            "wall1Z3BOpening assumes a 3-panel split; the lock changed shape."
        )
        let panelString = lock.panelSplit.map { String(Int($0)) }.joined(separator: " / ")
        let notes = "\(Int(lock.width))in x \(Int(lock.height))in window (code-locked, WindowLock \(lock.version)). \(panelString)in panel split. Side lights carry a grid pattern, center panel stays clear. Frame, mullions, and the \(Int(lock.casingWidth))in casing all around are white."
        return OpeningSpec(
            category: .window,
            windowStyle: .picture,
            openingWidth: lock.width,
            openingHeight: lock.height,
            sillOrBottomAFF: 20,
            casingLeft: lock.casingWidth,
            casingRight: lock.casingWidth,
            casingHead: lock.casingWidth,
            casingBottom: lock.casingWidth,
            casingWidth: lock.casingWidth,
            wallSpaceAboveUnit: 11,
            panelCount: lock.panelSplit.count,
            mullionsVertical: max(0, lock.panelSplit.count - 1),
            muntinsRows: 3,
            muntinsCols: 2,
            panels: [
                WindowPanel(label: "Left side light", widthShare: lock.panelSplit[0], hasMuntinGrid: true),
                WindowPanel(label: "Center",          widthShare: lock.panelSplit[1], hasMuntinGrid: false),
                WindowPanel(label: "Right side light", widthShare: lock.panelSplit[2], hasMuntinGrid: true)
            ],
            notes: notes
        )
    }
    
    static let wallOneSeedSegments: [WallSegment] = [
        WallSegment(
            label: "C1",
            width: 8,
            kind: .column,
            note: "Outer left column. Terminates Wall 1. 8in wide x 9.25in deep. Reads more structurally defined than the wall returns."
        ),
        WallSegment(
            label: "Z1",
            width: 43,
            kind: .shelf,
            note: "Left open shelf bay. Boards attach directly between C1 and C2. No bookcase box, no inset built-in, no side panels, no base cabinet.",
            shelfCount: 5,
            shelfDepth: 9.25,
            shelfThickness: 1.5,
            shelfSpacedEvenly: true
        ),
        WallSegment(
            label: "C2",
            width: 8,
            kind: .column,
            note: "Inner left column. 8in wide x 9.25in deep."
        ),
        WallSegment(
            label: "Z2",
            width: 12.75,
            kind: .returnZone,
            note: "Left wall return. Flush with the wall plane, plain plaster, no seams. Stays flat and quiet and is never absorbed into the window unit, its casing, the columns, or the shelves."
        ),
        WallSegment(
            label: "Z3",
            width: 0,
            kind: .windowUnit,
            note: "Main window unit \u{2014} code-locked by WindowLockLibrary.wall1Z3B (see WallRegistryWindowLock.swift). 22 / 52 / 22 panel split at 60in tall.",
            opening: Self.wall1Z3BOpening()
        ),
        WallSegment(
            label: "Z4",
            width: 12.75,
            kind: .returnZone,
            note: "Right wall return. Flush with the wall plane, plain plaster, no seams. Stays flat and quiet and is never absorbed into the window unit, its casing, the columns, or the shelves."
        ),
        WallSegment(
            label: "C3",
            width: 8,
            kind: .column,
            note: "Inner right column. 8in wide x 9.25in deep."
        ),
        WallSegment(
            label: "Z5",
            width: 39.5,
            kind: .shelf,
            note: "Right open shelf bay. Boards attach directly between C3 and C4. No bookcase box, no inset built-in, no side panels, no base cabinet.",
            shelfCount: 5,
            shelfDepth: 9.25,
            shelfThickness: 1.5,
            shelfSpacedEvenly: true
        ),
        WallSegment(
            label: "C4",
            width: 8,
            kind: .column,
            note: "Outer right column. Terminates Wall 1. 8in wide x 9.25in deep. Reads more structurally defined than the wall returns."
        )
    ]

    static let wallOneSeedTotalWidth: Double = 246

    /// Wall 1 runs 8in x 9.25in columns under an 8in beam zone at a 96in ceiling, not the room-wide
    /// RGRST defaults. Applied as wall overrides so no other wall's columns are resized.
    static let wallOneSeedDefaults = RoomDefaults(
        ceilingHeight: 96,
        crownHeight: 0,
        baseboardHeight: 8,
        beamHeight: 8,
        beamRangeAFF: "88.00-96.00",
        columnWidth: 8,
        columnDepth: 9.25,
        columnHeight: 88
    )

    /// Persistent Wall 1 decisions that have no dedicated field on the model. Written into
    /// `WallSpec.notes`, which `WallRegistryBridge` forwards into the payload's `rules`.
    static let wallOneSeedNotes = """
    Wall 1 locked decisions:
    - C1 and C4 terminate Wall 1. Nothing extends past them.
    - Columns are 8in wide x 9.25in deep and read more structurally defined than the wall returns.
    - Open shelves are 9.25in deep, aligned with the column depth, and attach directly between the flanking columns.
    - Shelves read as boards. No bookcase boxes, no inset built-ins, no side panels, no base cabinets.
    - Z2 and Z4 are flush wall returns, 12.75in each, in plain plaster with no seams. They stay flat and quiet and are never absorbed into the columns, shelves, casing, or window unit.
    - The window carries 5in casing all around; Z3A and Z3C are its 5in vertical legs.
    - Window frame and mullions are white. Side lights carry a grid pattern, the center panel stays clear.
    """

    /// Parses horizontal chain shorthand into segments.
    ///
    /// `WallSpec.segments` is the authoritative description of a wall; a chain string is only
    /// shorthand for producing or re-describing those segments. Use `parseChainDetailed` when
    /// the caller needs to tell the user about tokens that could not be understood.
    static func parseChain(_ chain: String) -> [WallSegment] {
        parseChainDetailed(chain).segments
    }

    struct ChainParseResult {
        var segments: [WallSegment]
        var unrecognizedTokens: [String]
    }

    /// Parses every token in `chain` through `ChainTokenTable`, collecting anything it cannot
    /// resolve. Nothing is dropped without being reported, so a chain and the segments it
    /// produced can never silently disagree.
    static func parseChainDetailed(_ chain: String) -> ChainParseResult {
        let tokens = chain
            .uppercased()
            .split(whereSeparator: \.isWhitespace)
            .map(String.init)

        var counts: [String: Int] = [:]
        var segments: [WallSegment] = []
        var unrecognized: [String] = []

        for raw in tokens {
            guard let token = ChainTokenTable.token(forInput: raw) else {
                if !unrecognized.contains(raw) { unrecognized.append(raw) }
                continue
            }
            counts[token.canonical, default: 0] += 1
            let label = "\(token.canonical)\(counts[token.canonical]!)"
            segments.append(chainSegment(for: token, label: label))
        }

        return ChainParseResult(segments: segments, unrecognizedTokens: unrecognized)
    }

    /// Builds the default segment for a chain token, including the opening spec that
    /// window / door / cased-opening tokens need.
    static func chainSegment(for token: ChainTokenTable.Token, label: String) -> WallSegment {
        var segment = WallSegment(
            label: label,
            width: token.defaultWidth,
            kind: token.kind,
            note: token.note
        )

        switch token.kind {
        case .bookcase:
            segment.shelfCount = 5
            segment.shelfDepth = 12
            segment.isFloorToCeiling = true

        case .shelf:
            segment.shelfCount = 1
            segment.shelfDepth = 10
            segment.shelfThickness = 1.5
            segment.shelfSpacedEvenly = true

        case .beam:
            segment.beamPosition = .onTopOfColumns

        case .windowUnit:
            // Openings carry their width in the opening spec; `resolvedWidth` adds the casing.
            segment.width = 0
            segment.opening = OpeningSpec(
                category: .window,
                windowStyle: .picture,
                openingWidth: 48,
                openingHeight: 48,
                sillOrBottomAFF: 24,
                wallSpaceAboveUnit: 6,
                panelCount: 1
            )

        case .door:
            segment.width = 0
            segment.opening = OpeningSpec(
                category: .door,
                windowStyle: nil,
                doorStyle: .single,
                openingWidth: 36,
                openingHeight: 80,
                sillOrBottomAFF: 0,
                panelCount: 1,
                handing: .left
            )

        case .opening:
            segment.width = 0
            segment.opening = OpeningSpec(
                category: .generic,
                windowStyle: nil,
                doorStyle: nil,
                openingWidth: 36,
                openingHeight: 80,
                sillOrBottomAFF: 0,
                casingLeft: 0,
                casingRight: 0,
                casingHead: 0
            )

        default:
            break
        }

        return segment
    }
}

// MARK: - Chain Token Table

/// The single vocabulary shared by the chain text field, the tap-to-insert legend, the chain
/// parser, and the shorthand rebuilt from segments. Adding a token here is enough to make it
/// typeable, insertable, parseable, and round-trippable.
///
/// A wall's authoritative data is `WallSpec.segments`. `WallSpec.chainString` is a derived
/// shorthand that is rebuilt from those segments whenever a wall is saved.
enum ChainTokenTable {
    struct Token: Identifiable, Hashable {
        let canonical: String
        let name: String
        let definition: String
        let kind: SegmentKind
        let defaultWidth: Double
        let note: String
        /// Extra spellings accepted from the keyboard, normalized to `canonical`.
        let aliases: [String]
        /// Whether the token gets a chip in the horizontal legend strip.
        let showsInLegend: Bool

        var id: String { canonical }
    }

    /// Order matters: the first token listed for a `SegmentKind` is the one used when a chain
    /// string is rebuilt from segments.
    static let horizontal: [Token] = [
        Token(canonical: "C", name: "Column", definition: "Vertical structural column.",
              kind: .column, defaultWidth: 12, note: "Chain column",
              aliases: ["COL"], showsInLegend: true),
        Token(canonical: "SH", name: "Shelf Bay", definition: "Built-in shelving / bookcase bay.",
              kind: .bookcase, defaultWidth: 24, note: "Chain shelf",
              aliases: ["S"], showsInLegend: true),
        Token(canonical: "BC", name: "Bookcase", definition: "Built-in bookcase or cabinetry.",
              kind: .bookcase, defaultWidth: 36, note: "Chain bookcase",
              aliases: ["BK"], showsInLegend: true),
        Token(canonical: "SF", name: "Open Shelf", definition: "Single open shelf plank.",
              kind: .shelf, defaultWidth: 24, note: "Chain open shelf",
              aliases: [], showsInLegend: false),
        Token(canonical: "WS", name: "Wall Space", definition: "Blank drywall run between elements.",
              kind: .wallSpace, defaultWidth: 18, note: "Chain wall space",
              aliases: [], showsInLegend: true),
        Token(canonical: "RZ", name: "Wall Return", definition: "Clear wall return beside an opening. Stays its own zone and is never absorbed into the opening.",
              kind: .returnZone, defaultWidth: 24, note: "Clear wall return - must remain separate from the adjacent opening",
              aliases: ["WR", "RET", "R", "WRET"], showsInLegend: true),
        // FP and NIC have no dedicated SegmentKind yet, so they are wall-space zones carrying their
        // own label. That keeps the zone and its width in the wall instead of dropping it, and the
        // label prefix lets the chain string round-trip as FP / NIC.
        Token(canonical: "FP", name: "Fireplace", definition: "Fireplace, mantel, or surround. Held as its own wall zone.",
              kind: .wallSpace, defaultWidth: 48, note: "Fireplace zone",
              aliases: ["F"], showsInLegend: true),
        Token(canonical: "NIC", name: "Niche", definition: "Recessed wall niche or alcove. Held as its own wall zone.",
              kind: .wallSpace, defaultWidth: 24, note: "Niche zone",
              aliases: ["N"], showsInLegend: true),
        Token(canonical: "W", name: "Wall", definition: "Full wall run or partition.",
              kind: .wall, defaultWidth: 24, note: "Chain wall",
              aliases: [], showsInLegend: true),
        Token(canonical: "WIN", name: "Window", definition: "Window opening.",
              kind: .windowUnit, defaultWidth: 0, note: "Chain window",
              aliases: ["WN"], showsInLegend: true),
        Token(canonical: "DR", name: "Door", definition: "Door opening.",
              kind: .door, defaultWidth: 0, note: "Chain door",
              aliases: ["D", "DOOR"], showsInLegend: true),
        Token(canonical: "OP", name: "Opening", definition: "Cased opening, no door.",
              kind: .opening, defaultWidth: 0, note: "Generic opening",
              aliases: ["O"], showsInLegend: true),
        Token(canonical: "BM", name: "Beam Zone", definition: "Horizontal beam zone on this wall.",
              kind: .beam, defaultWidth: 24, note: "Beam zone",
              aliases: ["B", "BEAM"], showsInLegend: false),
        Token(canonical: "BB", name: "Baseboard", definition: "Baseboard run.",
              kind: .baseboard, defaultWidth: 4, note: "Baseboard",
              aliases: [], showsInLegend: false),
        Token(canonical: "CR", name: "Crown", definition: "Crown molding run.",
              kind: .crown, defaultWidth: 4, note: "Crown",
              aliases: [], showsInLegend: false),
        Token(canonical: "CS", name: "Casing", definition: "Casing / trim beside an opening.",
              kind: .casing, defaultWidth: 4, note: "Casing",
              aliases: [], showsInLegend: false),
        Token(canonical: "TR", name: "Trim", definition: "Miscellaneous trim run.",
              kind: .trim, defaultWidth: 4, note: "Trim",
              aliases: [], showsInLegend: false)
    ]

    static let legendTokens: [Token] = horizontal.filter(\.showsInLegend)

    private static let lookup: [String: Token] = {
        var map: [String: Token] = [:]
        for token in horizontal {
            map[token.canonical] = token
            for alias in token.aliases where map[alias] == nil {
                map[alias] = token
            }
        }
        return map
    }()

    /// Resolves raw keyboard input (canonical token or alias) to a token.
    static func token(forInput raw: String) -> Token? {
        lookup[raw.trimmingCharacters(in: .whitespaces).uppercased()]
    }

    /// The canonical spelling for raw input, or the uppercased input when unrecognized so the
    /// user can still see and correct what they typed.
    static func canonicalInput(_ raw: String) -> String {
        let cleaned = raw.trimmingCharacters(in: .whitespaces).uppercased()
        return lookup[cleaned]?.canonical ?? cleaned
    }

    /// The token used when rebuilding a chain string from a segment. Prefers a token whose
    /// canonical spelling already prefixes the segment label, so a bookcase entered as `BC`
    /// round-trips as `BC` rather than collapsing to `SH`.
    static func canonicalToken(for segment: WallSegment) -> String {
        let candidates = horizontal.filter { $0.kind == segment.kind }
        let label = segment.label.uppercased()
        if let exact = candidates.first(where: { label.hasPrefix($0.canonical) }) {
            return exact.canonical
        }
        return candidates.first?.canonical ?? ""
    }

    /// Rebuilds the shorthand for a full segment list. This is the only direction of truth:
    /// segments produce the chain string, never the reverse.
    static func chainString(for segments: [WallSegment]) -> String {
        segments
            .map { canonicalToken(for: $0) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
}
