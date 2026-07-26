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
    
    // MARK: Package a render request
    //
    // On iPad Playgrounds we cannot reliably snapshot a RealityView
    // offscreen (ImageRenderer does not capture GPU-backed content).
    // The user provides the reference PNG themselves: they take the
    // Furnished view face-on, tap Export Render Frame to Photos, and
    // then pass that image into the render request.
    //
    // If no reference image is supplied, the app writes the prompt
    // JSON only and expects the user to attach the exported image
    // when sharing to the session.
    
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
                               note: String = "") -> PackageResult? {
        let wallIDString = wall.id.uuidString
        let folder = wallFolder(wallID: wallIDString)
        let stamp = ISO8601DateFormatter().string(from: Date()).replacingOccurrences(of: ":", with: "-")
        
        // Reference image is optional. If supplied, write it. Otherwise
        // record the intended filename and let the user attach later.
        let referenceFilename = "reference_" + stamp + ".png"
        var referenceURL: URL? = nil
        if let img = referenceImage, let data = img.pngData() {
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
