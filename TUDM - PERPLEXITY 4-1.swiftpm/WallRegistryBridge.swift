import Foundation

/// Converts the app's editable `WallSpec` into the flat wire format the backend proxy expects.
///
/// Openings are expanded into `casing | unit | casing` segments so the registry mirrors the
/// Wall 1 source of truth (Z3A | Z3B | Z3C) and so a window's panel split sums to the
/// window's own width rather than to the casing-inclusive segment width.
enum WallRegistryBridge {
    static func envelope(for wall: WallSpec, in room: Room, updatedAt: Date = Date()) -> WallRegistryEnvelope {
        let defaults = wall.usesOverrides ? (wall.overrides ?? room.defaults) : room.defaults
        let wallId = wall.name.trimmed

        var rules = WallRegistryWall1Example.lockedRules
        if !wall.ruleSet.trimmed.isEmpty {
            rules.insert("Rule set: \(wall.ruleSet.trimmed)", at: 0)
        }
        for notes in [room.notes.trimmed, wall.notes.trimmed] where !notes.isEmpty {
            rules.append(notes)
        }

        return WallRegistryEnvelope(
            roomId: slug(room.name),
            wallId: wallId,
            expectedTotalWidth: wall.totalWidth,
            updatedAt: updatedAt,
            segments: segments(for: wall, wallId: wallId),
            vertical: verticalReferences(for: wall, defaults: defaults),
            rules: rules
        )
    }

    // MARK: - Segments

    private static func segments(for wall: WallSpec, wallId: String) -> [WallRegistryEnvelope.WallSegment] {
        wall.segments.enumerated().flatMap { (index, segment) -> [WallRegistryEnvelope.WallSegment] in
            // The app's `label` is the short structural ID ("C1"); its `note` is the description.
            let globalId = segment.label.trimmed.isEmpty ? "SEG\(index + 1)" : segment.label.trimmed
            let description = segment.note.trimmed.isEmpty ? globalId : segment.note.trimmed

            guard let opening = segment.opening else {
                return [
                    .init(
                        globalId: globalId,
                        localId: localId(wallId: wallId, globalId: globalId),
                        kind: .init(segment.kind),
                        label: description,
                        width: segment.width
                    )
                ]
            }

            let hasCasing = opening.casingLeft > 0 || opening.casingRight > 0
            let unitId = hasCasing ? "\(globalId)B" : globalId
            var expanded: [WallRegistryEnvelope.WallSegment] = []

            if opening.casingLeft > 0 {
                expanded.append(
                    .init(
                        globalId: "\(globalId)A",
                        localId: localId(wallId: wallId, globalId: "\(globalId)A"),
                        kind: .casing,
                        label: "\(description) left casing",
                        width: opening.casingLeft
                    )
                )
            }

            expanded.append(
                .init(
                    globalId: unitId,
                    localId: localId(wallId: wallId, globalId: unitId),
                    kind: .init(segment.kind),
                    label: description,
                    width: opening.openingWidth,
                    height: opening.openingHeight,
                    panelSplit: panelSplit(for: opening)
                )
            )

            if opening.casingRight > 0 {
                expanded.append(
                    .init(
                        globalId: "\(globalId)C",
                        localId: localId(wallId: wallId, globalId: "\(globalId)C"),
                        kind: .casing,
                        label: "\(description) right casing",
                        width: opening.casingRight
                    )
                )
            }

            return expanded
        }
    }

    /// Panel widths in inches, guaranteed to sum exactly to `opening.openingWidth`.
    /// Returns nil for single-panel units, which have nothing to split.
    private static func panelSplit(for opening: OpeningSpec) -> [Double]? {
        let shares: [Double] = opening.panels.isEmpty
            ? Array(repeating: 1, count: max(opening.panelCount, 1))
            : opening.panels.map { max($0.widthShare, 0) }

        guard shares.count > 1 else { return nil }
        let totalShare = shares.reduce(0, +)
        guard totalShare > 0, opening.openingWidth > 0 else { return nil }

        var widths = shares.map { (($0 / totalShare) * opening.openingWidth * 1000).rounded() / 1000 }
        // Absorb rounding drift into the last panel so the split always matches the unit width.
        widths[widths.count - 1] = opening.openingWidth - widths.dropLast().reduce(0, +)

        guard widths.allSatisfy({ $0 > 0 }) else { return nil }
        return widths
    }

    // MARK: - Vertical references

    private static func verticalReferences(for wall: WallSpec, defaults: RoomDefaults) -> VerticalReferences {
        let window = wall.segments.compactMap(\.opening).first { $0.category == .window }
        let beamBottom = BeamRangeAFFHelper.parseBottom(defaults.beamRangeAFF)

        return VerticalReferences(
            ceilingHeight: defaults.ceilingHeight,
            beamBottom: beamBottom > 0 ? beamBottom : nil,
            beamZoneHeight: defaults.beamHeight,
            sillOrBaseReference: window?.sillOrBottomAFF ?? defaults.baseboardHeight,
            windowHead: window.map { $0.sillOrBottomAFF + $0.openingHeight },
            headerTop: window.map { $0.sillOrBottomAFF + $0.openingHeight + $0.casingHead }
        )
    }

    // MARK: - Helpers

    private static func localId(wallId: String, globalId: String) -> String? {
        wallId.isEmpty ? nil : "\(wallId)-\(globalId)"
    }

    /// "Family Room" -> "family_room"
    static func slug(_ raw: String) -> String {
        let parts = raw
            .lowercased()
            .split { !$0.isLetter && !$0.isNumber }
            .map(String.init)
        return parts.joined(separator: "_")
    }
}

extension WallRegistryEnvelope.WallSegmentKind {
    init(_ kind: SegmentKind) {
        switch kind {
        case .column: self = .column
        case .bookcase, .shelf: self = .bookcase
        case .returnZone: self = .return
        case .casing, .trim: self = .casing
        case .windowUnit: self = .window
        case .door: self = .door
        case .opening: self = .opening
        case .wall, .wallSpace: self = .wall
        case .beam, .baseboard, .crown: self = .unknown
        }
    }
}
