import SwiftUI
import UIKit

// MARK: - Wall photoreal renderer
//
// Given a wall + preset, this pipeline produces:
//   1. A reference PNG (the RealityKit Furnished view snapshot)
//   2. A prompt JSON describing the render request
//   3. Persistent per-wall render history
//   4. A canonical pinned render
//
// The photoreal image itself is generated OUT OF BAND by the Perplexity
// backend, not by the app. The app packages the request, exports it for
// sharing, and imports the returned PNG as the canonical render.
//
// This split is intentional: iPad Playgrounds cannot call an external
// image model. Structure and history are locked in the app; only the
// pixel generation happens externally.

// MARK: - Render request bundle

struct RenderRequestBundle: Codable {
    var wallID: String
    var wallName: String
    var wallTotalWidth: Double
    var ceilingHeight: Double
    var presetID: String
    var presetName: String
    var presetVersion: Int
    var structuralSummary: String
    var fullPrompt: String
    var referenceImageFilename: String
    var aspectRatio: String
    var modelName: String
    var createdAt: Date
    
    func toJSONData() -> Data? {
        let enc = JSONEncoder()
        enc.outputFormatting = [.prettyPrinted, .sortedKeys]
        enc.dateEncodingStrategy = .iso8601
        return try? enc.encode(self)
    }
}

// MARK: - Render history record

struct RenderHistoryRecord: Codable, Identifiable, Hashable {
    var id: UUID
    var wallID: String
    var presetID: String
    var presetName: String
    var presetVersion: Int
    var referenceImageFilename: String
    var finishedImageFilename: String?
    var promptJSONFilename: String
    var isCanonical: Bool
    var createdAt: Date
    var note: String
}

// MARK: - Structural summary generator

enum WallStructuralSummary {
    
    static func generate(wall: LockedWall, defaults: RoomDefaults) -> String {
        var lines: [String] = []
        
        lines.append("Wall width " + fmt(wall.totalWidth) + " inches, ceiling " + fmt(defaults.ceilingHeight) + " inches, beam height " + fmt(defaults.beamHeight) + " inches, baseboard " + fmt(defaults.baseboardHeight) + " inches.")
        
        // Chain summary
        var chainParts: [String] = []
        var cursor: Double = 0
        for seg in wall.segments {
            let w = seg.resolvedWidth
            let label = seg.label.isEmpty ? seg.kind.rawValue : seg.label
            chainParts.append(label + "=" + fmt(w))
            cursor += w
        }
        lines.append("Chain (left to right, inches): " + chainParts.joined(separator: " | ") + ". Total " + fmt(cursor) + ".")
        
        // Columns
        let columns = wall.segments.filter { $0.kind == .column }
        if !columns.isEmpty {
            lines.append("\(columns.count) structural columns, each protruding into the room.")
        }
        
        // Shelf bays
        let shelfBays = wall.segments.filter { $0.kind == .shelf }
        if !shelfBays.isEmpty {
            let widths = shelfBays.map { fmt($0.resolvedWidth) }.joined(separator: " and ")
            let shelfCounts = shelfBays.map { $0.shelfCount ?? 4 }
            let allSame = Set(shelfCounts).count == 1
            if allSame, let count = shelfCounts.first {
                lines.append("\(shelfBays.count) shelf bays of widths " + widths + " inches, each with exactly \(count) open shelves supported directly between columns, no cabinet box, no side panels.")
            } else {
                lines.append("\(shelfBays.count) shelf bays with per-bay shelf counts " + shelfCounts.map(String.init).joined(separator: ", ") + ".")
            }
        }
        
        // Returns
        let returns = wall.segments.filter { $0.kind == .returnZone }
        if !returns.isEmpty {
            let widths = returns.map { fmt($0.resolvedWidth) }.joined(separator: " and ")
            lines.append("\(returns.count) plaster wall returns of widths " + widths + " inches, flush with the wall plane.")
        }
        
        // Windows
        let windows = wall.segments.filter { $0.kind == .windowUnit }
        for w in windows {
            guard let op = w.opening else { continue }
            var winDesc = "Window " + fmt(op.openingWidth) + " x " + fmt(op.openingHeight) + " inches, sill at " + fmt(op.sillOrBottomAFF) + " inches, head at " + fmt(op.sillOrBottomAFF + op.openingHeight) + " inches."
            if !op.panels.isEmpty {
                let split = op.panels.map { fmt($0.widthShare) }.joined(separator: " / ")
                winDesc += " Panel split " + split + "."
                let gridded = op.panels.filter { $0.hasMuntinGrid }
                if !gridded.isEmpty {
                    winDesc += " Side lights carry a \(op.muntinsCols) by \(op.muntinsRows) muntin grid. Center panel is clear."
                }
            }
            winDesc += " Casing " + fmt(op.casingLeft) + " inches on each side, painted white."
            lines.append(winDesc)
        }
        
        // Beam
        if wall.segments.contains(where: { $0.kind == .beam }) {
            lines.append("Wood beam header spans the full top of the wall, column to column.")
        }
        
        return lines.joined(separator: " ")
    }
    
    private static func fmt(_ value: Double) -> String {
        String(format: "%.2f", value)
    }
}

// MARK: - Render packager

enum WallPhotorealRenderer {
    
    static var rendersRoot: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let root = docs.appendingPathComponent("WallPhotorealRenders", isDirectory: true)
        if !FileManager.default.fileExists(atPath: root.path) {
            try? FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        }
        return root
    }
    
    static func wallFolder(wallID: String) -> URL {
        let f = rendersRoot.appendingPathComponent(wallID, isDirectory: true)
        if !FileManager.default.fileExists(atPath: f.path) {
            try? FileManager.default.createDirectory(at: f, withIntermediateDirectories: true)
        }
        return f
    }
    
    static func historyURL(wallID: String) -> URL {
        wallFolder(wallID: wallID).appendingPathComponent("history.json")
    }
    
    static func loadHistory(wallID: String) -> [RenderHistoryRecord] {
        let url = historyURL(wallID: wallID)
        guard let data = try? Data(contentsOf: url),
              let records = try? JSONDecoder().decode([RenderHistoryRecord].self, from: data)
        else { return [] }
        return records.sorted { $0.createdAt > $1.createdAt }
    }
    
    static func saveHistory(_ records: [RenderHistoryRecord], wallID: String) {
        let enc = JSONEncoder()
        enc.outputFormatting = [.prettyPrinted, .sortedKeys]
        enc.dateEncodingStrategy = .iso8601
        if let data = try? enc.encode(records) {
            try? data.write(to: historyURL(wallID: wallID), options: .atomic)
        }
    }
    
    static func canonical(wallID: String) -> RenderHistoryRecord? {
        loadHistory(wallID: wallID).first { $0.isCanonical }
    }
    
    static func setCanonical(recordID: UUID, wallID: String) {
        var records = loadHistory(wallID: wallID)
        for i in records.indices {
            records[i].isCanonical = (records[i].id == recordID)
        }
        saveHistory(records, wallID: wallID)
    }
    
    // MARK: Snapshot the Furnished view
    //
    // Uses UIGraphicsImageRenderer + drawHierarchy(afterScreenUpdates:true)
    // on a temporary UIHostingController hosted in an offscreen UIWindow.
    // The window must be attached to a scene and made key so RealityKit
    // will actually render a frame; we then let the runloop tick a few
    // times to let RealityView build its scene and composite one frame.
    
    @MainActor
    static func snapshotFurnishedView(wall: LockedWall,
                                      defaults: RoomDefaults,
                                      size: CGSize = CGSize(width: 1600, height: 900),
                                      warmupTicks: Int = 16) async -> UIImage? {
        // Find an active window scene to host the offscreen window in.
        let scene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first(where: { $0.activationState == .foregroundActive })
            ?? UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
        guard let windowScene = scene else { return nil }
        
        // Offscreen window at the requested render size.
        let offscreenWindow = UIWindow(windowScene: windowScene)
        offscreenWindow.frame = CGRect(origin: .zero, size: size)
        offscreenWindow.windowLevel = .normal - 1
        offscreenWindow.isHidden = false
        offscreenWindow.alpha = 0.01 // effectively invisible but composited
        
        // Host the Furnished view. Force fixed frame so layout matches.
        let host = UIHostingController(
            rootView: WallFurnitureRealityPreview(wall: wall, defaults: defaults)
                .frame(width: size.width, height: size.height)
                .background(Color(white: 0.95))
        )
        host.view.frame = CGRect(origin: .zero, size: size)
        host.view.backgroundColor = UIColor(white: 0.95, alpha: 1.0)
        offscreenWindow.rootViewController = host
        offscreenWindow.makeKeyAndVisible()
        
        // Force layout, then let the runloop tick so RealityView can
        // build the scene, allocate its Metal drawable, and render.
        host.view.setNeedsLayout()
        host.view.layoutIfNeeded()
        
        for _ in 0..<warmupTicks {
            try? await Task.sleep(nanoseconds: 50_000_000) // 50ms per tick
            host.view.setNeedsLayout()
            host.view.layoutIfNeeded()
        }
        
        // Snapshot the composited view hierarchy.
        let format = UIGraphicsImageRendererFormat()
        format.scale = 2.0
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        let image = renderer.image { _ in
            host.view.drawHierarchy(in: CGRect(origin: .zero, size: size),
                                    afterScreenUpdates: true)
        }
        
        // Tear down the offscreen window.
        offscreenWindow.isHidden = true
        offscreenWindow.rootViewController = nil
        
        return image
    }
    
    // MARK: Mask cache
    //
    // The structural mask only depends on the wall's chain and the room
    // defaults. Cache by (wallID + structuralFingerprint) so repeated
    // renders of the same wall skip the Core Graphics draw entirely.
    
    private static var maskCache: [String: UIImage] = [:]
    
    private static func maskCacheKey(wall: LockedWall, defaults: RoomDefaults) -> String {
        var chain = ""
        for seg in wall.segments {
            chain += "\(seg.kind.rawValue):\(String(format: "%.3f", seg.resolvedWidth));"
            if let op = seg.opening {
                chain += "op:\(String(format: "%.2f", op.openingWidth))x\(String(format: "%.2f", op.openingHeight))@\(String(format: "%.2f", op.sillOrBottomAFF));"
            }
            if let sc = seg.shelfCount { chain += "sh:\(sc);" }
        }
        return "\(wall.id.uuidString)|c\(String(format: "%.2f", defaults.ceilingHeight))|b\(String(format: "%.2f", defaults.beamHeight))|bb\(String(format: "%.2f", defaults.baseboardHeight))|\(chain)"
    }
    
    // Mask resolution per speed tier. Draft/Standard use a smaller mask
    // to reduce img2img upload + attention cost; Final uses the full mask.
    private static func maskSize(for speed: RenderSpeed?) -> CGSize {
        switch speed ?? .final {
        case .draft, .standard: return CGSize(width: 1024, height: 576)
        case .final:            return CGSize(width: 1600, height: 900)
        }
    }
    
    static func clearMaskCache() {
        maskCache.removeAll()
    }
    
    // MARK: Structural mask snapshot (the img2img reference)
    //
    // Renders the wall as a flat-shaded dimensioned elevation using pure
    // Core Graphics — no RealityKit, no SwiftUI. This is what the AI
    // model receives as the img2img reference image, so it treats every
    // zone boundary, column position, shelf edge, window mullion, and
    // furniture silhouette as fixed geometry to paint on top of.
    //
    // Compared to a RealityKit snapshot this is deterministic, safe to
    // call off-main-actor-free paths, and produces a CAD-looking mask
    // that gpt_image_2 does not try to sample as a photograph.
    
    static func snapshotStructuralMask(wall: LockedWall,
                                       defaults: RoomDefaults,
                                       size: CGSize = CGSize(width: 1600, height: 900)) -> UIImage? {
        let key = maskCacheKey(wall: wall, defaults: defaults) + "|\(Int(size.width))x\(Int(size.height))"
        if let hit = maskCache[key] { return hit }
        let image = renderStructuralMask(wall: wall, defaults: defaults, size: size)
        if let image = image { maskCache[key] = image }
        return image
    }
    
    private static func renderStructuralMask(wall: LockedWall,
                                             defaults: RoomDefaults,
                                             size: CGSize) -> UIImage? {
        // Palette — flat, high-contrast, easy for the model to read as zones.
        let bgColor       = UIColor(red: 0.961, green: 0.941, blue: 0.910, alpha: 1)
        let columnColor   = UIColor(red: 0.235, green: 0.216, blue: 0.196, alpha: 1)
        let bayColor      = UIColor(red: 0.667, green: 0.745, blue: 0.647, alpha: 1)
        let narrowColor   = UIColor(red: 0.784, green: 0.745, blue: 0.647, alpha: 1)
        let beamColor     = UIColor(red: 0.392, green: 0.275, blue: 0.176, alpha: 1)
        let shelfColor    = UIColor(red: 0.392, green: 0.275, blue: 0.176, alpha: 1)
        let floorColor    = UIColor(red: 0.549, green: 0.392, blue: 0.235, alpha: 1)
        let winFrameColor = UIColor(red: 0.961, green: 0.961, blue: 0.941, alpha: 1)
        let winGlassColor = UIColor(red: 0.725, green: 0.804, blue: 0.863, alpha: 1)
        let sofaColor     = UIColor(red: 0.863, green: 0.784, blue: 0.667, alpha: 1)
        let sofaBackColor = UIColor(red: 0.902, green: 0.843, blue: 0.745, alpha: 1)
        let sideColor     = UIColor(red: 0.549, green: 0.431, blue: 0.294, alpha: 1)
        let coffeeColor   = UIColor(red: 0.392, green: 0.275, blue: 0.176, alpha: 1)
        let outlineColor  = UIColor(red: 0.118, green: 0.118, blue: 0.118, alpha: 1)
        
        let totalWidthInches = max(wall.totalWidth, 1)
        let ceilingInches = max(defaults.ceilingHeight, 1)
        
        // Vertical layout (inches, from top).
        let beamBottomIn: CGFloat = CGFloat(defaults.beamHeight > 0 ? defaults.beamHeight : 8)
        let baseCapIn: CGFloat = CGFloat(defaults.baseboardHeight > 0 ? defaults.baseboardHeight : 6)
        let floorTopIn: CGFloat = CGFloat(ceilingInches) - baseCapIn
        
        let format = UIGraphicsImageRendererFormat()
        format.scale = 2.0
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        
        return renderer.image { ctx in
            let cg = ctx.cgContext
            let W = size.width
            let H = size.height
            
            // Convert inches to pixels for both axes.
            let xForInches: (CGFloat) -> CGFloat = { inches in W * inches / CGFloat(totalWidthInches) }
            let yForInches: (CGFloat) -> CGFloat = { inches in H * inches / CGFloat(ceilingInches) }
            
            // Background.
            cg.setFillColor(bgColor.cgColor)
            cg.fill(CGRect(x: 0, y: 0, width: W, height: H))
            
            // Precompute segment ranges by walking the chain in station order.
            struct Slot { let seg: WallSegment; let x0: CGFloat; let x1: CGFloat }
            var cursorIn: CGFloat = 0
            var slots: [Slot] = []
            for seg in wall.segments {
                let w = CGFloat(seg.resolvedWidth)
                slots.append(Slot(seg: seg, x0: xForInches(cursorIn), x1: xForInches(cursorIn + w)))
                cursorIn += w
            }
            
            // Draw wall zones full-height so nothing peeks through.
            for slot in slots {
                let rect = CGRect(x: slot.x0, y: 0, width: slot.x1 - slot.x0, height: H)
                switch slot.seg.kind {
                case .column:
                    cg.setFillColor(columnColor.cgColor)
                    cg.fill(rect)
                case .returnZone:
                    cg.setFillColor(narrowColor.cgColor)
                    cg.fill(rect)
                case .shelf, .bookcase, .wallSpace, .wall:
                    cg.setFillColor(bayColor.cgColor)
                    cg.fill(rect)
                case .windowUnit, .door, .opening, .alcoveOpening:
                    // Background wall behind the opening — use bay color so the frame reads.
                    cg.setFillColor(bayColor.cgColor)
                    cg.fill(rect)
                default:
                    cg.setFillColor(bgColor.cgColor)
                    cg.fill(rect)
                }
            }
            
            // Beam header across the full frame width, above every column.
            cg.setFillColor(beamColor.cgColor)
            cg.fill(CGRect(x: 0, y: 0, width: W, height: yForInches(beamBottomIn)))
            cg.setStrokeColor(outlineColor.cgColor)
            cg.setLineWidth(2)
            cg.stroke(CGRect(x: 0, y: yForInches(beamBottomIn) - 1, width: W, height: 2))
            
            // Floor cap across the full frame width.
            cg.setFillColor(floorColor.cgColor)
            cg.fill(CGRect(x: 0, y: yForInches(floorTopIn), width: W, height: yForInches(CGFloat(ceilingInches)) - yForInches(floorTopIn)))
            
            // Shelves inside each shelf/bookcase slot.
            for slot in slots where slot.seg.kind == .shelf || slot.seg.kind == .bookcase {
                let count = max(2, slot.seg.shelfCount ?? 4) + 1  // shelves + base cap
                let topIn = beamBottomIn + 2
                let botIn = floorTopIn - 1
                let shelfH: CGFloat = 1.5
                for i in 0..<count {
                    let t = CGFloat(i) / CGFloat(count - 1)
                    let cyIn = topIn + t * (botIn - topIn)
                    cg.setFillColor(shelfColor.cgColor)
                    cg.fill(CGRect(x: slot.x0 + 4, y: yForInches(cyIn), width: slot.x1 - slot.x0 - 8, height: yForInches(cyIn + shelfH) - yForInches(cyIn)))
                    cg.setStrokeColor(outlineColor.cgColor)
                    cg.setLineWidth(1)
                    cg.stroke(CGRect(x: slot.x0 + 4, y: yForInches(cyIn), width: slot.x1 - slot.x0 - 8, height: yForInches(cyIn + shelfH) - yForInches(cyIn)))
                }
            }
            
            // Windows inside each windowUnit slot.
            for slot in slots where slot.seg.kind == .windowUnit {
                guard let op = slot.seg.opening else { continue }
                let sillIn = CGFloat(op.sillOrBottomAFF)
                let headIn = CGFloat(op.sillOrBottomAFF + op.openingHeight)
                let windowTopIn = CGFloat(ceilingInches) - headIn
                let windowBotIn = CGFloat(ceilingInches) - sillIn
                let casingPx: CGFloat = xForInches(CGFloat(max(op.casingLeft, 2)))
                
                let winRect = CGRect(x: slot.x0, y: yForInches(windowTopIn), width: slot.x1 - slot.x0, height: yForInches(windowBotIn) - yForInches(windowTopIn))
                cg.setFillColor(winFrameColor.cgColor)
                cg.fill(winRect)
                
                let glassRect = winRect.insetBy(dx: casingPx, dy: casingPx)
                cg.setFillColor(winGlassColor.cgColor)
                cg.fill(glassRect)
                
                // Panel split — draw vertical dividers at each panel boundary.
                if !op.panels.isEmpty {
                    var cursorX = glassRect.minX
                    let totalShare = op.panels.reduce(0.0) { $0 + $1.widthShare }
                    for (idx, panel) in op.panels.enumerated() {
                        let panelW = glassRect.width * CGFloat(panel.widthShare / max(totalShare, 0.0001))
                        if idx > 0 {
                            cg.setFillColor(winFrameColor.cgColor)
                            cg.fill(CGRect(x: cursorX - 3, y: glassRect.minY, width: 6, height: glassRect.height))
                        }
                        // Muntin grid for panels flagged for it.
                        if panel.hasMuntinGrid {
                            let rows = max(1, op.muntinsRows)
                            let cols = max(1, op.muntinsCols)
                            cg.setFillColor(winFrameColor.cgColor)
                            for c in 1..<cols {
                                let mx = cursorX + panelW * CGFloat(c) / CGFloat(cols)
                                cg.fill(CGRect(x: mx - 1.5, y: glassRect.minY, width: 3, height: glassRect.height))
                            }
                            for r in 1..<rows {
                                let my = glassRect.minY + glassRect.height * CGFloat(r) / CGFloat(rows)
                                cg.fill(CGRect(x: cursorX, y: my - 1.5, width: panelW, height: 3))
                            }
                        }
                        cursorX += panelW
                    }
                } else {
                    // Fallback: single sash, treat as 6-over-6 double-hung.
                    let midY = glassRect.midY
                    let midX = glassRect.midX
                    cg.setFillColor(winFrameColor.cgColor)
                    cg.fill(CGRect(x: midX - 3, y: glassRect.minY, width: 6, height: glassRect.height))
                    cg.fill(CGRect(x: glassRect.minX, y: midY - 3, width: glassRect.width, height: 6))
                }
            }
            
            // Compute the window centerline for furniture placement.
            var windowCenterX: CGFloat = W * 0.5
            for slot in slots where slot.seg.kind == .windowUnit {
                windowCenterX = (slot.x0 + slot.x1) / 2
                break
            }
            
            // Sofa silhouette centered on window centerline.
            let sofaHalfW: CGFloat = W * 0.28
            let sofaTopY = yForInches(CGFloat(ceilingInches) * 0.55)
            let sofaBotY = yForInches(floorTopIn - 4)
            let sofaRect = CGRect(x: windowCenterX - sofaHalfW, y: sofaTopY, width: sofaHalfW * 2, height: sofaBotY - sofaTopY)
            cg.setFillColor(sofaColor.cgColor)
            cg.fill(sofaRect)
            cg.setStrokeColor(outlineColor.cgColor)
            cg.setLineWidth(2)
            cg.stroke(sofaRect)
            cg.setFillColor(sofaBackColor.cgColor)
            cg.fill(CGRect(x: sofaRect.minX + 12, y: sofaRect.minY + 8, width: sofaRect.width - 24, height: sofaRect.height * 0.5))
            
            // Side tables outside the sofa arms.
            let drumHalf: CGFloat = W * 0.028
            let drumY0 = yForInches(floorTopIn - 24)
            let drumY1 = yForInches(floorTopIn - 4)
            for dx: CGFloat in [sofaRect.minX - drumHalf * 3, sofaRect.maxX + drumHalf * 3] {
                let rect = CGRect(x: dx - drumHalf, y: drumY0, width: drumHalf * 2, height: drumY1 - drumY0)
                cg.setFillColor(sideColor.cgColor)
                cg.fill(rect)
                cg.setStrokeColor(outlineColor.cgColor)
                cg.setLineWidth(2)
                cg.stroke(rect)
            }
            
            // Round pedestal coffee table centered on sofa.
            let coffeeHalf: CGFloat = W * 0.08
            let coffeeY0 = yForInches(floorTopIn - 16)
            let coffeeY1 = yForInches(floorTopIn - 2)
            let coffeeRect = CGRect(x: windowCenterX - coffeeHalf, y: coffeeY0, width: coffeeHalf * 2, height: coffeeY1 - coffeeY0)
            cg.setFillColor(coffeeColor.cgColor)
            cg.fillEllipse(in: coffeeRect)
            cg.setStrokeColor(outlineColor.cgColor)
            cg.setLineWidth(2)
            cg.strokeEllipse(in: coffeeRect)
            
            // Zone labels overlaid on the beam so the model can read them.
            let paragraph = NSMutableParagraphStyle()
            paragraph.alignment = .center
            let labelAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 22),
                .foregroundColor: UIColor.white,
                .paragraphStyle: paragraph
            ]
            let pctAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 14),
                .foregroundColor: UIColor.white,
                .paragraphStyle: paragraph
            ]
            for slot in slots {
                let cx = (slot.x0 + slot.x1) / 2
                let label = slot.seg.label.isEmpty ? slot.seg.kind.rawValue : slot.seg.label
                let pct = 100 * (slot.x1 - slot.x0) / W
                let labelString = NSString(string: label)
                let pctString = NSString(string: String(format: "%.1f%%", pct))
                let labelBox = CGRect(x: cx - 60, y: 4, width: 120, height: 26)
                let pctBox = CGRect(x: cx - 60, y: 30, width: 120, height: 20)
                labelString.draw(in: labelBox, withAttributes: labelAttrs)
                pctString.draw(in: pctBox, withAttributes: pctAttrs)
            }
        }
    }
    
    // MARK: Preview a render (no writes)
    //
    // Runs the auto-snapshot and composes the prompt, but writes
    // nothing to disk. Used by the UI to show an inline preview
    // before the user commits to Share + Save.
    
    struct PreviewResult {
        var referenceImage: UIImage?
        var promptJSON: Data
        var structuralSummary: String
        var fullPrompt: String
        var preset: PhotorealPreset
    }
    
    @MainActor
    static func previewRequest(wall: LockedWall,
                               defaults: RoomDefaults,
                               preset: PhotorealPreset,
                               speed: RenderSpeed? = nil,
                               autoSnapshot: Bool = true) async -> PreviewResult? {
        // Structural mask (Core Graphics) is the img2img reference now.
        // Falls back to the RealityView snapshot only if the caller asks
        // for it explicitly by setting autoSnapshot to false and passing
        // a manual referenceImage via packageRequest.
        // Non-final tiers use a smaller mask (2.4x less pixel data through
        // the img2img channel) since it's a flat schematic anyway.
        let maskSize = maskSize(for: speed)
        let snapshot: UIImage? = autoSnapshot
            ? snapshotStructuralMask(wall: wall, defaults: defaults, size: maskSize)
            : nil
        
        let structural = WallStructuralSummary.generate(wall: wall, defaults: defaults)
        let detail = speed?.promptDetail ?? .full
        let fullPrompt = preset.compose(structural: structural, detail: detail)
        
        // Speed override wins over the preset's modelName so a single
        // preset can be rendered in Draft, Standard, or Final without
        // duplicating it.
        let effectiveModel = speed?.modelName ?? preset.modelName
        
        let bundle = RenderRequestBundle(
            wallID: wall.id.uuidString,
            wallName: wall.name,
            wallTotalWidth: wall.totalWidth,
            ceilingHeight: defaults.ceilingHeight,
            presetID: preset.id.uuidString,
            presetName: preset.name,
            presetVersion: preset.version,
            structuralSummary: structural,
            fullPrompt: fullPrompt,
            referenceImageFilename: "",
            aspectRatio: preset.aspectRatio,
            modelName: effectiveModel,
            createdAt: Date()
        )
        guard let promptData = bundle.toJSONData() else { return nil }
        
        return PreviewResult(
            referenceImage: snapshot,
            promptJSON: promptData,
            structuralSummary: structural,
            fullPrompt: fullPrompt,
            preset: preset
        )
    }
    
    // MARK: Batch preview (parallel)
    //
    // Renders multiple presets against the same wall concurrently. Each
    // preset's image-model call is independent, so wall-clock time for
    // N presets is roughly the time of the slowest single call, not the
    // sum. The mask is drawn once (cached) and reused across all presets.
    
    @MainActor
    static func previewBatch(wall: LockedWall,
                             defaults: RoomDefaults,
                             presets: [PhotorealPreset],
                             speed: RenderSpeed? = nil) async -> [PreviewResult] {
        // Warm the mask cache once so every parallel task hits it.
        _ = snapshotStructuralMask(wall: wall, defaults: defaults)
        
        return await withTaskGroup(of: PreviewResult?.self) { group in
            for preset in presets {
                group.addTask { @MainActor in
                    await previewRequest(wall: wall, defaults: defaults, preset: preset, speed: speed)
                }
            }
            var results: [PreviewResult] = []
            for await result in group {
                if let result = result { results.append(result) }
            }
            return results
        }
    }
    
    // MARK: Package a render request
    //
    // Attempts to auto-snapshot the Furnished view via an offscreen
    // UIHostingController + UIGraphicsImageRenderer. If the snapshot
    // fails (e.g. RealityKit did not composite in time), the caller
    // may still supply a manually-exported PNG via referenceImage.
    
    struct PackageResult {
        var referenceImageURL: URL?
        var promptJSONURL: URL
        var historyRecord: RenderHistoryRecord
    }
    
    @MainActor
    static func packageRequest(wall: LockedWall,
                               defaults: RoomDefaults,
                               preset: PhotorealPreset,
                               speed: RenderSpeed? = nil,
                               referenceImage: UIImage? = nil,
                               autoSnapshot: Bool = true,
                               note: String = "") async -> PackageResult? {
        let wallIDString = wall.id.uuidString
        let folder = wallFolder(wallID: wallIDString)
        let stamp = ISO8601DateFormatter().string(from: Date()).replacingOccurrences(of: ":", with: "-")
        
        // Resolve a reference image: explicit override, else auto-snapshot.
        let maskSize = maskSize(for: speed)
        var resolvedImage = referenceImage
        if resolvedImage == nil, autoSnapshot {
            resolvedImage = snapshotStructuralMask(wall: wall, defaults: defaults, size: maskSize)
        }
        
        let referenceFilename = "reference_" + stamp + ".png"
        var referenceURL: URL? = nil
        if let img = resolvedImage, let data = img.pngData() {
            referenceURL = folder.appendingPathComponent(referenceFilename)
            try? data.write(to: referenceURL!, options: .atomic)
        }
        
        let structural = WallStructuralSummary.generate(wall: wall, defaults: defaults)
        let detail = speed?.promptDetail ?? .full
        let fullPrompt = preset.compose(structural: structural, detail: detail)
        
        // Speed override wins over the preset's modelName.
        let effectiveModel = speed?.modelName ?? preset.modelName
        
        let bundle = RenderRequestBundle(
            wallID: wallIDString,
            wallName: wall.name,
            wallTotalWidth: wall.totalWidth,
            ceilingHeight: defaults.ceilingHeight,
            presetID: preset.id.uuidString,
            presetName: preset.name,
            presetVersion: preset.version,
            structuralSummary: structural,
            fullPrompt: fullPrompt,
            referenceImageFilename: referenceFilename,
            aspectRatio: preset.aspectRatio,
            modelName: effectiveModel,
            createdAt: Date()
        )
        
        let promptFilename = "prompt_" + stamp + ".json"
        let promptURL = folder.appendingPathComponent(promptFilename)
        if let data = bundle.toJSONData() {
            try? data.write(to: promptURL, options: .atomic)
        }
        
        let record = RenderHistoryRecord(
            id: UUID(),
            wallID: wallIDString,
            presetID: preset.id.uuidString,
            presetName: preset.name,
            presetVersion: preset.version,
            referenceImageFilename: referenceFilename,
            finishedImageFilename: nil,
            promptJSONFilename: promptFilename,
            isCanonical: false,
            createdAt: Date(),
            note: note
        )
        var records = loadHistory(wallID: wallIDString)
        records.insert(record, at: 0)
        saveHistory(records, wallID: wallIDString)
        
        return PackageResult(
            referenceImageURL: referenceURL,
            promptJSONURL: promptURL,
            historyRecord: record
        )
    }
    
    // MARK: Batch package (parallel)
    //
    // Same wall, multiple presets, all packaged concurrently. Each
    // packageRequest writes its own reference PNG, prompt JSON, and
    // history record.
    
    @MainActor
    static func packageBatch(wall: LockedWall,
                             defaults: RoomDefaults,
                             presets: [PhotorealPreset],
                             speed: RenderSpeed? = nil,
                             note: String = "") async -> [PackageResult] {
        _ = snapshotStructuralMask(wall: wall, defaults: defaults)
        
        return await withTaskGroup(of: PackageResult?.self) { group in
            for preset in presets {
                group.addTask { @MainActor in
                    await packageRequest(wall: wall, defaults: defaults, preset: preset, speed: speed, note: note)
                }
            }
            var results: [PackageResult] = []
            for await result in group {
                if let result = result { results.append(result) }
            }
            return results
        }
    }
    
    static func importFinishedImage(_ image: UIImage,
                                    recordID: UUID,
                                    wallID: String,
                                    pinAsCanonical: Bool) {
        guard let data = image.pngData() else { return }
        let folder = wallFolder(wallID: wallID)
        var records = loadHistory(wallID: wallID)
        guard let idx = records.firstIndex(where: { $0.id == recordID }) else { return }
        let stamp = ISO8601DateFormatter().string(from: Date()).replacingOccurrences(of: ":", with: "-")
        let filename = "finished_" + stamp + ".png"
        let url = folder.appendingPathComponent(filename)
        try? data.write(to: url, options: .atomic)
        records[idx].finishedImageFilename = filename
        if pinAsCanonical {
            for i in records.indices { records[i].isCanonical = (i == idx) }
        }
        saveHistory(records, wallID: wallID)
    }
    
    static func loadFinishedImage(for record: RenderHistoryRecord) -> UIImage? {
        guard let filename = record.finishedImageFilename else { return nil }
        let url = wallFolder(wallID: record.wallID).appendingPathComponent(filename)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }
    
    static func loadReferenceImage(for record: RenderHistoryRecord) -> UIImage? {
        let url = wallFolder(wallID: record.wallID).appendingPathComponent(record.referenceImageFilename)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }
}
