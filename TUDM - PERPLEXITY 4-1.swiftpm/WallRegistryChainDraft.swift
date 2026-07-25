import Foundation

/// Editable, text-first model behind the chain entry form. Widths stay as text so the user can
/// type carpentry fractions (`12 3/4`) and see exactly what they entered; conversion to a
/// `WallRegistryEnvelope` happens only when validating, previewing, or pushing.
struct WallRegistryChainDraft: Equatable {
    /// Matches the tolerance in `WallRegistryEnvelope.validate` and the backend validator.
    static let tolerance: Double = 0.001

    struct Row: Identifiable, Equatable {
        var id = UUID()
        var globalId: String = ""
        var kind: WallRegistryEnvelope.WallSegmentKind = .wall
        var label: String = ""
        var widthText: String = ""
        var heightText: String = ""
        var panelSplitText: String = ""
        var notes: String = ""

        init() {}

        init(segment: WallRegistryEnvelope.WallSegment) {
            globalId = segment.globalId
            kind = segment.kind
            label = segment.label
            widthText = WallRegistryEnvelope.trimmedNumber(segment.width)
            heightText = segment.height.map(WallRegistryEnvelope.trimmedNumber) ?? ""
            panelSplitText = segment.panelSplit?
                .map(WallRegistryEnvelope.trimmedNumber)
                .joined(separator: " / ") ?? ""
            notes = segment.notes ?? ""
        }

        var parsedWidth: Double? {
            try? WallRegistryChainParser.measurement(widthText)
        }

        var parsedHeight: Double? {
            heightText.trimmed.isEmpty ? nil : try? WallRegistryChainParser.measurement(heightText)
        }

        var parsedPanelSplit: [Double]? {
            let parts = panelSplitParts
            guard !parts.isEmpty else { return nil }
            let widths = parts.compactMap { try? WallRegistryChainParser.measurement($0) }
            return widths.count == parts.count ? widths : nil
        }

        var hasInvalidPanelSplit: Bool {
            !panelSplitParts.isEmpty && parsedPanelSplit == nil
        }

        private var panelSplitParts: [String] {
            panelSplitText
                .split { $0 == "/" || $0 == "," }
                .map { String($0).trimmed }
                .filter { !$0.isEmpty }
        }
    }

    var roomId: String = ""
    var wallId: String = ""
    var units: String = "inches"
    var expectedTotalWidth: Double = 0
    var rows: [Row] = []
    var vertical: VerticalReferences?
    var rules: [String] = WallRegistryWall1Example.lockedRules
    /// Scratch buffer for the paste/import field; never part of the pushed payload.
    var chainInput: String = ""

    init() {}

    init(envelope: WallRegistryEnvelope) {
        roomId = envelope.roomId
        wallId = envelope.wallId
        units = envelope.units
        expectedTotalWidth = envelope.expectedTotalWidth
        rows = envelope.segments.map(Row.init(segment:))
        vertical = envelope.vertical
        rules = envelope.rules.isEmpty ? WallRegistryWall1Example.lockedRules : envelope.rules
        chainInput = envelope.chainDescription
    }

    static func wall1Template() -> WallRegistryChainDraft {
        WallRegistryChainDraft(envelope: WallRegistryWall1Example.make())
    }

    // MARK: - Derived

    var calculatedTotalWidth: Double {
        rows.reduce(0) { $0 + ($1.parsedWidth ?? 0) }
    }

    var chainDescription: String {
        envelope().chainDescription
    }

    func envelope(updatedAt: Date = Date()) -> WallRegistryEnvelope {
        let wall = wallId.trimmed
        let segments: [WallRegistryEnvelope.WallSegment] = rows.map { row in
            let globalId = row.globalId.trimmed
            let localId: String? = wall.isEmpty || globalId.isEmpty ? nil : "\(wall)-\(globalId)"
            let notes: String? = row.notes.trimmed.isEmpty ? nil : row.notes.trimmed
            return WallRegistryEnvelope.WallSegment(
                globalId: globalId,
                localId: localId,
                kind: row.kind,
                label: row.label.trimmed.isEmpty ? globalId : row.label.trimmed,
                width: row.parsedWidth ?? 0,
                height: row.parsedHeight,
                panelSplit: row.parsedPanelSplit,
                notes: notes
            )
        }

        return WallRegistryEnvelope(
            roomId: roomId.trimmed,
            wallId: wall,
            units: units,
            expectedTotalWidth: expectedTotalWidth,
            updatedAt: updatedAt,
            segments: segments,
            vertical: vertical,
            rules: rules
        )
    }

    // MARK: - Validation

    /// Every problem at once, so the user can fix the whole wall in one pass instead of
    /// rediscovering one error per push. `WallRegistryEnvelope.validate` stays the authority.
    var validationIssues: [String] {
        var issues: [String] = []

        if roomId.trimmed.isEmpty { issues.append(message(.missingRoomId)) }
        if wallId.trimmed.isEmpty { issues.append(message(.missingWallId)) }
        if rows.isEmpty { issues.append(message(.noSegments)) }

        var seenGlobalIds: Set<String> = []
        for row in rows {
            let globalId = row.globalId.trimmed
            guard !globalId.isEmpty else {
                let label = row.label.trimmed.isEmpty ? "(no label)" : row.label.trimmed
                issues.append(message(.missingGlobalId(label: label)))
                continue
            }
            if !seenGlobalIds.insert(globalId).inserted {
                issues.append(message(.duplicateGlobalId(globalId)))
            }

            guard let width = row.parsedWidth else {
                issues.append("Segment \(globalId) width \"\(row.widthText.trimmed)\" is not a measurement. Use 43, 12.75, or 12 3/4.")
                continue
            }
            if width <= 0 {
                issues.append(message(.nonPositiveWidth(globalId: globalId)))
            }
            if !row.heightText.trimmed.isEmpty, row.parsedHeight == nil {
                issues.append("Segment \(globalId) height \"\(row.heightText.trimmed)\" is not a measurement.")
            }

            if row.hasInvalidPanelSplit {
                issues.append("Segment \(globalId) panel split \"\(row.panelSplitText.trimmed)\" is not a list of measurements. Use 22 / 52 / 22.")
            } else if let panelSplit = row.parsedPanelSplit {
                let panelTotal = panelSplit.reduce(0, +)
                if abs(panelTotal - width) > Self.tolerance {
                    issues.append(message(.panelSplitMismatch(globalId: globalId, expected: width, actual: panelTotal)))
                }
            }
        }

        let total = calculatedTotalWidth
        if abs(total - expectedTotalWidth) > Self.tolerance {
            issues.append(message(.totalWidthMismatch(expected: expectedTotalWidth, actual: total)))
        }
        return issues
    }

    var totalMatchesExpected: Bool {
        abs(calculatedTotalWidth - expectedTotalWidth) <= Self.tolerance
    }

    // MARK: - Mutations

    mutating func loadWall1Template() {
        self = .wall1Template()
    }

    mutating func addRow() {
        rows.append(Row())
    }

    mutating func deleteRows(at offsets: IndexSet) {
        rows.remove(atOffsets: offsets)
    }

    mutating func moveRows(from source: IndexSet, to destination: Int) {
        rows.move(fromOffsets: source, toOffset: destination)
    }

    mutating func matchExpectedTotalToSegments() {
        expectedTotalWidth = calculatedTotalWidth
    }

    /// Replaces every row from `chainInput`. Kind, label, and notes are recovered from the
    /// Wall 1 source of truth whenever a pasted ID and width match it, so a re-pasted Wall 1
    /// chain comes back fully described instead of as bare widths.
    mutating func applyChainString() throws {
        let parsed = try WallRegistryChainParser.parse(chainInput)
        rows = parsed.map { segment in
            var row = Row()
            row.globalId = segment.globalId
            row.widthText = WallRegistryEnvelope.trimmedNumber(segment.width)
            row.heightText = segment.height.map(WallRegistryEnvelope.trimmedNumber) ?? ""
            row.panelSplitText = segment.panelSplit?
                .map(WallRegistryEnvelope.trimmedNumber)
                .joined(separator: " / ") ?? ""

            let template = Self.wall1Segments[segment.globalId.uppercased()]
            row.kind = template?.kind ?? Self.inferredKind(forGlobalId: segment.globalId)
            row.label = template?.label ?? segment.globalId

            if let template, abs(template.width - segment.width) <= Self.tolerance {
                row.notes = template.notes ?? ""
                if row.heightText.isEmpty {
                    row.heightText = template.height.map(WallRegistryEnvelope.trimmedNumber) ?? ""
                }
                if row.panelSplitText.isEmpty {
                    row.panelSplitText = template.panelSplit?
                        .map(WallRegistryEnvelope.trimmedNumber)
                        .joined(separator: " / ") ?? ""
                }
            }
            return row
        }
    }

    // MARK: - Helpers

    private static let wall1Segments: [String: WallRegistryEnvelope.WallSegment] = {
        Dictionary(
            WallRegistryWall1Example.make().segments.map { ($0.globalId.uppercased(), $0) },
            uniquingKeysWith: { first, _ in first }
        )
    }()

    private static func inferredKind(forGlobalId globalId: String) -> WallRegistryEnvelope.WallSegmentKind {
        let upper = globalId.uppercased()
        if upper.hasPrefix("C") { return .column }
        if upper.hasPrefix("D") { return .door }
        return .wall
    }

    private func message(_ error: WallRegistryValidationError) -> String {
        error.localizedDescription
    }
}

extension WallRegistryEnvelope.WallSegmentKind {
    var displayName: String {
        switch self {
        case .column: return "Column"
        case .bookcase: return "Bookcase"
        case .shelf: return "Open Shelves"
        case .return: return "Wall Return"
        case .casing: return "Casing / Trim"
        case .window: return "Window Unit"
        case .door: return "Door"
        case .opening: return "Opening"
        case .wall: return "Wall Space"
        case .unknown: return "Other"
        }
    }
}
