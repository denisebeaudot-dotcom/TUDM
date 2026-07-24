import Foundation

// MARK: - Project / Room / Wall Models

struct Project: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var clientName: String
    var location: String
    var notes: String
    var rooms: [Room]
    
    init(
        id: UUID = UUID(),
        name: String = "",
        clientName: String = "",
        location: String = "",
        notes: String = "",
        rooms: [Room] = []
    ) {
        self.id = id
        self.name = name
        self.clientName = clientName
        self.location = location
        self.notes = notes
        self.rooms = rooms
    }
}

struct Room: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var notes: String
    var defaults: RoomDefaults
    var wallSpecs: [WallSpec]
    
    init(
        id: UUID = UUID(),
        name: String = "",
        notes: String = "",
        defaults: RoomDefaults = .rgrstDefaults,
        wallSpecs: [WallSpec] = []
    ) {
        self.id = id
        self.name = name
        self.notes = notes
        self.defaults = defaults
        self.wallSpecs = wallSpecs
    }
}

struct WallSpec: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var totalWidth: Double
    var ruleSet: String
    var notes: String
    
    var chainString: String
    var verticalChainString: String
    var segments: [WallSegment]
    
    var usesOverrides: Bool
    var overrides: RoomDefaults?
    
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
        overrides: RoomDefaults? = nil
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
        case segments, usesOverrides, overrides
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
    case beam = "Beam"
    case casing = "Casing"
    case trim = "Trim"
    case baseboard = "Baseboard"
    case crown = "Crown"
    case windowUnit = "Window Unit"
    case door = "Door"
    case opening = "Opening"
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
        case muntinsRows, muntinsCols, muntinWidth, panels, mullionLayoutPreset
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
    var isFloorToCeiling: Bool?
    var beamPosition: BeamPosition?  // only used when kind == .beam
    var wallVariant: WallVariant?    // only used when kind == .wall or .wallSpace
    var kneeWallHeight: Double?      // inches AFF; only when wallVariant == .kneeWall
    var cathedralPeakHeight: Double? // inches AFF; only when wallVariant == .cathedral
    var cathedralPeakOffset: Double? // inches from wall left edge to peak; only when .cathedral
    var archRise: Double?            // inches; only when wallVariant == .archedPartition
    
    init(
        id: UUID = UUID(),
        label: String,
        width: Double,
        kind: SegmentKind,
        note: String = "",
        opening: OpeningSpec? = nil,
        shelfCount: Int? = nil,
        shelfDepth: Double? = nil,
        isFloorToCeiling: Bool? = nil,
        beamPosition: BeamPosition? = nil,
        wallVariant: WallVariant? = nil,
        kneeWallHeight: Double? = nil,
        cathedralPeakHeight: Double? = nil,
        cathedralPeakOffset: Double? = nil,
        archRise: Double? = nil
    ) {
        self.id = id
        self.label = label
        self.width = width
        self.kind = kind
        self.note = note
        self.opening = opening
        self.shelfCount = shelfCount
        self.shelfDepth = shelfDepth
        self.isFloorToCeiling = isFloorToCeiling
        self.beamPosition = beamPosition
        self.wallVariant = wallVariant
        self.kneeWallHeight = kneeWallHeight
        self.cathedralPeakHeight = cathedralPeakHeight
        self.cathedralPeakOffset = cathedralPeakOffset
        self.archRise = archRise
    }
    
    enum CodingKeys: String, CodingKey {
        case id, label, width, kind, note
        case opening, shelfCount, shelfDepth, isFloorToCeiling, beamPosition
        case wallVariant, kneeWallHeight, cathedralPeakHeight, cathedralPeakOffset, archRise
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
        self.isFloorToCeiling = try c.decodeIfPresent(Bool.self, forKey: .isFloorToCeiling)
        self.beamPosition = try c.decodeIfPresent(BeamPosition.self, forKey: .beamPosition)
        self.wallVariant = try c.decodeIfPresent(WallVariant.self, forKey: .wallVariant)
        self.kneeWallHeight = try c.decodeIfPresent(Double.self, forKey: .kneeWallHeight)
        self.cathedralPeakHeight = try c.decodeIfPresent(Double.self, forKey: .cathedralPeakHeight)
        self.cathedralPeakOffset = try c.decodeIfPresent(Double.self, forKey: .cathedralPeakOffset)
        self.archRise = try c.decodeIfPresent(Double.self, forKey: .archRise)
    }
    
    var resolvedWidth: Double {
        if let opening {
            return opening.resolvedSegmentWidth
        }
        return width
    }
    
    static let wallOneSeedSegments: [WallSegment] = [
        WallSegment(label: "C1", width: 12, kind: .column, note: "Left column"),
        WallSegment(label: "SH1", width: 24, kind: .bookcase, note: "Shelf bay", shelfCount: 5, shelfDepth: 12, isFloorToCeiling: true),
        WallSegment(label: "C2", width: 12, kind: .column, note: "Center-left column"),
        WallSegment(label: "WS1", width: 18, kind: .wallSpace, note: "Left wall space"),
        WallSegment(
            label: "W1",
            width: 0,
            kind: .windowUnit,
            note: "Center window",
            opening: OpeningSpec(
                category: .window,
                windowStyle: .picture,
                openingWidth: 60,
                openingHeight: 48,
                sillOrBottomAFF: 24,
                wallSpaceAboveUnit: 6,
                panelCount: 1
            )
        ),
        WallSegment(label: "WS2", width: 18, kind: .wallSpace, note: "Right wall space"),
        WallSegment(label: "C3", width: 12, kind: .column, note: "Center-right column"),
        WallSegment(label: "SH2", width: 24, kind: .bookcase, note: "Shelf bay", shelfCount: 5, shelfDepth: 12, isFloorToCeiling: true),
        WallSegment(label: "C4", width: 12, kind: .column, note: "Right column")
    ]
    
    static func parseChain(_ chain: String) -> [WallSegment] {
        let tokens = chain
            .uppercased()
            .split(whereSeparator: \.isWhitespace)
            .map(String.init)
        
        var counts: [String: Int] = [:]
        
        func nextLabel(_ prefix: String) -> String {
            counts[prefix, default: 0] += 1
            return "\(prefix)\(counts[prefix]!)"
        }
        
        return tokens.compactMap { token in
            switch token {
            case "C":
                return WallSegment(
                    label: nextLabel("C"),
                    width: 12,
                    kind: .column,
                    note: "Chain column"
                )
                
            case "SH":
                return WallSegment(
                    label: nextLabel("SH"),
                    width: 24,
                    kind: .bookcase,
                    note: "Chain shelf",
                    shelfCount: 5,
                    shelfDepth: 12,
                    isFloorToCeiling: true
                )
                
            case "WS":
                return WallSegment(
                    label: nextLabel("WS"),
                    width: 18,
                    kind: .wallSpace,
                    note: "Chain wall space"
                )
                
            case "W":
                return WallSegment(
                    label: nextLabel("W"),
                    width: 24,
                    kind: .wall,
                    note: "Chain wall"
                )
                
            case "WIN":
                return WallSegment(
                    label: nextLabel("WIN"),
                    width: 0,
                    kind: .windowUnit,
                    note: "Chain window",
                    opening: OpeningSpec(
                        category: .window,
                        windowStyle: .picture,
                        openingWidth: 48,
                        openingHeight: 48,
                        sillOrBottomAFF: 24,
                        wallSpaceAboveUnit: 6,
                        panelCount: 1
                    )
                )
                
            case "DR", "D":
                return WallSegment(
                    label: nextLabel("DR"),
                    width: 0,
                    kind: .door,
                    note: "Chain door",
                    opening: OpeningSpec(
                        category: .door,
                        windowStyle: nil,
                        doorStyle: .single,
                        openingWidth: 36,
                        openingHeight: 80,
                        sillOrBottomAFF: 0,
                        panelCount: 1,
                        handing: .left
                    )
                )
                
            case "OP", "O":
                return WallSegment(
                    label: nextLabel("OP"),
                    width: 0,
                    kind: .opening,
                    note: "Generic opening",
                    opening: OpeningSpec(
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
                )
                
            case "BM", "B":
                return WallSegment(
                    label: nextLabel("BM"),
                    width: 24,
                    kind: .beam,
                    note: "Beam zone",
                    beamPosition: .onTopOfColumns
                )
                
            case "BB":
                return WallSegment(
                    label: nextLabel("BB"),
                    width: 4,
                    kind: .baseboard,
                    note: "Baseboard"
                )
                
            case "CR":
                return WallSegment(
                    label: nextLabel("CR"),
                    width: 4,
                    kind: .crown,
                    note: "Crown"
                )
                
            case "CS":
                return WallSegment(
                    label: nextLabel("CS"),
                    width: 4,
                    kind: .casing,
                    note: "Casing"
                )
                
            case "TR":
                return WallSegment(
                    label: nextLabel("TR"),
                    width: 4,
                    kind: .trim,
                    note: "Trim"
                )
                
            case "RZ":
                return WallSegment(
                    label: nextLabel("RZ"),
                    width: 24,
                    kind: .returnZone,
                    note: "Return zone"
                )
                
            default:
                return nil
            }
        }
    }
}
