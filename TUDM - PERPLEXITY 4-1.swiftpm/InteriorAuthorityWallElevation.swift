import SwiftUI

// MARK: - Wall Elevation Layout

struct WallElevationLayout {
    let wall: LockedWall
    let defaults: RoomDefaults
    let verticalChain: String
    let allWalls: [LockedWall]
    let roomBeams: [RoomBeam]
    
    var totalWidth: Double { max(1, wall.totalWidth) }
    var ceilingHeight: Double { max(1, defaults.ceilingHeight) }
    var baseboardHeight: Double { max(0, defaults.baseboardHeight) }
    var crownHeight: Double { max(0, defaults.crownHeight) }
    var beamHeight: Double { max(0, defaults.beamHeight) }
    
    struct PositionedSegment: Identifiable {
        var id: UUID { segment.id }
        let segment: WallSegment
        let xInches: Double
        let widthInches: Double
    }
    
    var positionedSegments: [PositionedSegment] {
        var results: [PositionedSegment] = []
        var cursor: Double = 0
        for segment in wall.segments {
            let w = segment.resolvedWidth
            results.append(PositionedSegment(segment: segment, xInches: cursor, widthInches: w))
            cursor += w
        }
        return results
    }
    
    var segmentSum: Double {
        wall.segments.reduce(0) { $0 + $1.resolvedWidth }
    }
    
    private var verticalTokens: [String] {
        verticalChain
            .split(whereSeparator: { $0 == "-" || $0 == "/" || $0 == " " })
            .map { $0.trimmingCharacters(in: .whitespaces).uppercased() }
            .filter { !$0.isEmpty }
    }
    
    var hasBaseboard: Bool { verticalTokens.contains("BB") || baseboardHeight > 0 }
    var hasCrown: Bool { verticalTokens.contains("CR") || crownHeight > 0 }
    var hasBeam: Bool { verticalTokens.contains("BM") && beamHeight > 0 }
    
    // Beam top position from ceiling (in inches from top of wall)
    var beamTopFromCeiling: Double {
        let parts = defaults.beamRangeAFF.split(separator: "-").map { $0.trimmingCharacters(in: .whitespaces) }
        let hiAFF: Double
        if parts.count == 2, let hi = Double(parts[1]) {
            hiAFF = hi
        } else {
            hiAFF = 108
        }
        return max(0, ceilingHeight - hiAFF)
    }
    
    // MARK: Room-beam intersections with this wall
    
    /// Where a column with the given ID appears on this wall.
    /// Returns the x center in inches (0..totalWidth), or nil if the column is not on this wall.
    private func columnCenterX(columnID: UUID) -> Double? {
        var cursor: Double = 0
        for segment in wall.segments {
            let w = segment.resolvedWidth
            if segment.id == columnID && segment.kind == .column {
                return cursor + w / 2
            }
            cursor += w
        }
        return nil
    }
    
    /// Which wall (by id) is the given column on?
    private func wallID(forColumn columnID: UUID) -> UUID? {
        for w in allWalls {
            if w.segments.contains(where: { $0.id == columnID && $0.kind == .column }) {
                return w.id
            }
        }
        return nil
    }
    
    /// A projected beam extent on this wall.
    struct BeamProjection: Identifiable {
        let id: UUID
        let label: String
        let startX: Double     // inches from left edge of this wall
        let endX: Double       // inches from left edge of this wall
        let thickness: Double  // vertical size in inches
        let position: BeamPosition
    }
    
    /// Compute how each room beam intersects this wall for drawing.
    var beamProjections: [BeamProjection] {
        var results: [BeamProjection] = []
        for beam in roomBeams {
            let fromX = columnCenterX(columnID: beam.fromColumnID)
            let toX = columnCenterX(columnID: beam.toColumnID)
            let fromWall = wallID(forColumn: beam.fromColumnID)
            let toWall = wallID(forColumn: beam.toColumnID)
            
            let onThisWallFrom = fromWall == wall.id
            let onThisWallTo = toWall == wall.id
            
            let startX: Double
            let endX: Double
            
            if onThisWallFrom && onThisWallTo, let a = fromX, let b = toX {
                // Both anchors on this wall: draw between them
                startX = min(a, b)
                endX = max(a, b)
            } else if onThisWallFrom, let a = fromX {
                // From anchor here, To on another wall: extend to the end of this wall
                // Direction: from column A to the wall edge nearest the other wall.
                // Without floorplan info we don't know which edge, so draw to the closer wall edge.
                // Heuristic: extend to the farther edge (which is toward the room interior).
                let leftDistance = a
                let rightDistance = totalWidth - a
                if rightDistance >= leftDistance {
                    startX = a
                    endX = totalWidth
                } else {
                    startX = 0
                    endX = a
                }
            } else if onThisWallTo, let b = toX {
                let leftDistance = b
                let rightDistance = totalWidth - b
                if rightDistance >= leftDistance {
                    startX = b
                    endX = totalWidth
                } else {
                    startX = 0
                    endX = b
                }
            } else {
                // Neither anchor on this wall - beam does not intersect (v1 assumption)
                continue
            }
            
            results.append(BeamProjection(
                id: beam.id,
                label: beam.label,
                startX: startX,
                endX: endX,
                thickness: max(0, beam.height),
                position: beam.position
            ))
        }
        return results
    }
}

// MARK: - Wall Elevation Builder

enum WallElevationBuilder {
    static func build(wall: LockedWall, defaults: RoomDefaults, verticalChain: String, allWalls: [LockedWall] = [], roomBeams: [RoomBeam] = []) -> WallElevationLayout {
        WallElevationLayout(wall: wall, defaults: defaults, verticalChain: verticalChain, allWalls: allWalls, roomBeams: roomBeams)
    }
}

// MARK: - Wall Elevation View

struct WallElevationView: View {
    let layout: WallElevationLayout
    var showsDimensions: Bool = true
    var showsLabels: Bool = true
    
    var body: some View {
        GeometryReader { geo in
            content(in: geo.size)
        }
    }
    
    private func content(in size: CGSize) -> some View {
        let contentW = layout.totalWidth
        let contentH = layout.ceilingHeight
        let scale = fitScale(contentW: contentW, contentH: contentH, in: size)
        let scaledW = contentW * scale
        let scaledH = contentH * scale
        let offsetX = (size.width - scaledW) / 2
        let offsetY = (size.height - scaledH) / 2 - (showsDimensions ? 8 : 0)
        
        return ZStack(alignment: .topLeading) {
            Rectangle().fill(Color(.systemBackground))
            
            innerStack(scale: scale, scaledW: scaledW, scaledH: scaledH)
                .frame(width: scaledW, height: scaledH)
                .offset(x: offsetX, y: offsetY)
        }
        .frame(width: size.width, height: size.height)
    }
    
    @ViewBuilder
    private func innerStack(scale: Double, scaledW: Double, scaledH: Double) -> some View {
        ZStack(alignment: .topLeading) {
            Rectangle()
                .stroke(Color.primary.opacity(0.7), lineWidth: 1.5)
                .background(Color.gray.opacity(0.04))
                .frame(width: scaledW, height: scaledH)
            
            verticalBandsLayer(scale: scale, scaledW: scaledW, scaledH: scaledH)
            
            segmentsLayer(scale: scale, scaledH: scaledH)
            
            roomBeamsLayer(scale: scale, scaledW: scaledW, scaledH: scaledH)
            
            if showsDimensions {
                dimensionsLayer(scale: scale, scaledW: scaledW, scaledH: scaledH)
            }
        }
    }
    
    private func roomBeamsLayer(scale: Double, scaledW: Double, scaledH: Double) -> some View {
        let projections = layout.beamProjections
        let colH = max(0, layout.defaults.columnHeight * scale)
        
        return ZStack(alignment: .topLeading) {
            ForEach(projections) { p in
                let x = p.startX * scale
                let w = max(1, (p.endX - p.startX) * scale)
                let h = max(1, p.thickness * scale)
                let yTop: Double = {
                    switch p.position {
                    case .onTopOfColumns, .wedgedBetween:
                        return max(0, scaledH - colH - h)
                    case .ceilingHung:
                        return 0
                    }
                }()
                Rectangle()
                    .fill(Color.purple.opacity(0.35))
                    .overlay(
                        Rectangle().stroke(Color.purple.opacity(0.8), lineWidth: 1)
                    )
                    .overlay(
                        showsLabels ?
                            Text(p.label.isEmpty ? "BM" : p.label)
                                .font(.system(size: 8, weight: .bold))
                                .foregroundStyle(.primary)
                            : nil
                    )
                    .frame(width: w, height: h)
                    .offset(x: x, y: yTop)
            }
        }
    }
    
    private func fitScale(contentW: Double, contentH: Double, in size: CGSize) -> Double {
        let padRatio = showsDimensions ? 0.86 : 0.95
        let availW = Double(size.width) * padRatio
        let availH = Double(size.height) * padRatio
        return min(availW / contentW, availH / contentH)
    }
    
    // MARK: Layers
    
    @ViewBuilder
    private func verticalBandsLayer(scale: Double, scaledW: Double, scaledH: Double) -> some View {
        ZStack(alignment: .topLeading) {
            if layout.hasBaseboard {
                baseboardBand(scale: scale, scaledW: scaledW, scaledH: scaledH)
            }
            if layout.hasCrown {
                crownBand(scale: scale, scaledW: scaledW)
            }
            if layout.hasBeam {
                beamBand(scale: scale, scaledW: scaledW)
            }
        }
    }
    
    private func baseboardBand(scale: Double, scaledW: Double, scaledH: Double) -> some View {
        let bbH = layout.baseboardHeight * scale
        return Rectangle()
            .fill(Color.brown.opacity(0.25))
            .overlay(Rectangle().stroke(Color.brown.opacity(0.6), lineWidth: 0.75))
            .frame(width: scaledW, height: bbH)
            .offset(x: 0, y: scaledH - bbH)
    }
    
    private func crownBand(scale: Double, scaledW: Double) -> some View {
        let crH = layout.crownHeight * scale
        return Rectangle()
            .fill(Color.orange.opacity(0.2))
            .overlay(Rectangle().stroke(Color.orange.opacity(0.6), lineWidth: 0.75))
            .frame(width: scaledW, height: crH)
    }
    
    private func beamBand(scale: Double, scaledW: Double) -> some View {
        let bmH = layout.beamHeight * scale
        let yFromTop = layout.beamTopFromCeiling * scale
        return Rectangle()
            .fill(Color.purple.opacity(0.15))
            .overlay(Rectangle().stroke(Color.purple.opacity(0.5), lineWidth: 0.5))
            .frame(width: scaledW, height: bmH)
            .offset(x: 0, y: max(0, yFromTop))
    }
    
    @ViewBuilder
    private func segmentsLayer(scale: Double, scaledH: Double) -> some View {
        ZStack(alignment: .topLeading) {
            ForEach(layout.positionedSegments) { positioned in
                segmentView(positioned: positioned, wallHeight: scaledH, scale: scale)
                    .offset(x: positioned.xInches * scale, y: 0)
            }
        }
    }
    
    @ViewBuilder
    private func segmentView(
        positioned: WallElevationLayout.PositionedSegment,
        wallHeight: Double,
        scale: Double
    ) -> some View {
        let seg = positioned.segment
        let width = positioned.widthInches * scale
        
        switch seg.kind {
        case .windowUnit, .door, .opening:
            openingSegmentView(segment: seg, width: width, wallHeight: wallHeight, scale: scale)
        case .column:
            columnView(segment: seg, width: width, wallHeight: wallHeight, scale: scale)
        case .bookcase:
            bookcaseView(segment: seg, width: width, wallHeight: wallHeight)
        case .shelf:
            shelfSegmentView(segment: seg, width: width, wallHeight: wallHeight, scale: scale)
        case .beam:
            beamSegmentView(segment: seg, width: width, wallHeight: wallHeight, scale: scale)
        case .baseboard, .crown, .trim, .casing:
            Color.clear.frame(width: width, height: wallHeight)
        case .returnZone:
            filledBar(width: width, height: wallHeight, fill: Color.blue.opacity(0.08), stroke: Color.blue.opacity(0.4), label: showsLabels ? "RZ" : nil)
        case .wallSpace:
            wallSpaceView(seg: seg, width: width, wallHeight: wallHeight)
        case .wall:
            wallView(seg: seg, width: width, wallHeight: wallHeight)
        case .alcoveOpening:
            // Step 7 — station range claimed by a room-level alcove. Draw as
            // a neutral placeholder band on the elevation; the alcove
            // renderer (Step 7b) paints the real silhouette in a later pass.
            filledBar(width: width, height: wallHeight, fill: Color.orange.opacity(0.08), stroke: Color.orange.opacity(0.4), label: showsLabels ? (seg.label.isEmpty ? "AL" : seg.label) : nil)
        }
    }
    
    private func beamSegmentView(segment: WallSegment, width: Double, wallHeight: Double, scale: Double) -> some View {
        // Beam segments in the horizontal chain occupy the vertical band where the beam actually sits.
        // Height = beamHeight from defaults. Vertical position depends on BeamPosition:
        //   .onTopOfColumns: beam bottom = columnHeight, extends up to columnHeight + beamHeight (may reach ceiling)
        //   .wedgedBetween:  same vertical extents but rendered narrower to sit only between the two adjacent verticals visually (still full slot here)
        //   .ceilingHung:    beam top = ceiling, beam bottom = ceiling - beamHeight (no column support)
        let beamH = max(0, layout.beamHeight * scale)
        let colH = max(0, layout.defaults.columnHeight * scale)
        let position = segment.beamPosition ?? .onTopOfColumns
        
        let yTop: Double
        switch position {
        case .onTopOfColumns:
            // Beam bottom at column top. yTop measured from top of wall = wallHeight - (colH + beamH)
            yTop = max(0, wallHeight - colH - beamH)
        case .wedgedBetween:
            // Same as onTopOfColumns for placement, but conceptually only spans between adjacent walls/columns
            yTop = max(0, wallHeight - colH - beamH)
        case .ceilingHung:
            // Beam hugs the ceiling
            yTop = 0
        }
        
        let label = showsLabels ? (segment.label.isEmpty ? "BM" : segment.label) : nil
        return Rectangle()
            .fill(Color.purple.opacity(0.3))
            .overlay(
                ZStack {
                    Rectangle().stroke(Color.purple.opacity(0.7), lineWidth: 1)
                    labelOverlay(label: label)
                }
            )
            .frame(width: width, height: beamH)
            .offset(y: yTop)
    }
    
    private func columnView(segment: WallSegment, width: Double, wallHeight: Double, scale: Double) -> some View {
        // A column stands on the floor. Its height comes from RoomDefaults.columnHeight.
        // If that value is less than the wall's full height, the column stops short — creating room for the beam above it.
        let colH = max(0, layout.defaults.columnHeight * scale)
        let clampedH = min(colH, wallHeight)
        let yOffset = wallHeight - clampedH
        let label = showsLabels ? segment.label : nil
        let isShared = segment.isSharedCorner ?? false
        return Rectangle()
            .fill(Color.gray.opacity(0.55))
            .overlay(
                ZStack {
                    Rectangle().stroke(isShared ? Color.orange : Color.gray, lineWidth: isShared ? 1.5 : 1)
                    labelOverlay(label: label)
                    if isShared {
                        VStack {
                            HStack {
                                Spacer()
                                Text("S")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 3)
                                    .padding(.vertical, 1)
                                    .background(
                                        RoundedRectangle(cornerRadius: 3)
                                            .fill(Color.orange)
                                    )
                                    .padding(2)
                            }
                            Spacer()
                        }
                    }
                }
            )
            .frame(width: width, height: clampedH)
            .offset(y: yOffset)
    }
    
    private func filledBar(width: Double, height: Double, fill: Color, stroke: Color, label: String?) -> some View {
        Rectangle()
            .fill(fill)
            .overlay(
                ZStack {
                    Rectangle().stroke(stroke, lineWidth: 1)
                    labelOverlay(label: label)
                }
            )
            .frame(width: width, height: height)
    }
    
    @ViewBuilder
    private func labelOverlay(label: String?) -> some View {
        if let label = label, !label.isEmpty {
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.primary)
                .padding(.horizontal, 3)
                .padding(.vertical, 1)
                .background(Color(.systemBackground).opacity(0.85))
        }
    }
    
    private func wallSpaceView(seg: WallSegment, width: Double, wallHeight: Double) -> some View {
        let text = seg.label.isEmpty ? "WS" : seg.label
        return Rectangle()
            .fill(Color.clear)
            .overlay(
                Group {
                    if showsLabels {
                        Text(text)
                            .font(.system(size: 8))
                            .foregroundStyle(.tertiary)
                    }
                }
            )
            .frame(width: width, height: wallHeight)
    }
    
    private func wallView(seg: WallSegment, width: Double, wallHeight: Double) -> some View {
        Rectangle()
            .fill(Color.gray.opacity(0.06))
            .overlay(alignment: .top) {
                if showsLabels && !seg.label.isEmpty {
                    Text(seg.label)
                        .font(.system(size: 8, weight: .medium))
                        .foregroundStyle(.secondary)
                        .padding(.top, 2)
                }
            }
            .frame(width: width, height: wallHeight)
    }
    
    private func bookcaseView(segment: WallSegment, width: Double, wallHeight: Double) -> some View {
        let shelfCount = max(1, segment.shelfCount ?? 4)
        let isFTC = segment.isFloorToCeiling ?? true
        let bookH: Double = isFTC ? wallHeight : wallHeight * 0.75
        let topOffset: Double = isFTC ? 0 : wallHeight * 0.25
        let shelfIndices: [Int] = shelfCount > 1 ? Array(1..<shelfCount) : []
        let labelText = segment.label.isEmpty ? "SH" : segment.label
        
        return ZStack(alignment: .topLeading) {
            Rectangle()
                .stroke(Color.brown.opacity(0.7), lineWidth: 1)
                .background(Color.brown.opacity(0.12))
                .frame(width: width, height: bookH)
            
            ForEach(shelfIndices, id: \.self) { i in
                shelfLine(i: i, shelfCount: shelfCount, bookH: bookH, width: width)
            }
            
            if showsLabels {
                Text(labelText)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 3)
                    .padding(.vertical, 1)
                    .background(Color(.systemBackground).opacity(0.9))
                    .offset(x: 4, y: 4)
            }
        }
        .offset(y: topOffset)
        .frame(width: width, height: wallHeight, alignment: .topLeading)
    }
    
    private func shelfLine(i: Int, shelfCount: Int, bookH: Double, width: Double) -> some View {
        let y = bookH * Double(i) / Double(shelfCount)
        return Rectangle()
            .fill(Color.brown.opacity(0.5))
            .frame(width: width, height: 0.75)
            .offset(x: 0, y: y)
    }
    
    private func shelfSegmentView(segment: WallSegment, width: Double, wallHeight: Double, scale: Double) -> some View {
        // Standalone shelf(s). Segment width sets the horizontal span already.
        // Vertical placement: evenly distributed across the full wall height when Spaced Evenly is on.
        // Shelf Thickness controls the drawn plank thickness in inches (× scale).
        let count = max(1, segment.shelfCount ?? 1)
        let thicknessPx = max(1.0, (segment.shelfThickness ?? 1.5) * scale)
        let spacedEvenly = segment.shelfSpacedEvenly ?? true
        let labelText = segment.label.isEmpty ? "SF" : segment.label
        
        // Compute y positions (top of each plank) measured from top of wall.
        // Evenly: divide wall into count+1 gaps; shelves sit at gap boundaries.
        // Fallback (Spaced Evenly off): stack from bottom, 12in gaps.
        var planks: [Double] = []
        if spacedEvenly {
            let step = wallHeight / Double(count + 1)
            for i in 0..<count {
                let centerFromTop = step * Double(i + 1)
                planks.append(max(0, centerFromTop - thicknessPx / 2))
            }
        } else {
            let gapPx = 12.0 * scale
            for i in 0..<count {
                let centerFromBottom = gapPx * Double(i + 1)
                let yTop = wallHeight - centerFromBottom - thicknessPx / 2
                planks.append(max(0, yTop))
            }
        }
        
        return ZStack(alignment: .topLeading) {
            // Transparent framing rectangle so layout stays width × wallHeight
            Color.clear.frame(width: width, height: wallHeight)
            
            ForEach(Array(planks.enumerated()), id: \.offset) { _, yTop in
                Rectangle()
                    .fill(Color.brown.opacity(0.55))
                    .overlay(Rectangle().stroke(Color.brown.opacity(0.9), lineWidth: 0.75))
                    .frame(width: width, height: thicknessPx)
                    .offset(y: yTop)
            }
            
            if showsLabels {
                Text(labelText)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 3)
                    .padding(.vertical, 1)
                    .background(Color(.systemBackground).opacity(0.9))
                    .offset(x: 4, y: 4)
            }
        }
        .frame(width: width, height: wallHeight, alignment: .topLeading)
    }
    
    @ViewBuilder
    private func openingSegmentView(segment: WallSegment, width: Double, wallHeight: Double, scale: Double) -> some View {
        if let opening = segment.opening {
            openingSegmentBody(segment: segment, opening: opening, width: width, wallHeight: wallHeight, scale: scale)
        } else {
            Color.clear.frame(width: width, height: wallHeight)
        }
    }
    
    private func openingSegmentBody(segment: WallSegment, opening: OpeningSpec, width: Double, wallHeight: Double, scale: Double) -> some View {
        // `width` is the segment's full allotted slot in the wall = casingLeft + openingWidth + casingRight (already scaled to wall).
        // Draw casing + inner opening directly using the wall's own scale so nothing shrinks or grows off-ratio.
        let sillFromFloor = opening.sillOrBottomAFF
        let unitH = opening.openingHeight
        let unitW = opening.openingWidth
        let casingLeft = opening.casingLeft * scale
        let casingRight = opening.casingRight * scale
        let casingHead = opening.casingHead * scale
        let casingBottom = opening.casingBottom * scale
        let ceilingH = layout.ceilingHeight
        // Vertical placement: unit sits with its bottom at sillFromFloor (from floor).
        let unitTopFromCeiling = max(0, ceilingH - (sillFromFloor + unitH))
        let unitYTop = unitTopFromCeiling * scale
        let unitHeightScaled = unitH * scale
        let innerOpeningWidth = max(0, width - casingLeft - casingRight)
        // Casing rectangle spans the full slot horizontally and covers head casing above unit and bottom casing below sill:
        let outerY = unitYTop - casingHead
        let outerH = unitHeightScaled + casingHead + casingBottom
        let labelText = segment.label.isEmpty ? kindShort(segment.kind) : segment.label
        
        return ZStack(alignment: .topLeading) {
            Rectangle()
                .fill(Color.gray.opacity(0.04))
                .frame(width: width, height: wallHeight)
            
            // Casing (brown outline + fill) — heavy stroke so 5" trim reads clearly
            Rectangle()
                .fill(Color.brown.opacity(0.35))
                .overlay(Rectangle().stroke(Color.brown.opacity(0.95), lineWidth: 2))
                .frame(width: max(0, width), height: max(0, outerH))
                .offset(x: 0, y: max(0, outerY))
            
            // Inner opening (glass background), sized precisely by wall scale
            Rectangle()
                .fill(glassFillFor(segment.kind))
                .overlay(Rectangle().stroke(Color.teal.opacity(0.7), lineWidth: 0.75))
                .frame(width: innerOpeningWidth, height: unitHeightScaled)
                .offset(x: casingLeft, y: unitYTop)
            
            // Panel dividers (vertical mullions) + muntin grid inside each panel
            openingInternals(opening: opening, scale: scale,
                             innerX: casingLeft,
                             innerY: unitYTop,
                             innerW: innerOpeningWidth,
                             innerH: unitHeightScaled)
            
            if showsLabels {
                Text(labelText)
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 3)
                    .padding(.vertical, 1)
                    .background(Color(.systemBackground).opacity(0.9))
                    .offset(x: 2, y: unitYTop + 2)
            }
            
            // Show the opening's unit width label under the WIN for verification
            if showsLabels {
                Text(String(format: "%.2f\"", unitW))
                    .font(.system(size: 7))
                    .foregroundStyle(.tertiary)
                    .offset(x: casingLeft, y: unitYTop + unitHeightScaled + 2)
            }
        }
        .frame(width: width, height: wallHeight, alignment: .topLeading)
        .clipped()
    }
    
    // Precomputed layout for an opening's internal panels + mullions
    private struct PanelLayout {
        let panelXs: [Double]        // absolute x for each panel's left edge
        let panelWidths: [Double]    // width of each panel
        let mullionsDrawn: [Bool]    // per-gap flag, count = panelCount - 1
        let mullionW: Double         // scaled mullion width
    }
    
    private func computePanelLayout(opening: OpeningSpec, scale: Double,
                                    innerX: Double, innerW: Double) -> PanelLayout {
        let panelCount = max(1, opening.panelCount)
        let mullionW = opening.mullionWidth * scale
        
        // Determine which inter-panel mullions actually get drawn.
        // New model: opening.mullionSeams[i] controls seam i (between panel i and i+1).
        // Legacy fallback: if mullionSeams is empty, use the old per-panel adjacency rule (both On).
        var mullionsDrawn: [Bool] = []
        for i in 0..<max(0, panelCount - 1) {
            if i < opening.mullionSeams.count {
                mullionsDrawn.append(opening.mullionSeams[i])
            } else if i + 1 < opening.panels.count {
                let a = opening.panels[i].hasMullions
                let b = opening.panels[i + 1].hasMullions
                mullionsDrawn.append(a && b)
            } else {
                mullionsDrawn.append(true)
            }
        }
        let drawnMullionsCount = mullionsDrawn.filter { $0 }.count
        let panelsGlassW = max(0, innerW - Double(drawnMullionsCount) * mullionW)
        
        // Compute per-panel widths using widthShare (fallback to equal shares)
        let shares: [Double]
        if opening.panels.count == panelCount {
            let raw = opening.panels.map { max(0.0001, $0.widthShare) }
            let sum = raw.reduce(0, +)
            shares = raw.map { $0 / sum }
        } else {
            shares = Array(repeating: 1.0 / Double(panelCount), count: panelCount)
        }
        let panelWidths: [Double] = shares.map { $0 * panelsGlassW }
        
        // Compute panel x positions
        var panelXs: [Double] = []
        var cursor: Double = innerX
        for p in 0..<panelCount {
            panelXs.append(cursor)
            cursor += panelWidths[p]
            if p < mullionsDrawn.count, mullionsDrawn[p] {
                cursor += mullionW
            }
        }
        
        return PanelLayout(panelXs: panelXs,
                           panelWidths: panelWidths,
                           mullionsDrawn: mullionsDrawn,
                           mullionW: mullionW)
    }
    
    @ViewBuilder
    private func openingInternals(opening: OpeningSpec, scale: Double,
                                  innerX: Double, innerY: Double,
                                  innerW: Double, innerH: Double) -> some View {
        let pl = computePanelLayout(opening: opening, scale: scale,
                                    innerX: innerX, innerW: innerW)
        let panelCount = max(1, opening.panelCount)
        
        ZStack(alignment: .topLeading) {
            // Vertical mullions between panels (only where drawn)
            ForEach(0..<pl.mullionsDrawn.count, id: \.self) { i in
                mullionBar(index: i, pl: pl, innerY: innerY, innerH: innerH)
            }
            
            // Per-panel muntin grid (only if hasMuntinGrid)
            ForEach(0..<panelCount, id: \.self) { p in
                muntinGridForPanel(opening: opening,
                                   panelIndex: p,
                                   scale: scale,
                                   panelX: pl.panelXs[p],
                                   panelY: innerY,
                                   panelW: pl.panelWidths[p],
                                   panelH: innerH)
            }
        }
    }
    
    @ViewBuilder
    private func mullionBar(index i: Int, pl: PanelLayout, innerY: Double, innerH: Double) -> some View {
        if i < pl.mullionsDrawn.count, pl.mullionsDrawn[i], i < pl.panelXs.count, i < pl.panelWidths.count {
            let x = pl.panelXs[i] + pl.panelWidths[i]
            Rectangle()
                .fill(Color.brown.opacity(0.75))
                .frame(width: pl.mullionW, height: innerH)
                .offset(x: x, y: innerY)
        } else {
            EmptyView()
        }
    }
    
    @ViewBuilder
    private func muntinGridForPanel(opening: OpeningSpec, panelIndex: Int,
                                    scale: Double,
                                    panelX: Double, panelY: Double,
                                    panelW: Double, panelH: Double) -> some View {
        // If this panel has an entry, use its values. Otherwise fall back to opening defaults.
        let hasEntry = panelIndex < opening.panels.count
        let hasGrid: Bool = hasEntry ? opening.panels[panelIndex].hasMuntinGrid
        : (opening.muntinsRows > 0 || opening.muntinsCols > 0)
        let rowsRaw: Int = hasEntry ? opening.panels[panelIndex].muntinRows : opening.muntinsRows
        let colsRaw: Int = hasEntry ? opening.panels[panelIndex].muntinCols : opening.muntinsCols
        // If panel has hasMuntinGrid=true but rows/cols are 0, fall back to opening-level pattern
        let rows = max(0, rowsRaw > 0 ? rowsRaw : opening.muntinsRows)
        let cols = max(0, colsRaw > 0 ? colsRaw : opening.muntinsCols)
        let barW = opening.muntinWidth * scale
        
        if hasGrid, panelW > 0, panelH > 0 {
            ZStack(alignment: .topLeading) {
                // Vertical bars (cols-1 dividers)
                if cols > 1 {
                    ForEach(1..<cols, id: \.self) { c in
                        let frac = Double(c) / Double(cols)
                        Rectangle()
                            .fill(Color.brown.opacity(0.7))
                            .frame(width: max(0.5, barW), height: panelH)
                            .offset(x: panelX + panelW * frac - barW / 2, y: panelY)
                    }
                }
                // Horizontal bars (rows-1 dividers)
                if rows > 1 {
                    ForEach(1..<rows, id: \.self) { r in
                        let frac = Double(r) / Double(rows)
                        Rectangle()
                            .fill(Color.brown.opacity(0.7))
                            .frame(width: panelW, height: max(0.5, barW))
                            .offset(x: panelX, y: panelY + panelH * frac - barW / 2)
                    }
                }
            }
        }
    }
    
    private func glassFillFor(_ kind: SegmentKind) -> Color {
        switch kind {
        case .windowUnit: return Color.teal.opacity(0.18)
        case .door: return Color.green.opacity(0.15)
        case .opening: return Color.blue.opacity(0.12)
        default: return Color.gray.opacity(0.1)
        }
    }
    
    private func kindShort(_ kind: SegmentKind) -> String {
        switch kind {
        case .windowUnit: return "WIN"
        case .door: return "DR"
        case .opening: return "OP"
        default: return ""
        }
    }
    
    private func dimensionsLayer(scale: Double, scaledW: Double, scaledH: Double) -> some View {
        let widthText = String(format: "%.2f\"", layout.totalWidth)
        let heightText = String(format: "%.2f\"", layout.ceilingHeight)
        
        return ZStack(alignment: .topLeading) {
            Text(widthText)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.primary)
                .padding(.horizontal, 4)
                .padding(.vertical, 1)
                .background(Color(.systemBackground).opacity(0.9))
                .offset(x: scaledW / 2 - 24, y: scaledH + 4)
            
            Text(heightText)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.primary)
                .padding(.horizontal, 4)
                .padding(.vertical, 1)
                .background(Color(.systemBackground).opacity(0.9))
                .rotationEffect(.degrees(-90))
                .offset(x: scaledW + 4, y: scaledH / 2 - 6)
        }
    }
}

// MARK: - Wall Elevation Thumbnail

struct WallElevationThumbnail: View {
    let wall: WallSpec
    let defaults: RoomDefaults
    let verticalChain: String
    var allWalls: [WallSpec] = []
    var roomBeams: [RoomBeam] = []
    
    var body: some View {
        let layout = WallElevationBuilder.build(
            wall: wall.locked,
            defaults: defaults,
            verticalChain: verticalChain,
            allWalls: allWalls.map(\.locked),
            roomBeams: roomBeams
        )
        return WallElevationView(layout: layout, showsDimensions: false, showsLabels: false)
    }
}

// MARK: - Preview Card (used by wall form)

struct ElevationPreviewCard: View {
    let layout: WallElevationLayout
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            WallElevationView(layout: layout, showsDimensions: true, showsLabels: true)
                .frame(height: 260)
            legendRow
        }
    }
    
    private var legendRow: some View {
        HStack(spacing: 12) {
            legendSwatch(color: Color.brown.opacity(0.6), text: "Casing / Base")
            legendSwatch(color: Color.orange.opacity(0.6), text: "Crown")
            legendSwatch(color: Color.teal.opacity(0.7), text: "Window")
            legendSwatch(color: Color.green.opacity(0.7), text: "Door")
        }
        .font(.caption2)
        .foregroundStyle(.secondary)
    }
    
    private func legendSwatch(color: Color, text: String) -> some View {
        HStack(spacing: 3) {
            Rectangle().fill(color).frame(width: 10, height: 8)
            Text(text)
        }
    }
}
