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
                                      warmupTicks: Int = 8) async -> UIImage? {
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
                               autoSnapshot: Bool = true) async -> PreviewResult? {
        let snapshot = autoSnapshot
            ? await snapshotFurnishedView(wall: wall, defaults: defaults)
            : nil
        
        let structural = WallStructuralSummary.generate(wall: wall, defaults: defaults)
        let fullPrompt = preset.compose(structural: structural)
        
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
            modelName: preset.modelName,
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
                               referenceImage: UIImage? = nil,
                               autoSnapshot: Bool = true,
                               note: String = "") async -> PackageResult? {
        let wallIDString = wall.id.uuidString
        let folder = wallFolder(wallID: wallIDString)
        let stamp = ISO8601DateFormatter().string(from: Date()).replacingOccurrences(of: ":", with: "-")
        
        // Resolve a reference image: explicit override, else auto-snapshot.
        var resolvedImage = referenceImage
        if resolvedImage == nil, autoSnapshot {
            resolvedImage = await snapshotFurnishedView(wall: wall, defaults: defaults)
        }
        
        let referenceFilename = "reference_" + stamp + ".png"
        var referenceURL: URL? = nil
        if let img = resolvedImage, let data = img.pngData() {
            referenceURL = folder.appendingPathComponent(referenceFilename)
            try? data.write(to: referenceURL!, options: .atomic)
        }
        
        let structural = WallStructuralSummary.generate(wall: wall, defaults: defaults)
        let fullPrompt = preset.compose(structural: structural)
        
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
            modelName: preset.modelName,
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
