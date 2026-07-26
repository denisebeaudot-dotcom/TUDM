import Foundation

/// Payload pushed to the wall-registry backend proxy, which is the source of truth
/// for Perplexity render control. This app never holds the Perplexity API key.
struct WallRegistryEnvelope: Codable, Equatable {
    var roomId: String
    var wallId: String
    var units: String
    var expectedTotalWidth: Double
    var sourceApp: String
    var schemaVersion: String
    var updatedAt: Date
    var segments: [WallSegment]
    var vertical: VerticalReferences?
    var rules: [String]

    init(
        roomId: String,
        wallId: String,
        units: String = "inches",
        expectedTotalWidth: Double,
        sourceApp: String = "TUDM Interior Authority",
        schemaVersion: String = "wall-registry-v1",
        updatedAt: Date = Date(),
        segments: [WallSegment],
        vertical: VerticalReferences? = nil,
        rules: [String] = []
    ) {
        self.roomId = roomId
        self.wallId = wallId
        self.units = units
        self.expectedTotalWidth = expectedTotalWidth
        self.sourceApp = sourceApp
        self.schemaVersion = schemaVersion
        self.updatedAt = updatedAt
        self.segments = segments
        self.vertical = vertical
        self.rules = rules
    }

    // Nested because the app already has a top-level `WallSegment` (the editable
    // model in InteriorAuthorityModels.swift). This is the flattened wire format.
    struct WallSegment: Codable, Equatable, Identifiable {
        var id: String { globalId }
        var globalId: String
        var localId: String?
        var kind: WallSegmentKind
        var label: String
        var width: Double
        var height: Double?
        var panelSplit: [Double]?
        var notes: String?

        init(
            globalId: String,
            localId: String? = nil,
            kind: WallSegmentKind,
            label: String,
            width: Double,
            height: Double? = nil,
            panelSplit: [Double]? = nil,
            notes: String? = nil
        ) {
            self.globalId = globalId
            self.localId = localId
            self.kind = kind
            self.label = label
            self.width = width
            self.height = height
            self.panelSplit = panelSplit
            self.notes = notes
        }
    }

    enum WallSegmentKind: String, Codable, CaseIterable {
        case column
        case bookcase
        /// Open shelf boards spanning between columns. Distinct from `bookcase`, which is a
        /// carcass with side panels.
        case shelf
        case `return`
        case casing
        case window
        case door
        case opening
        case wall
        case unknown
    }

    var calculatedTotalWidth: Double {
        segments.reduce(0) { $0 + $1.width }
    }

    /// Human-readable chain, e.g. `C1=8in | Z1=43in | ...`, for the source-of-truth display.
    var chainDescription: String {
        let suffix = units == "inches" ? "in" : ""
        return segments
            .map { "\($0.globalId)=\(Self.trimmedNumber($0.width))\(suffix)" }
            .joined(separator: " | ")
    }

    /// Tolerance matches the backend validator so this app never accepts a wall the proxy will reject.
    func validate(tolerance: Double = 0.001) throws {
        guard !roomId.trimmed.isEmpty else {
            throw WallRegistryValidationError.missingRoomId
        }
        guard !wallId.trimmed.isEmpty else {
            throw WallRegistryValidationError.missingWallId
        }
        guard !segments.isEmpty else {
            throw WallRegistryValidationError.noSegments
        }

        var seenGlobalIds: Set<String> = []
        for segment in segments {
            let globalId = segment.globalId.trimmed
            guard !globalId.isEmpty else {
                throw WallRegistryValidationError.missingGlobalId(label: segment.label)
            }
            guard segment.width > 0 else {
                throw WallRegistryValidationError.nonPositiveWidth(globalId: globalId)
            }
            guard seenGlobalIds.insert(globalId).inserted else {
                throw WallRegistryValidationError.duplicateGlobalId(globalId)
            }

            if let panelSplit = segment.panelSplit {
                guard !panelSplit.isEmpty else {
                    throw WallRegistryValidationError.emptyPanelSplit(globalId: globalId)
                }
                let panelTotal = panelSplit.reduce(0, +)
                guard abs(panelTotal - segment.width) <= tolerance else {
                    throw WallRegistryValidationError.panelSplitMismatch(
                        globalId: globalId,
                        expected: segment.width,
                        actual: panelTotal
                    )
                }
            }
        }

        let total = calculatedTotalWidth
        guard abs(total - expectedTotalWidth) <= tolerance else {
            throw WallRegistryValidationError.totalWidthMismatch(
                expected: expectedTotalWidth,
                actual: total
            )
        }
    }

    static func trimmedNumber(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0...2)).grouping(.never))
    }
}

/// Vertical reference heights (inches AFF) that keep renders locked to the measured framework.
struct VerticalReferences: Codable, Equatable {
    var ceilingHeight: Double?
    var beamBottom: Double?
    var beamZoneHeight: Double?
    var sillOrBaseReference: Double?
    var windowHead: Double?
    var headerTop: Double?

    init(
        ceilingHeight: Double? = nil,
        beamBottom: Double? = nil,
        beamZoneHeight: Double? = nil,
        sillOrBaseReference: Double? = nil,
        windowHead: Double? = nil,
        headerTop: Double? = nil
    ) {
        self.ceilingHeight = ceilingHeight
        self.beamBottom = beamBottom
        self.beamZoneHeight = beamZoneHeight
        self.sillOrBaseReference = sillOrBaseReference
        self.windowHead = windowHead
        self.headerTop = headerTop
    }
}

enum WallRegistryValidationError: Error, LocalizedError, Equatable {
    case missingRoomId
    case missingWallId
    case noSegments
    case missingGlobalId(label: String)
    case nonPositiveWidth(globalId: String)
    case duplicateGlobalId(String)
    case emptyPanelSplit(globalId: String)
    case panelSplitMismatch(globalId: String, expected: Double, actual: Double)
    case totalWidthMismatch(expected: Double, actual: Double)
    /// A segment covered by a `WindowLock` was found with values that
    /// do not match the lock. The window must be repaired before this
    /// wall can be rendered, saved, or pushed to the registry.
    case windowLockViolation(wallId: String, globalId: String, detail: String)

    var errorDescription: String? {
        let number = WallRegistryEnvelope.trimmedNumber
        switch self {
        case .missingRoomId:
            return "Room ID is required. Give the room a name before pushing."
        case .missingWallId:
            return "Wall ID is required. Give the wall a name before pushing."
        case .noSegments:
            return "At least one wall segment is required."
        case let .missingGlobalId(label):
            return "Every segment needs a global ID. Segment \"\(label)\" has none."
        case let .nonPositiveWidth(globalId):
            return "Segment \(globalId) must have a width greater than zero."
        case let .duplicateGlobalId(globalId):
            return "Duplicate global ID \(globalId). Global IDs must be unique across the room."
        case let .emptyPanelSplit(globalId):
            return "Segment \(globalId) has an empty panel split. Remove it or list the panel widths."
        case let .panelSplitMismatch(globalId, expected, actual):
            return "Segment \(globalId) panel split totals \(number(actual)) but the segment is \(number(expected)) wide."
        case let .totalWidthMismatch(expected, actual):
            return "Wall total mismatch. Expected \(number(expected)), segments add up to \(number(actual))."
        case let .windowLockViolation(wallId, globalId, detail):
            return "Window lock violated on \(wallId)/\(globalId): \(detail). The 22/52/22 x 60in window is code-locked and cannot be changed."
        }
    }
}
