import Foundation
import SwiftUI
import UniformTypeIdentifiers

// MARK: - Project JSON Bridge
//
// Path C: Swift is the source of truth for wall structural data. This bridge
// serializes the entire in-app Project graph (rooms, walls, segments, openings,
// beams, room defaults) to a single JSON file that can be dropped into a
// Working Copy repository folder, committed, and pushed to GitHub. Perplexity
// (or any external tool) then reads project.json from git and has the exact
// numbers the app is using — no retyping, no inference from screenshots.
//
// Roundtrip:
//   Export: current in-memory Projects  ->  JSON file on Files/Working Copy
//   Import: JSON file  ->  replaces (or merges into) in-memory Projects
//
// The JSON is a plain array of Project encoded via JSONEncoder with
// prettyPrinted + sortedKeys so diffs stay readable.

enum ProjectJSONBridge {
    
    static let defaultFilename = "tudm_projects.json"
    
    // MARK: Encode
    
    static func encode(projects: [Project]) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(projects)
    }
    
    // MARK: Decode
    
    static func decode(data: Data) throws -> [Project] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([Project].self, from: data)
    }
    
    // MARK: Write to Temp (for share/export document picker)
    
    static func writeToTemp(projects: [Project], filename: String = defaultFilename) throws -> URL {
        let data = try encode(projects: projects)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try data.write(to: url, options: [.atomic])
        return url
    }
}

// MARK: - Document Wrapper for Files app export
//
// A FileDocument that vends the JSON via the Files app export picker, allowing
// the user to save directly into their Working Copy repo folder.

struct ProjectJSONDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    static var writableContentTypes: [UTType] { [.json] }
    
    var projects: [Project]
    
    init(projects: [Project]) {
        self.projects = projects
    }
    
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.projects = try ProjectJSONBridge.decode(data: data)
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = try ProjectJSONBridge.encode(projects: projects)
        return FileWrapper(regularFileWithContents: data)
    }
}
