import SwiftUI
import UIKit
import Photos

// MARK: - Render Frame Exporter
//
// Level 2 rendering pipeline: produce a structural FRAME image + a binary MASK image
// from the wall elevation. These two files feed an AI inpainting model:
//   - MASK: pure white on structural pixels (locked). Pure black on paintable pixels (free).
//   - FRAME: high-contrast structural silhouette on plaster wall face. Human/AI-legible.
//
// Design goals:
//   - End columns (C1, C4) never flatten into the image edge — a paintable wall gutter
//     is drawn to the left of C1 and right of C4 so they read as freestanding columns.
//   - Structural elements render as strong solids (near-black / dark brown) against pale
//     plaster, so diffusion models see unambiguous vertical bars for every column.
//   - Mask and frame are pixel-aligned — the mask is computed from the exact same
//     geometry math the frame uses.
//
// Output files (three per wall):
//   <WallName>_frame.png    — clean elevation with high-contrast structure
//   <WallName>_mask.png     — binary mask (white=structural, black=paintable)
//   <WallName>_prompt.md    — paste-ready inpainting prompt with numeric geometry

enum RenderFrameExporter {
    
    static let targetLongEdgePixels: Double = 3072
    
    // Canvas margins (in fraction of the wall's rendered width/height) that pad the
    // structural drawing inside the exported image so end columns visually detach
    // from the image edge. Paintable (black in mask) pixels sit in these margins.
    static let horizontalMarginFraction: Double = 0.04
    static let topMarginFraction: Double = 0.05
    static let bottomMarginFraction: Double = 0.18   // extra floor area for foreground moveables
    
    // Frame colors — high contrast structural solids on plaster background.
    private static let plasterColor = Color(red: 0.96, green: 0.94, blue: 0.90) // limewash off-white
    private static let columnColor  = Color(red: 0.12, green: 0.12, blue: 0.14) // near-black
    private static let shelfWoodColor = Color(red: 0.32, green: 0.22, blue: 0.14) // dark aged oak
    private static let casingColor = Color(red: 0.28, green: 0.20, blue: 0.14)
    private static let muntinColor = Color(red: 0.24, green: 0.18, blue: 0.12)
    private static let glassColor = Color(red: 0.76, green: 0.82, blue: 0.82) // muted sage-glass
    private static let beamColor = Color(red: 0.20, green: 0.15, blue: 0.10) // dark oak beam
    private static let baseboardColor = Color(red: 0.22, green: 0.16, blue: 0.11)
    private static let crownColor = Color(red: 0.22, green: 0.16, blue: 0.11)
    
    struct ExportBundle {
        let frameImage: UIImage
        let maskImage: UIImage
        let promptMarkdown: String
        let baseName: String
    }
    
    @MainActor
    static func export(
        wall: WallSpec,
        defaults: RoomDefaults,
        verticalChain: String,
        allWalls: [WallSpec],
        roomBeams: [RoomBeam],
        styleDNADescription: String? = nil
    ) -> ExportBundle {
        let layout = WallElevationBuilder.build(
            wall: wall,
            defaults: defaults,
            verticalChain: verticalChain,
            allWalls: allWalls,
            roomBeams: roomBeams
        )
        
        // Pixel canvas honors wall aspect but adds margins so end columns don't hit the image edge.
        let wallAspect = max(0.1, layout.totalWidth / layout.ceilingHeight)
        let pixelWidth: Double
        let pixelHeight: Double
        if wallAspect >= 1 {
            pixelWidth = targetLongEdgePixels
            pixelHeight = targetLongEdgePixels / wallAspect
        } else {
            pixelHeight = targetLongEdgePixels
            pixelWidth = targetLongEdgePixels * wallAspect
        }
        let size = CGSize(width: pixelWidth, height: pixelHeight)
        
        // Render FRAME (high-contrast structural silhouette on plaster).
        let frameContent = ZStack {
            Color.white
            WallElevationFrameView(layout: layout)
        }
        .frame(width: size.width, height: size.height)
        
        let frameRenderer = ImageRenderer(content: frameContent)
        frameRenderer.scale = 1.0
        frameRenderer.proposedSize = ProposedViewSize(size)
        let frameImage = frameRenderer.uiImage ?? placeholderImage(size: size, color: .white)
        
        // Render MASK (binary white-on-black, pixel-aligned with the frame).
        let maskContent = ZStack {
            Color.black
            WallElevationMaskView(layout: layout)
        }
        .frame(width: size.width, height: size.height)
        
        let maskRenderer = ImageRenderer(content: maskContent)
        maskRenderer.scale = 1.0
        maskRenderer.proposedSize = ProposedViewSize(size)
        let maskImage = maskRenderer.uiImage ?? placeholderImage(size: size, color: .black)
        
        let baseName = sanitizeFilename(wall.name.isEmpty ? "Wall" : wall.name)
        let prompt = buildPromptMarkdown(
            wall: wall,
            layout: layout,
            baseName: baseName,
            styleDNADescription: styleDNADescription
        )
        
        return ExportBundle(
            frameImage: frameImage,
            maskImage: maskImage,
            promptMarkdown: prompt,
            baseName: baseName
        )
    }
    
    /// Saves frame + mask PNGs directly to the user's Photos library. Prompts for permission on first use.
    /// Completion returns (savedCount, errorMessage). Prompt markdown is written to a temp file whose URL is returned separately.
    @MainActor
    static func saveToPhotos(_ bundle: ExportBundle, completion: @escaping (Int, String?) -> Void) {
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            guard status == .authorized || status == .limited else {
                DispatchQueue.main.async { completion(0, "Photos access denied. Enable in Settings → Privacy → Photos → Swift Playgrounds → TUDM.") }
                return
            }
            PHPhotoLibrary.shared().performChanges({
                if let framePNG = bundle.frameImage.pngData(), let img = UIImage(data: framePNG) {
                    PHAssetChangeRequest.creationRequestForAsset(from: img)
                }
                if let maskPNG = bundle.maskImage.pngData(), let img = UIImage(data: maskPNG) {
                    PHAssetChangeRequest.creationRequestForAsset(from: img)
                }
            }, completionHandler: { success, error in
                DispatchQueue.main.async {
                    if success {
                        completion(2, nil)
                    } else {
                        completion(0, error?.localizedDescription ?? "Photos save failed for an unknown reason.")
                    }
                }
            })
        }
    }
    
    /// Writes the prompt markdown to a temp file and returns its URL (Photos can't hold text files, so we still surface it separately).
    @MainActor
    static func writePromptFile(_ bundle: ExportBundle) -> URL? {
        guard let data = bundle.promptMarkdown.data(using: .utf8) else { return nil }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(bundle.baseName)_prompt.md")
        try? data.write(to: url, options: [.atomic])
        return url
    }
    
    @MainActor
    static func writeToTempFiles(_ bundle: ExportBundle) -> [URL] {
        var urls: [URL] = []
        let tmpDir = FileManager.default.temporaryDirectory
        var diagnostics: [String] = []
        diagnostics.append("Wall: \(bundle.baseName)")
        diagnostics.append("Frame image size: \(bundle.frameImage.size.width) x \(bundle.frameImage.size.height)")
        diagnostics.append("Mask image size: \(bundle.maskImage.size.width) x \(bundle.maskImage.size.height)")
        
        let framePNG = bundle.frameImage.pngData()
        diagnostics.append("Frame png data: \(framePNG?.count ?? 0) bytes")
        if let framePNG {
            let url = tmpDir.appendingPathComponent("\(bundle.baseName)_frame.png")
            do { try framePNG.write(to: url, options: [.atomic]); urls.append(url) }
            catch { diagnostics.append("Frame write error: \(error.localizedDescription)") }
        }
        let maskPNG = bundle.maskImage.pngData()
        diagnostics.append("Mask png data: \(maskPNG?.count ?? 0) bytes")
        if let maskPNG {
            let url = tmpDir.appendingPathComponent("\(bundle.baseName)_mask.png")
            do { try maskPNG.write(to: url, options: [.atomic]); urls.append(url) }
            catch { diagnostics.append("Mask write error: \(error.localizedDescription)") }
        }
        if let promptData = bundle.promptMarkdown.data(using: .utf8) {
            let url = tmpDir.appendingPathComponent("\(bundle.baseName)_prompt.md")
            do { try promptData.write(to: url, options: [.atomic]); urls.append(url) }
            catch { diagnostics.append("Prompt write error: \(error.localizedDescription)") }
        }
        
        let diagURL = tmpDir.appendingPathComponent("\(bundle.baseName)_export_log.txt")
        try? diagnostics.joined(separator: "\n").data(using: .utf8)?.write(to: diagURL, options: [.atomic])
        urls.append(diagURL)
        
        return urls
    }
    
    private static func placeholderImage(size: CGSize, color: UIColor) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            color.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
        }
    }
    
    private static func sanitizeFilename(_ name: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        return name.unicodeScalars.map { allowed.contains($0) ? Character($0) : "_" }.reduce(into: "") { $0.append($1) }
    }
    
    private static func buildPromptMarkdown(
        wall: WallSpec,
        layout: WallElevationLayout,
        baseName: String,
        styleDNADescription: String?
    ) -> String {
        let wallWidth = String(format: "%.2f", wall.totalWidth)
        let wallHeight = String(format: "%.2f", layout.ceilingHeight)
        let styleBlock = styleDNADescription ?? "[Paste your style DNA reference image and description here — palette, materials, mood, moveables to include.]"
        
        var columnCount = 0
        var columnPositions: [String] = []
        var segmentLines: [String] = []
        for p in layout.positionedSegments {
            let start = String(format: "%.2f", p.xInches)
            let end = String(format: "%.2f", p.xInches + p.widthInches)
            let label = p.segment.label.isEmpty ? p.segment.kind.rawValue : p.segment.label
            segmentLines.append("- \(label) (\(p.segment.kind.rawValue)): x = \(start)\" to \(end)\", width \(String(format: "%.2f", p.widthInches))\"")
            if p.segment.kind == .column {
                columnCount += 1
                columnPositions.append("\(label) at x = \(start)\" to \(end)\"")
            }
        }
        let segmentBlock = segmentLines.joined(separator: "\n")
        let columnBlock = columnPositions.joined(separator: "\n- ")
        
        return """
        # \(baseName) — Render Frame + Mask Prompt (Level 2 inpainting)
        
        ## Files
        - `\(baseName)_frame.png` — structural elevation (high-contrast solids on plaster)
        - `\(baseName)_mask.png` — binary mask: WHITE = structural pixels (locked), BLACK = paintable
        
        ## Wall Geometry (SACRED — do not alter)
        - Wall total width: \(wallWidth)"
        - Wall total height: \(wallHeight)"
        - Column count: \(columnCount) (MUST match exactly)
        - Column positions (left to right):
        - \(columnBlock)
        
        - Segments left to right:
        \(segmentBlock)
        
        ## Prompt (paste into inpainting tool)
        
        You are painting materials, atmosphere, and moveables onto a structural elevation frame. The FRAME image defines the wall geometry. The MASK image defines what may be repainted: only the BLACK pixels in the mask may be modified. WHITE pixels in the mask are structural and must remain exactly as the frame shows them.
        
        The wall has EXACTLY \(columnCount) vertical structural columns at the positions listed above. Every column must be preserved — none may be merged into the wall, dropped, or moved.
        
        Style DNA:
        \(styleBlock)
        
        Rules (absolute):
        - Do NOT modify masked (white) structural pixels — columns, shelves, window frame, muntins, beams, casing, baseboard, crown.
        - Do NOT add structural elements not present in the frame.
        - Do NOT remove or merge structural elements shown in the frame.
        - Column count is \(columnCount). Not \(columnCount - 1). Not \(columnCount + 1).
        - Muntin grid, panel count, column count, shelf count are exactly what the frame shows.
        - Camera is a perfect flat elevation, perpendicular to the wall. No perspective, no vanishing point.
        - Paint moveables in the black paintable region in front of the wall (foreground): sofas, chairs, coffee tables, side tables, rugs, drapery, lamps, art, plants — styled to the DNA above.
        - Paint materials (limewash, aged oak, aged limestone, linen, iron, brass, terracotta) around the structural pixels without altering their shape or edges.
        - Preserve every asymmetry in the frame.
        """
    }
}

// MARK: - Frame View (high-contrast structural silhouette)
//
// Renders structural elements as strong solids on a pale plaster background,
// with paintable-margin gutters top/left/right/bottom so end columns detach from
// the image edge and the model has floor foreground area to paint moveables into.

struct WallElevationFrameView: View {
    let layout: WallElevationLayout
    
    var body: some View {
        GeometryReader { geo in
            let (rect, scale) = wallRect(in: geo.size)
            ZStack(alignment: .topLeading) {
                // Plaster background across full canvas (paintable region).
                Rectangle().fill(RenderFrameExporter.plasterColor)
                    .frame(width: geo.size.width, height: geo.size.height)
                
                // Structural layer positioned inside the wall rect.
                structureLayer(scale: scale, wallW: rect.width, wallH: rect.height)
                    .frame(width: rect.width, height: rect.height, alignment: .topLeading)
                    .offset(x: rect.minX, y: rect.minY)
            }
        }
    }
    
    @ViewBuilder
    private func structureLayer(scale: Double, wallW: Double, wallH: Double) -> some View {
        ZStack(alignment: .topLeading) {
            // Ceiling beam band (top)
            if layout.hasBeam {
                let h = layout.beamHeight * scale
                let y = layout.beamTopFromCeiling * scale
                Rectangle().fill(RenderFrameExporter.beamColor)
                    .frame(width: wallW, height: h)
                    .offset(x: 0, y: max(0, y))
            }
            // Crown band (very top)
            if layout.hasCrown {
                let h = layout.crownHeight * scale
                Rectangle().fill(RenderFrameExporter.crownColor)
                    .frame(width: wallW, height: h)
            }
            // Baseboard band (bottom)
            if layout.hasBaseboard {
                let h = layout.baseboardHeight * scale
                Rectangle().fill(RenderFrameExporter.baseboardColor)
                    .frame(width: wallW, height: h)
                    .offset(x: 0, y: wallH - h)
            }
            // Segments
            ForEach(layout.positionedSegments) { p in
                segmentFrame(p: p, scale: scale, wallH: wallH)
                    .offset(x: p.xInches * scale, y: 0)
            }
        }
    }
    
    @ViewBuilder
    private func segmentFrame(
        p: WallElevationLayout.PositionedSegment,
        scale: Double,
        wallH: Double
    ) -> some View {
        let seg = p.segment
        let width = p.widthInches * scale
        let colH = min(wallH, max(0, layout.defaults.columnHeight * scale))
        
        switch seg.kind {
        case .column:
            Rectangle().fill(RenderFrameExporter.columnColor)
                .frame(width: width, height: colH)
                .offset(y: wallH - colH)
        case .shelf, .bookcase:
            // Full-height dark-wood block filling the niche. Individual shelves indicated
            // by darker horizontal bands, but the whole region is a strong structural silhouette.
            ZStack(alignment: .topLeading) {
                Rectangle().fill(RenderFrameExporter.shelfWoodColor.opacity(0.55))
                    .frame(width: width, height: wallH)
                shelfBars(seg: seg, width: width, height: wallH)
            }
        case .wall:
            Rectangle().fill(RenderFrameExporter.columnColor.opacity(0.85))
                .frame(width: width, height: wallH)
        case .beam:
            let beamH = max(0, layout.beamHeight * scale)
            let position = seg.beamPosition ?? .onTopOfColumns
            let yTop: Double = {
                switch position {
                case .onTopOfColumns, .wedgedBetween: return max(0, wallH - colH - beamH)
                case .ceilingHung: return 0
                }
            }()
            Rectangle().fill(RenderFrameExporter.beamColor)
                .frame(width: width, height: beamH)
                .offset(y: yTop)
        case .windowUnit, .door, .opening:
            openingFrame(seg: seg, width: width, wallH: wallH, scale: scale)
        case .wallSpace, .returnZone, .baseboard, .crown, .trim, .casing:
            Color.clear.frame(width: width, height: wallH)
        }
    }
    
    @ViewBuilder
    private func shelfBars(seg: WallSegment, width: Double, height: Double) -> some View {
        let count = max(1, seg.shelfCount ?? 5)
        let thick = max(3.0, height * 0.012)
        // Evenly distributed horizontal shelf bars.
        VStack(spacing: 0) {
            ForEach(0..<count, id: \.self) { i in
                Spacer(minLength: 0)
                Rectangle().fill(RenderFrameExporter.shelfWoodColor)
                    .frame(height: thick)
                if i == count - 1 {
                    Spacer(minLength: 0)
                }
            }
        }
        .frame(width: width, height: height)
    }
    
    @ViewBuilder
    private func openingFrame(seg: WallSegment, width: Double, wallH: Double, scale: Double) -> some View {
        if let opening = seg.opening {
            let sillFromFloor = opening.sillOrBottomAFF
            let unitH = opening.openingHeight
            let ceilingH = layout.ceilingHeight
            let unitTopFromCeiling = max(0, ceilingH - (sillFromFloor + unitH))
            let unitYTop = unitTopFromCeiling * scale
            let unitHeightScaled = unitH * scale
            let casingLeft = opening.casingLeft * scale
            let casingRight = opening.casingRight * scale
            let casingHead = opening.casingHead * scale
            let casingBottom = opening.casingBottom * scale
            let innerW = max(0, width - casingLeft - casingRight)
            let outerY = unitYTop - casingHead
            let outerH = unitHeightScaled + casingHead + casingBottom
            let casingThickness = max(3.0, min(casingLeft, casingRight, casingHead, casingBottom) * 0.9)
            
            ZStack(alignment: .topLeading) {
                // Casing outline
                Rectangle()
                    .stroke(RenderFrameExporter.casingColor, lineWidth: casingThickness)
                    .frame(width: max(0, width), height: max(0, outerH))
                    .offset(x: 0, y: max(0, outerY))
                // Glass
                Rectangle().fill(RenderFrameExporter.glassColor)
                    .frame(width: innerW, height: unitHeightScaled)
                    .offset(x: casingLeft, y: unitYTop)
                // Muntins (grid)
                muntinGrid(opening: opening,
                           innerX: casingLeft, innerY: unitYTop,
                           innerW: innerW, innerH: unitHeightScaled)
            }
        } else {
            Color.clear.frame(width: width, height: wallH)
        }
    }
    
    @ViewBuilder
    private func muntinGrid(opening: OpeningSpec, innerX: Double, innerY: Double, innerW: Double, innerH: Double) -> some View {
        let rows = max(1, opening.muntinsRows)
        let cols = max(1, opening.muntinsCols)
        let barThick = max(2.0, min(innerW, innerH) * 0.006)
        ZStack(alignment: .topLeading) {
            // Vertical muntins
            ForEach(1..<cols, id: \.self) { i in
                let x = innerW * Double(i) / Double(cols)
                Rectangle().fill(RenderFrameExporter.muntinColor)
                    .frame(width: barThick, height: innerH)
                    .offset(x: innerX + x - barThick/2, y: innerY)
            }
            // Horizontal muntins
            ForEach(1..<rows, id: \.self) { i in
                let y = innerH * Double(i) / Double(rows)
                Rectangle().fill(RenderFrameExporter.muntinColor)
                    .frame(width: innerW, height: barThick)
                    .offset(x: innerX, y: innerY + y - barThick/2)
            }
        }
    }
    
    // Compute the wall's drawable rect inside the canvas with the configured margins.
    private func wallRect(in canvas: CGSize) -> (rect: CGRect, scale: Double) {
        let hMargin = canvas.width * RenderFrameExporter.horizontalMarginFraction
        let topMargin = canvas.height * RenderFrameExporter.topMarginFraction
        let bottomMargin = canvas.height * RenderFrameExporter.bottomMarginFraction
        let availableW = canvas.width - 2 * hMargin
        let availableH = canvas.height - topMargin - bottomMargin
        let scale = min(availableW / layout.totalWidth, availableH / layout.ceilingHeight)
        let scaledW = layout.totalWidth * scale
        let scaledH = layout.ceilingHeight * scale
        let x = (canvas.width - scaledW) / 2
        let y = topMargin
        return (CGRect(x: x, y: y, width: scaledW, height: scaledH), scale)
    }
}

// MARK: - Mask View (binary white=structural, black=paintable)
//
// Uses the same wallRect + scale math as the frame view so pixels align exactly.

struct WallElevationMaskView: View {
    let layout: WallElevationLayout
    
    var body: some View {
        GeometryReader { geo in
            let (rect, scale) = wallRect(in: geo.size)
            ZStack(alignment: .topLeading) {
                // Full canvas = paintable black.
                Rectangle().fill(Color.black)
                    .frame(width: geo.size.width, height: geo.size.height)
                // Structural white shapes inside wall rect.
                structureLayer(scale: scale, wallW: rect.width, wallH: rect.height)
                    .frame(width: rect.width, height: rect.height, alignment: .topLeading)
                    .offset(x: rect.minX, y: rect.minY)
            }
        }
    }
    
    @ViewBuilder
    private func structureLayer(scale: Double, wallW: Double, wallH: Double) -> some View {
        ZStack(alignment: .topLeading) {
            // Beam band
            if layout.hasBeam {
                let h = layout.beamHeight * scale
                let y = layout.beamTopFromCeiling * scale
                Rectangle().fill(Color.white)
                    .frame(width: wallW, height: h)
                    .offset(x: 0, y: max(0, y))
            }
            // Crown
            if layout.hasCrown {
                let h = layout.crownHeight * scale
                Rectangle().fill(Color.white)
                    .frame(width: wallW, height: h)
            }
            // Baseboard
            if layout.hasBaseboard {
                let h = layout.baseboardHeight * scale
                Rectangle().fill(Color.white)
                    .frame(width: wallW, height: h)
                    .offset(x: 0, y: wallH - h)
            }
            // Segments
            ForEach(layout.positionedSegments) { p in
                segmentMask(p: p, scale: scale, wallH: wallH)
                    .offset(x: p.xInches * scale, y: 0)
            }
        }
    }
    
    @ViewBuilder
    private func segmentMask(
        p: WallElevationLayout.PositionedSegment,
        scale: Double,
        wallH: Double
    ) -> some View {
        let seg = p.segment
        let width = p.widthInches * scale
        let colH = min(wallH, max(0, layout.defaults.columnHeight * scale))
        
        switch seg.kind {
        case .column:
            Rectangle().fill(Color.white)
                .frame(width: width, height: colH)
                .offset(y: wallH - colH)
        case .shelf, .bookcase:
            Rectangle().fill(Color.white)
                .frame(width: width, height: wallH)
        case .wall:
            Rectangle().fill(Color.white)
                .frame(width: width, height: wallH)
        case .beam:
            let beamH = max(0, layout.beamHeight * scale)
            let position = seg.beamPosition ?? .onTopOfColumns
            let yTop: Double = {
                switch position {
                case .onTopOfColumns, .wedgedBetween: return max(0, wallH - colH - beamH)
                case .ceilingHung: return 0
                }
            }()
            Rectangle().fill(Color.white)
                .frame(width: width, height: beamH)
                .offset(y: yTop)
        case .windowUnit, .door, .opening:
            openingMask(seg: seg, width: width, wallH: wallH, scale: scale)
        case .wallSpace, .returnZone, .baseboard, .crown, .trim, .casing:
            Color.clear.frame(width: width, height: wallH)
        }
    }
    
    @ViewBuilder
    private func openingMask(seg: WallSegment, width: Double, wallH: Double, scale: Double) -> some View {
        if let opening = seg.opening {
            let sillFromFloor = opening.sillOrBottomAFF
            let unitH = opening.openingHeight
            let ceilingH = layout.ceilingHeight
            let unitTopFromCeiling = max(0, ceilingH - (sillFromFloor + unitH))
            let unitYTop = unitTopFromCeiling * scale
            let unitHeightScaled = unitH * scale
            let casingHead = opening.casingHead * scale
            let casingBottom = opening.casingBottom * scale
            let outerY = unitYTop - casingHead
            let outerH = unitHeightScaled + casingHead + casingBottom
            
            Rectangle().fill(Color.white)
                .frame(width: max(0, width), height: max(0, outerH))
                .offset(x: 0, y: max(0, outerY))
        } else {
            Color.clear.frame(width: width, height: wallH)
        }
    }
    
    private func wallRect(in canvas: CGSize) -> (rect: CGRect, scale: Double) {
        let hMargin = canvas.width * RenderFrameExporter.horizontalMarginFraction
        let topMargin = canvas.height * RenderFrameExporter.topMarginFraction
        let bottomMargin = canvas.height * RenderFrameExporter.bottomMarginFraction
        let availableW = canvas.width - 2 * hMargin
        let availableH = canvas.height - topMargin - bottomMargin
        let scale = min(availableW / layout.totalWidth, availableH / layout.ceilingHeight)
        let scaledW = layout.totalWidth * scale
        let scaledH = layout.ceilingHeight * scale
        let x = (canvas.width - scaledW) / 2
        let y = topMargin
        return (CGRect(x: x, y: y, width: scaledW, height: scaledH), scale)
    }
}
