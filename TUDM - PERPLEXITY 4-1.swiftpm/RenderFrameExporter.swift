import SwiftUI
import UIKit

// MARK: - Render Frame Exporter
//
// Level 2 rendering pipeline: produce a structural FRAME image + a binary MASK image
// from the wall elevation. These two files feed an AI inpainting model so structure
// stays pixel-locked (mask forbids the model from repainting structural pixels) while
// the model is free to paint materials, moveables, and atmosphere elsewhere.
//
// Output files (three per wall):
//   <WallName>_frame.png    — clean elevation, no labels, no dimensions, no purple stroke
//   <WallName>_mask.png     — white where structure lives, black elsewhere
//   <WallName>_prompt.md    — paste-ready inpainting prompt referencing frame + mask
//
// Camera: perfectly flat elevation (2D SwiftUI view snapshot). Guaranteed zero perspective.
// Resolution: 3072 px on the longest side, aspect ratio derived from the wall's own proportions.

enum RenderFrameExporter {
    
    static let targetLongEdgePixels: Double = 3072
    
    struct ExportBundle {
        let frameImage: UIImage
        let maskImage: UIImage
        let promptMarkdown: String
        let baseName: String
    }
    
    /// Produces frame + mask + prompt for the given wall.
    /// Must run on the main thread (ImageRenderer requirement).
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
        
        // Compute pixel dimensions honoring wall aspect ratio.
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
        
        // Render FRAME: existing WallElevationView with labels + dimensions off.
        let frameView = WallElevationView(layout: layout, showsDimensions: false, showsLabels: false)
            .frame(width: size.width, height: size.height)
            .background(Color(.systemBackground))
        let frameRenderer = ImageRenderer(content: frameView)
        frameRenderer.scale = 1.0
        frameRenderer.proposedSize = ProposedViewSize(size)
        let frameImage = frameRenderer.uiImage ?? UIImage()
        
        // Render MASK: dedicated mask view, pure white on structural regions, pure black elsewhere.
        let maskView = WallElevationMaskView(layout: layout)
            .frame(width: size.width, height: size.height)
            .background(Color.black)
        let maskRenderer = ImageRenderer(content: maskView)
        maskRenderer.scale = 1.0
        maskRenderer.proposedSize = ProposedViewSize(size)
        let maskImage = maskRenderer.uiImage ?? UIImage()
        
        let baseName = sanitizeFilename(wall.name.isEmpty ? "Wall" : wall.name)
        let prompt = buildPromptMarkdown(
            wall: wall,
            defaults: defaults,
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
    
    /// Writes frame + mask + prompt to temporary URLs so ShareLink / UIActivityViewController can pick them up.
    @MainActor
    static func writeToTempFiles(_ bundle: ExportBundle) -> [URL] {
        var urls: [URL] = []
        let tmpDir = FileManager.default.temporaryDirectory
        
        if let framePNG = bundle.frameImage.pngData() {
            let url = tmpDir.appendingPathComponent("\(bundle.baseName)_frame.png")
            try? framePNG.write(to: url, options: [.atomic])
            urls.append(url)
        }
        if let maskPNG = bundle.maskImage.pngData() {
            let url = tmpDir.appendingPathComponent("\(bundle.baseName)_mask.png")
            try? maskPNG.write(to: url, options: [.atomic])
            urls.append(url)
        }
        if let promptData = bundle.promptMarkdown.data(using: .utf8) {
            let url = tmpDir.appendingPathComponent("\(bundle.baseName)_prompt.md")
            try? promptData.write(to: url, options: [.atomic])
            urls.append(url)
        }
        return urls
    }
    
    private static func sanitizeFilename(_ name: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        return name.unicodeScalars.map { allowed.contains($0) ? Character($0) : "_" }.reduce(into: "") { $0.append($1) }
    }
    
    private static func buildPromptMarkdown(
        wall: WallSpec,
        defaults: RoomDefaults,
        baseName: String,
        styleDNADescription: String?
    ) -> String {
        let wallWidth = String(format: "%.2f", wall.totalWidth)
        let wallHeight = String(format: "%.2f", defaults.ceilingHeight)
        let styleBlock = styleDNADescription ?? "[Paste your style DNA reference image and description here — palette, materials, mood, moveables to include.]"
        
        var segmentLines: [String] = []
        var cursor: Double = 0
        for seg in wall.segments {
            let w = seg.resolvedWidth
            let start = String(format: "%.2f", cursor)
            let end = String(format: "%.2f", cursor + w)
            let label = seg.label.isEmpty ? seg.kind.rawValue : seg.label
            segmentLines.append("- \(label) (\(seg.kind.rawValue)): x = \(start)\" to \(end)\", width \(String(format: "%.2f", w))\"")
            cursor += w
        }
        let segmentBlock = segmentLines.joined(separator: "\n")
        
        return """
        # \(baseName) — Render Frame + Mask Prompt (Level 2 inpainting)
        
        ## Files
        
        - `\(baseName)_frame.png` — structural elevation (no labels, no dimensions)
        - `\(baseName)_mask.png` — binary mask: WHITE = structural pixels (locked), BLACK = paintable
        
        ## Wall Geometry (SACRED — do not alter)
        
        - Wall total width: \(wallWidth)"
        - Wall total height: \(wallHeight)"
        - Segments left to right (positions are inviolable):
        
        \(segmentBlock)
        
        ## Prompt (paste into inpainting tool)
        
        You are painting materials, atmosphere, and moveables onto a structural elevation frame. The FRAME image defines the wall geometry. The MASK image defines what may be repainted: only the BLACK pixels in the mask may be modified. WHITE pixels in the mask are structural and must remain exactly as the frame shows them.
        
        Style DNA:
        \(styleBlock)
        
        Rules (absolute):
        - Do NOT modify masked (white) structural pixels — columns, shelves, window frame, muntins, beams, casing.
        - Do NOT add structural elements not present in the frame.
        - Do NOT remove structural elements shown in the frame.
        - The muntin grid, panel count, column count, shelf count are exactly what the frame shows.
        - Camera is a perfect flat elevation, perpendicular to the wall. No perspective, no vanishing point.
        - Paint moveables in the black paintable region in front of the wall: sofas, chairs, coffee tables, side tables, rugs, drapery, lamps, art, plants — styled to the DNA above.
        - Paint materials (limewash, aged oak, aged limestone, linen, iron, brass, terracotta) on and around the structural pixels without altering their shape or edges.
        - Preserve every asymmetry in the frame.
        
        Deliverable: a single photorealistic editorial elevation image of the wall with correct structure preserved and materials + moveables painted in the DNA style.
        """
    }
}

// MARK: - Mask View
//
// Renders the same structural geometry as WallElevationView but as pure white shapes
// on a black background — no labels, no dimensions, no dividers. Structural elements
// covered:
//   - segments of kind: column, shelf, bookcase, wall (interior wall segment), beam
//   - opening segment casings and window frames (muntins collapsed into the frame region)
//   - ceiling beam band (from vertical chain)
//   - baseboard band
//   - crown band
//   - room beams projected onto this wall
//
// Wall space and return zones are intentionally NOT masked — they are the "paintable" area.

struct WallElevationMaskView: View {
    let layout: WallElevationLayout
    
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
        let offsetY = (size.height - scaledH) / 2
        
        return ZStack(alignment: .topLeading) {
            // Full frame is black (paintable everywhere by default).
            Rectangle().fill(Color.black)
                .frame(width: size.width, height: size.height)
            
            // White structural layer inside the wall bounds.
            ZStack(alignment: .topLeading) {
                verticalBandsMask(scale: scale, scaledW: scaledW, scaledH: scaledH)
                segmentsMask(scale: scale, scaledH: scaledH)
                roomBeamsMask(scale: scale, scaledW: scaledW, scaledH: scaledH)
            }
            .frame(width: scaledW, height: scaledH)
            .offset(x: offsetX, y: offsetY)
        }
    }
    
    private func fitScale(contentW: Double, contentH: Double, in size: CGSize) -> Double {
        let availW = Double(size.width) * 0.95
        let availH = Double(size.height) * 0.95
        return min(availW / contentW, availH / contentH)
    }
    
    // MARK: Vertical bands (baseboard, crown, ceiling beam band)
    
    @ViewBuilder
    private func verticalBandsMask(scale: Double, scaledW: Double, scaledH: Double) -> some View {
        ZStack(alignment: .topLeading) {
            if layout.hasBaseboard {
                let bbH = layout.baseboardHeight * scale
                Rectangle().fill(Color.white)
                    .frame(width: scaledW, height: bbH)
                    .offset(x: 0, y: scaledH - bbH)
            }
            if layout.hasCrown {
                let crH = layout.crownHeight * scale
                Rectangle().fill(Color.white)
                    .frame(width: scaledW, height: crH)
            }
            if layout.hasBeam {
                let bmH = layout.beamHeight * scale
                let yFromTop = layout.beamTopFromCeiling * scale
                Rectangle().fill(Color.white)
                    .frame(width: scaledW, height: bmH)
                    .offset(x: 0, y: max(0, yFromTop))
            }
        }
    }
    
    // MARK: Segments
    
    @ViewBuilder
    private func segmentsMask(scale: Double, scaledH: Double) -> some View {
        ZStack(alignment: .topLeading) {
            ForEach(layout.positionedSegments) { positioned in
                segmentMask(positioned: positioned, wallHeight: scaledH, scale: scale)
                    .offset(x: positioned.xInches * scale, y: 0)
            }
        }
    }
    
    @ViewBuilder
    private func segmentMask(
        positioned: WallElevationLayout.PositionedSegment,
        wallHeight: Double,
        scale: Double
    ) -> some View {
        let seg = positioned.segment
        let width = positioned.widthInches * scale
        let colH = max(0, layout.defaults.columnHeight * scale)
        
        switch seg.kind {
        case .column:
            let clampedH = min(colH, wallHeight)
            let yOffset = wallHeight - clampedH
            Rectangle().fill(Color.white)
                .frame(width: width, height: clampedH)
                .offset(y: yOffset)
        case .shelf, .bookcase:
            // Full-height column-flanked niche region masked.
            Rectangle().fill(Color.white)
                .frame(width: width, height: wallHeight)
        case .wall:
            // Interior wall (solid segment) is structural.
            Rectangle().fill(Color.white)
                .frame(width: width, height: wallHeight)
        case .beam:
            let beamH = max(0, layout.beamHeight * scale)
            let position = seg.beamPosition ?? .onTopOfColumns
            let yTop: Double = {
                switch position {
                case .onTopOfColumns, .wedgedBetween:
                    return max(0, wallHeight - colH - beamH)
                case .ceilingHung:
                    return 0
                }
            }()
            Rectangle().fill(Color.white)
                .frame(width: width, height: beamH)
                .offset(y: yTop)
        case .windowUnit, .door, .opening:
            openingMask(segment: seg, width: width, wallHeight: wallHeight, scale: scale)
        case .wallSpace, .returnZone, .baseboard, .crown, .trim, .casing:
            // Paintable — leave black.
            Color.clear.frame(width: width, height: wallHeight)
        }
    }
    
    @ViewBuilder
    private func openingMask(segment: WallSegment, width: Double, wallHeight: Double, scale: Double) -> some View {
        if let opening = segment.opening {
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
            
            // Mask covers the full opening slot including casing. The glass area
            // is intentionally left masked (white) so the AI doesn't try to invent
            // a window frame — inpainting will just paint sky/foliage-tone glass
            // beyond the mask boundary in v2 if needed. For now: whole slot = locked.
            Rectangle().fill(Color.white)
                .frame(width: max(0, width), height: max(0, outerH))
                .offset(x: 0, y: max(0, outerY))
        } else {
            Color.clear.frame(width: width, height: wallHeight)
        }
    }
    
    // MARK: Room beams
    
    @ViewBuilder
    private func roomBeamsMask(scale: Double, scaledW: Double, scaledH: Double) -> some View {
        let projections = layout.beamProjections
        let colH = max(0, layout.defaults.columnHeight * scale)
        ZStack(alignment: .topLeading) {
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
                Rectangle().fill(Color.white)
                    .frame(width: w, height: h)
                    .offset(x: x, y: yTop)
            }
        }
    }
}
