import SwiftUI

// MARK: - Opening Elevation Layout
// Deterministic orthographic view of a single window / door / cased opening.
// All values are in inches; scaling is handled by the container GeometryReader.

struct OpeningElevationLayout {
    let opening: OpeningSpec
    let kind: SegmentKind
    
    // Overall unit dimensions (opening only, without casing)
    var unitWidth: Double { max(0, opening.openingWidth) }
    var unitHeight: Double { max(0, opening.openingHeight) }
    
    // Full outer dimensions including casing
    var outerWidth: Double { unitWidth + opening.casingLeft + opening.casingRight }
    var outerHeight: Double { unitHeight + opening.casingHead + (kind == .door ? 0 : 0) }
    
    // Available width inside the frame for panels (subtracting vertical mullion space)
    var availablePanelWidth: Double {
        let vMulls = Double(opening.mullionsVertical)
        return max(0, unitWidth - (vMulls * opening.mullionWidth))
    }
    
    // Available height inside the frame for panels (subtracting horizontal mullion space)
    var availablePanelHeight: Double {
        let hMulls = Double(opening.mullionsHorizontal)
        return max(0, unitHeight - (hMulls * opening.mullionWidth))
    }
    
    // Effective panel shares — normalize to opening.panels or fall back to equal shares
    var effectivePanels: [WindowPanel] {
        let count = max(1, opening.panelCount)
        if opening.panels.count == count { return opening.panels }
        // Auto-generate equal-share panels if missing
        return (0..<count).map { i in
            WindowPanel(label: "P\(i + 1)", widthShare: 1, operation: .fixed, hasMuntinGrid: true)
        }
    }
    
    var sumOfShares: Double {
        let panels = effectivePanels
        let total = panels.reduce(0) { $0 + $1.widthShare }
        return total > 0 ? total : Double(max(1, panels.count))
    }
    
    // Compute panel widths in inches based on width shares and available width
    func panelInches() -> [Double] {
        let panels = effectivePanels
        let total = sumOfShares
        let avail = availablePanelWidth
        return panels.map { avail * ($0.widthShare / total) }
    }
    
    // Compute the X position (in inches, from left edge of unit) where each vertical mullion sits.
    // Returns the position AND whether that mullion should be drawn (per-panel adjacency rule).
    func verticalMullionPlacements() -> [(x: Double, visible: Bool)] {
        switch opening.mullionLayoutPreset {
        case .none:
            return []
        case .grid, .custom:
            let widths = panelInches()
            let panels = effectivePanels
            guard widths.count > 1 else { return [] }
            var placements: [(x: Double, visible: Bool)] = []
            var cursor: Double = 0
            for i in 0..<(widths.count - 1) {
                cursor += widths[i]
                let leftHas = i < panels.count ? panels[i].hasMullions : true
                let rightHas = (i + 1) < panels.count ? panels[i + 1].hasMullions : true
                let visible = leftHas && rightHas
                placements.append((x: cursor, visible: visible))
                cursor += opening.mullionWidth
            }
            return placements
        }
    }
    
    // Backward-compat helper for anywhere that used verticalMullionPositions.
    func verticalMullionPositions() -> [Double] {
        verticalMullionPlacements().map { $0.x }
    }
    
    // Compute Y positions of horizontal mullions from the top of the unit.
    // Horizontal mullions are disabled by design — muntin grids inside each panel
    // handle horizontal divisions. Returning empty prevents any horizontal bars
    // from being drawn across the whole window.
    func horizontalMullionPositions() -> [Double] {
        return []
    }
    
    // Resolve per-panel muntin rows: prefer panel value, fall back to unit-level.
    func muntinRows(forPanelIndex idx: Int) -> Int {
        let panels = effectivePanels
        guard idx >= 0, idx < panels.count else { return opening.muntinsRows }
        let pr = panels[idx].muntinRows
        return pr > 0 ? pr : opening.muntinsRows
    }
    
    // Resolve per-panel muntin cols: prefer panel value, fall back to unit-level.
    func muntinCols(forPanelIndex idx: Int) -> Int {
        let panels = effectivePanels
        guard idx >= 0, idx < panels.count else { return opening.muntinsCols }
        let pc = panels[idx].muntinCols
        return pc > 0 ? pc : opening.muntinsCols
    }
    
    // Does this panel show a muntin grid?
    func panelHasGrid(idx: Int) -> Bool {
        let panels = effectivePanels
        guard idx >= 0, idx < panels.count else { return true }
        return panels[idx].hasMuntinGrid
    }
    
    // Panel labels (used for glass overlay)
    func panelLabel(idx: Int) -> String {
        let panels = effectivePanels
        guard idx >= 0, idx < panels.count else { return "" }
        return panels[idx].label
    }
}

// MARK: - Opening Elevation View

struct OpeningElevationView: View {
    let segment: WallSegment
    var showsCasing: Bool = true
    var showsDimensions: Bool = true
    
    private var opening: OpeningSpec? { segment.opening }
    
    private var layout: OpeningElevationLayout? {
        guard let opening else { return nil }
        return OpeningElevationLayout(opening: opening, kind: segment.kind)
    }
    
    var body: some View {
        GeometryReader { geo in
            content(size: geo.size)
        }
    }
    
    @ViewBuilder
    private func content(size: CGSize) -> some View {
        if let layout = layout, layout.outerWidth > 0, layout.outerHeight > 0 {
            drawnContent(layout: layout, size: size)
        } else {
            emptyContent(size: size)
        }
    }
    
    private func drawnContent(layout: OpeningElevationLayout, size: CGSize) -> some View {
        let scale = fitScale(
            contentWidth: layout.outerWidth,
            contentHeight: layout.outerHeight,
            in: size
        )
        let scaledOuterW = layout.outerWidth * scale
        let scaledOuterH = layout.outerHeight * scale
        let offsetX = (size.width - scaledOuterW) / 2
        let offsetY = (size.height - scaledOuterH) / 2
        
        return ZStack(alignment: .topLeading) {
            Rectangle().fill(Color(.systemBackground))
            
            innerStack(layout: layout, scale: scale)
                .frame(width: scaledOuterW, height: scaledOuterH)
                .offset(x: offsetX, y: offsetY)
        }
        .frame(width: size.width, height: size.height)
    }
    
    @ViewBuilder
    private func innerStack(layout: OpeningElevationLayout, scale: Double) -> some View {
        ZStack(alignment: .topLeading) {
            casingLayer(layout: layout, scale: scale)
            frameLayer(layout: layout, scale: scale)
            panelsLayer(layout: layout, scale: scale)
            mullionsLayer(layout: layout, scale: scale)
            muntinsLayer(layout: layout, scale: scale)
            doorFeaturesLayer(layout: layout, scale: scale)
            dimensionsLayer(layout: layout, scale: scale)
        }
    }
    
    private func emptyContent(size: CGSize) -> some View {
        Text("No opening data")
            .font(.caption)
            .foregroundStyle(.tertiary)
            .frame(width: size.width, height: size.height)
    }
    
    // MARK: Scale
    
    private func fitScale(contentWidth: Double, contentHeight: Double, in size: CGSize) -> Double {
        let paddingRatio = showsDimensions ? 0.82 : 0.92
        let availableW = Double(size.width) * paddingRatio
        let availableH = Double(size.height) * paddingRatio
        let sx = availableW / contentWidth
        let sy = availableH / contentHeight
        return min(sx, sy)
    }
    
    // MARK: Layers
    
    @ViewBuilder
    private func casingLayer(layout: OpeningElevationLayout, scale: Double) -> some View {
        if showsCasing {
            casingRect(layout: layout, scale: scale)
        }
    }
    
    private func casingRect(layout: OpeningElevationLayout, scale: Double) -> some View {
        let w = layout.outerWidth * scale
        let h = layout.outerHeight * scale
        return Rectangle()
            .stroke(Color.brown.opacity(0.6), lineWidth: 1.5)
            .background(Color.brown.opacity(0.08))
            .frame(width: w, height: h)
    }
    
    private func frameLayer(layout: OpeningElevationLayout, scale: Double) -> some View {
        let unitW = layout.unitWidth * scale
        let unitH = layout.unitHeight * scale
        let dx = layout.opening.casingLeft * scale
        let dy = layout.opening.casingHead * scale
        
        return Rectangle()
            .stroke(frameColor(for: segment.kind), lineWidth: 2)
            .background(frameFill(for: segment.kind))
            .frame(width: unitW, height: unitH)
            .offset(x: showsCasing ? dx : 0, y: showsCasing ? dy : 0)
    }
    
    // MARK: Panels
    
    private func panelsLayer(layout: OpeningElevationLayout, scale: Double) -> some View {
        let dx = showsCasing ? layout.opening.casingLeft * scale : 0
        let dy = showsCasing ? layout.opening.casingHead * scale : 0
        let unitH = layout.unitHeight * scale
        let unitW = layout.unitWidth * scale
        let widths = layout.panelInches()
        let mullionW = layout.opening.mullionWidth * scale
        let positions = panelXPositions(widths: widths, mullionW: mullionW, scale: scale)
        let indices = Array(widths.indices)
        
        return ZStack(alignment: .topLeading) {
            ForEach(indices, id: \.self) { idx in
                panelAt(idx: idx, widths: widths, positions: positions, unitH: unitH, scale: scale, layout: layout)
            }
        }
        .frame(width: unitW, height: unitH, alignment: .topLeading)
        .offset(x: dx, y: dy)
    }
    
    private func panelAt(idx: Int, widths: [Double], positions: [Double], unitH: Double, scale: Double, layout: OpeningElevationLayout) -> some View {
        let inches = widths[idx]
        let scaledW = inches * scale
        let x = positions[idx]
        let label = layout.panelLabel(idx: idx)
        let hasGrid = layout.panelHasGrid(idx: idx)
        
        return panelGlass(width: scaledW, height: unitH, label: label, hasGrid: hasGrid)
            .offset(x: x, y: 0)
    }
    
    private func panelXPositions(widths: [Double], mullionW: Double, scale: Double) -> [Double] {
        var positions: [Double] = []
        var cursor: Double = 0
        for w in widths {
            positions.append(cursor)
            cursor += w * scale + mullionW
        }
        return positions
    }
    
    private func panelGlass(width: Double, height: Double, label: String, hasGrid: Bool) -> some View {
        Rectangle()
            .stroke(Color.gray.opacity(0.7), lineWidth: 1)
            .background(glassFill(for: segment.kind))
            .frame(width: width, height: height)
            .overlay(
                Group {
                    if !label.isEmpty {
                        Text(label)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }
            )
    }
    
    // MARK: Mullions
    
    private func mullionsLayer(layout: OpeningElevationLayout, scale: Double) -> some View {
        let dx = showsCasing ? layout.opening.casingLeft * scale : 0
        let dy = showsCasing ? layout.opening.casingHead * scale : 0
        let unitH = layout.unitHeight * scale
        let unitW = layout.unitWidth * scale
        let mullionW = max(1, layout.opening.mullionWidth * scale)
        let vPlacements = layout.verticalMullionPlacements()
        let hPositions = layout.horizontalMullionPositions()
        let vVisibleIdx = vPlacements.enumerated().compactMap { $0.element.visible ? $0.offset : nil }
        let hIdx = Array(hPositions.indices)
        
        return ZStack(alignment: .topLeading) {
            ForEach(vVisibleIdx, id: \.self) { i in
                verticalMullion(x: vPlacements[i].x * scale, height: unitH, width: mullionW)
            }
            ForEach(hIdx, id: \.self) { i in
                horizontalMullion(y: hPositions[i] * scale, width: unitW, height: mullionW)
            }
        }
        .frame(width: unitW, height: unitH, alignment: .topLeading)
        .offset(x: dx, y: dy)
    }
    
    private func verticalMullion(x: Double, height: Double, width: Double) -> some View {
        Rectangle()
            .fill(Color.brown.opacity(0.85))
            .frame(width: width, height: height)
            .offset(x: x, y: 0)
    }
    
    private func horizontalMullion(y: Double, width: Double, height: Double) -> some View {
        Rectangle()
            .fill(Color.brown.opacity(0.85))
            .frame(width: width, height: height)
            .offset(x: 0, y: y)
    }
    
    // MARK: Muntins (per-panel)
    
    @ViewBuilder
    private func muntinsLayer(layout: OpeningElevationLayout, scale: Double) -> some View {
        if segment.kind == .windowUnit || segment.kind == .opening {
            muntinsGrid(layout: layout, scale: scale)
        }
    }
    
    private func muntinsGrid(layout: OpeningElevationLayout, scale: Double) -> some View {
        let dx = showsCasing ? layout.opening.casingLeft * scale : 0
        let dy = showsCasing ? layout.opening.casingHead * scale : 0
        let unitH = layout.unitHeight * scale
        let mullionW = layout.opening.mullionWidth * scale
        let widths = layout.panelInches()
        let positions = panelXPositions(widths: widths, mullionW: mullionW, scale: scale)
        let muntinLineW: Double = max(0.6, layout.opening.muntinWidth * scale)
        let indices = Array(widths.indices)
        
        return ZStack(alignment: .topLeading) {
            ForEach(indices, id: \.self) { idx in
                panelMuntins(
                    idx: idx,
                    widths: widths,
                    positions: positions,
                    unitH: unitH,
                    scale: scale,
                    lineW: muntinLineW,
                    layout: layout
                )
            }
        }
        .offset(x: dx, y: dy)
    }
    
    private func panelMuntins(
        idx: Int,
        widths: [Double],
        positions: [Double],
        unitH: Double,
        scale: Double,
        lineW: Double,
        layout: OpeningElevationLayout
    ) -> some View {
        // Always render; when hasGrid is false the bars have zero thickness (invisible)
        // to avoid a structural view-tree change on toggle.
        let effectiveLineW = layout.panelHasGrid(idx: idx) ? lineW : 0
        return panelMuntinBars(
            idx: idx,
            widths: widths,
            positions: positions,
            unitH: unitH,
            lineW: effectiveLineW,
            layout: layout
        )
    }
    
    private func panelMuntinBars(
        idx: Int,
        widths: [Double],
        positions: [Double],
        unitH: Double,
        lineW: Double,
        layout: OpeningElevationLayout
    ) -> some View {
        let x = positions[idx]
        let pointsPerInch = unitH / max(0.0001, layout.unitHeight)
        let pointWidth = widths[idx] * pointsPerInch
        let rows = layout.muntinRows(forPanelIndex: idx)
        let cols = layout.muntinCols(forPanelIndex: idx)
        let rowIndices: [Int] = rows > 0 ? Array(1...rows) : []
        let colIndices: [Int] = cols > 0 ? Array(1...cols) : []
        
        return ZStack(alignment: .topLeading) {
            ForEach(rowIndices, id: \.self) { r in
                horizontalMuntin(
                    r: r,
                    rowsPlusOne: rows + 1,
                    unitH: unitH,
                    width: pointWidth,
                    lineW: lineW,
                    x: x
                )
            }
            ForEach(colIndices, id: \.self) { c in
                verticalMuntin(
                    c: c,
                    colsPlusOne: cols + 1,
                    unitH: unitH,
                    pointWidth: pointWidth,
                    lineW: lineW,
                    x: x
                )
            }
        }
    }
    
    private func horizontalMuntin(
        r: Int,
        rowsPlusOne: Int,
        unitH: Double,
        width: Double,
        lineW: Double,
        x: Double
    ) -> some View {
        let y = unitH * Double(r) / Double(rowsPlusOne)
        return Rectangle()
            .fill(Color.gray.opacity(0.75))
            .frame(width: width, height: lineW)
            .offset(x: x, y: y)
    }
    
    private func verticalMuntin(
        c: Int,
        colsPlusOne: Int,
        unitH: Double,
        pointWidth: Double,
        lineW: Double,
        x: Double
    ) -> some View {
        let xInside = pointWidth * Double(c) / Double(colsPlusOne)
        return Rectangle()
            .fill(Color.gray.opacity(0.75))
            .frame(width: lineW, height: unitH)
            .offset(x: x + xInside, y: 0)
    }
    
    // MARK: Door features
    
    @ViewBuilder
    private func doorFeaturesLayer(layout: OpeningElevationLayout, scale: Double) -> some View {
        if segment.kind == .door, let opening = self.opening {
            doorFeatures(layout: layout, opening: opening, scale: scale)
        }
    }
    
    private func doorFeatures(layout: OpeningElevationLayout, opening: OpeningSpec, scale: Double) -> some View {
        let dx = showsCasing ? layout.opening.casingLeft * scale : 0
        let dy = showsCasing ? layout.opening.casingHead * scale : 0
        let unitW = layout.unitWidth * scale
        let unitH = layout.unitHeight * scale
        let handleX = handleXOffset(handing: opening.handing, unitW: unitW)
        
        return ZStack(alignment: .topLeading) {
            doorSwingPath(handing: opening.handing, unitW: unitW, unitH: unitH)
            Circle()
                .fill(Color.green.opacity(0.9))
                .frame(width: 4, height: 4)
                .offset(x: handleX, y: unitH * 0.5)
        }
        .frame(width: unitW, height: unitH, alignment: .topLeading)
        .offset(x: dx, y: dy)
    }
    
    private func doorSwingPath(handing: OpeningHanding, unitW: Double, unitH: Double) -> some View {
        Path { path in
            switch handing {
            case .left:
                path.move(to: CGPoint(x: 0, y: unitH))
                path.addLine(to: CGPoint(x: unitW, y: 0))
            case .right:
                path.move(to: CGPoint(x: unitW, y: unitH))
                path.addLine(to: CGPoint(x: 0, y: 0))
            case .center, .none:
                path.move(to: CGPoint(x: 0, y: unitH))
                path.addLine(to: CGPoint(x: unitW, y: 0))
            }
        }
        .stroke(Color.green.opacity(0.6), style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
    }
    
    private func handleXOffset(handing: OpeningHanding, unitW: Double) -> Double {
        switch handing {
        case .left: return unitW - 4
        case .right: return 0
        case .center, .none: return unitW * 0.5 - 2
        }
    }
    
    // MARK: Dimensions
    
    @ViewBuilder
    private func dimensionsLayer(layout: OpeningElevationLayout, scale: Double) -> some View {
        if showsDimensions {
            dimensionLabels(layout: layout, scale: scale)
        }
    }
    
    private func dimensionLabels(layout: OpeningElevationLayout, scale: Double) -> some View {
        let unitW = layout.unitWidth * scale
        let unitH = layout.unitHeight * scale
        let outerW = layout.outerWidth * scale
        let outerH = layout.outerHeight * scale
        let widthText = String(format: "%.2f\"", layout.unitWidth)
        let heightText = String(format: "%.2f\"", layout.unitHeight)
        let widthX = (outerW - unitW) / 2 + unitW / 2 - 18
        let heightY = (outerH - unitH) / 2 + unitH / 2 - 8
        
        return ZStack(alignment: .topLeading) {
            Text(widthText)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.primary)
                .padding(.horizontal, 4)
                .padding(.vertical, 1)
                .background(Color(.systemBackground).opacity(0.9))
                .offset(x: widthX, y: outerH + 2)
            
            Text(heightText)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.primary)
                .padding(.horizontal, 4)
                .padding(.vertical, 1)
                .background(Color(.systemBackground).opacity(0.9))
                .rotationEffect(.degrees(-90))
                .offset(x: outerW + 2, y: heightY)
        }
    }
    
    // MARK: - Style helpers
    
    private func frameColor(for kind: SegmentKind) -> Color {
        switch kind {
        case .windowUnit: return .teal.opacity(0.9)
        case .door: return .green.opacity(0.85)
        case .opening: return .mint.opacity(0.85)
        default: return .gray
        }
    }
    
    private func frameFill(for kind: SegmentKind) -> Color {
        switch kind {
        case .windowUnit: return .teal.opacity(0.05)
        case .door: return .green.opacity(0.05)
        case .opening: return .mint.opacity(0.05)
        default: return .clear
        }
    }
    
    private func glassFill(for kind: SegmentKind) -> Color {
        switch kind {
        case .windowUnit: return Color.blue.opacity(0.08)
        case .door: return Color.brown.opacity(0.15)
        case .opening: return Color.mint.opacity(0.05)
        default: return .clear
        }
    }
}

// MARK: - Safe subscript helper

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
