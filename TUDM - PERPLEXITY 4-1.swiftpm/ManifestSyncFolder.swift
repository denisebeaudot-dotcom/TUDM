import Foundation
import SwiftUI

// MARK: - Manifest Sync Folder
//
// Stores a security-scoped bookmark to a user-chosen folder in the Files app
// (typically the user's Working Copy repo folder for the TUDM repository).
// Every time store.save() runs, the app resolves the bookmark, starts access,
// writes wall_manifests.txt into that folder, and releases access.
//
// The bookmark lives in UserDefaults so it survives relaunches.
//
// UX contract:
//   - First launch: bookmark absent. writeManifest() no-ops silently. UI shows
//     a Set Sync Folder button.
//   - User taps Set Sync Folder -> Files picker -> picks TUDM Working Copy repo
//     folder -> bookmark stored -> UI shows the folder path and Sync Now button.
//   - Every store.save(): manifest txt is auto-written to that folder.
//   - Working Copy sees the modified file. User commits + pushes when ready.

@Observable
final class ManifestSyncFolder {
    
    static let bookmarkKey = "TUDM.ManifestSyncFolder.Bookmark"
    static let displayPathKey = "TUDM.ManifestSyncFolder.DisplayPath"
    static let lastWriteKey = "TUDM.ManifestSyncFolder.LastWrite"
    static let lastWriteStatusKey = "TUDM.ManifestSyncFolder.LastWriteStatus"
    
    // Public read-only observable state
    private(set) var displayPath: String?
    private(set) var lastWriteAt: Date?
    private(set) var lastWriteStatus: String?
    
    init() {
        self.displayPath = UserDefaults.standard.string(forKey: Self.displayPathKey)
        if let ts = UserDefaults.standard.object(forKey: Self.lastWriteKey) as? Date {
            self.lastWriteAt = ts
        }
        self.lastWriteStatus = UserDefaults.standard.string(forKey: Self.lastWriteStatusKey)
    }
    
    var isConfigured: Bool { UserDefaults.standard.data(forKey: Self.bookmarkKey) != nil }
    
    // MARK: - Set / Clear bookmark
    
    /// Called after the fileImporter returns a folder URL. Creates a security-scoped bookmark and stores it.
    func setFolder(from url: URL) throws {
        let didStart = url.startAccessingSecurityScopedResource()
        defer { if didStart { url.stopAccessingSecurityScopedResource() } }
        let bookmark = try url.bookmarkData(options: [.minimalBookmark], includingResourceValuesForKeys: nil, relativeTo: nil)
        UserDefaults.standard.set(bookmark, forKey: Self.bookmarkKey)
        UserDefaults.standard.set(url.path, forKey: Self.displayPathKey)
        self.displayPath = url.path
    }
    
    func clearFolder() {
        UserDefaults.standard.removeObject(forKey: Self.bookmarkKey)
        UserDefaults.standard.removeObject(forKey: Self.displayPathKey)
        UserDefaults.standard.removeObject(forKey: Self.lastWriteKey)
        UserDefaults.standard.removeObject(forKey: Self.lastWriteStatusKey)
        self.displayPath = nil
        self.lastWriteAt = nil
        self.lastWriteStatus = nil
    }
    
    // MARK: - Write
    
    /// Writes wall_manifests.txt into the bookmarked folder. Silent no-op if no folder is set.
    /// Records lastWriteAt + lastWriteStatus so the UI can display sync state.
    @discardableResult
    func writeManifest(projects: [Project]) -> Bool {
        guard let bookmarkData = UserDefaults.standard.data(forKey: Self.bookmarkKey) else {
            return false
        }
        do {
            var isStale = false
            let folderURL = try URL(
                resolvingBookmarkData: bookmarkData,
                options: [],
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )
            let didStart = folderURL.startAccessingSecurityScopedResource()
            defer { if didStart { folderURL.stopAccessingSecurityScopedResource() } }
            
            let text = ManifestTxtWriter.build(projects: projects)
            let fileURL = folderURL.appendingPathComponent(ManifestTxtWriter.filename)
            try text.data(using: .utf8)?.write(to: fileURL, options: [.atomic])
            
            let now = Date()
            UserDefaults.standard.set(now, forKey: Self.lastWriteKey)
            UserDefaults.standard.set("ok", forKey: Self.lastWriteStatusKey)
            self.lastWriteAt = now
            self.lastWriteStatus = "ok"
            
            // If the bookmark is stale, refresh it silently.
            if isStale {
                if let fresh = try? folderURL.bookmarkData(options: [.minimalBookmark], includingResourceValuesForKeys: nil, relativeTo: nil) {
                    UserDefaults.standard.set(fresh, forKey: Self.bookmarkKey)
                }
            }
            return true
        } catch {
            let msg = "error: \(error.localizedDescription)"
            UserDefaults.standard.set(msg, forKey: Self.lastWriteStatusKey)
            self.lastWriteStatus = msg
            return false
        }
    }
}
