import Foundation
import Observation

@Observable
final class InteriorAuthorityStore {
    var projects: [Project] = []
    
    private let saveKey = "InteriorAuthorityProjects"
    private let fileName = "InteriorAuthorityProjects.json"
    
    init() {
        load()
    }
    
    func addProject(_ draft: ProjectDraft) {
        let project = Project(
            name: draft.name,
            clientName: draft.clientName,
            location: draft.location,
            notes: draft.notes
        )
        projects.append(project)
        save()
    }
    
    func updateProject(_ projectID: UUID, draft: ProjectDraft) {
        guard let index = projects.firstIndex(where: { $0.id == projectID }) else { return }
        
        projects[index].name = draft.name
        projects[index].clientName = draft.clientName
        projects[index].location = draft.location
        projects[index].notes = draft.notes
        save()
    }
    
    func deleteProjects(at offsets: IndexSet) {
        projects.remove(atOffsets: offsets)
        save()
    }
    
    func addRoom(to projectID: UUID, draft: RoomDraft) {
        guard let projectIndex = projects.firstIndex(where: { $0.id == projectID }) else { return }
        
        let room = Room(
            name: draft.name,
            notes: draft.notes,
            defaults: draft.defaults
        )
        
        projects[projectIndex].rooms.append(room)
        save()
    }
    
    func updateRoom(projectID: UUID, roomID: UUID, draft: RoomDraft) {
        guard
            let projectIndex = projects.firstIndex(where: { $0.id == projectID }),
            let roomIndex = projects[projectIndex].rooms.firstIndex(where: { $0.id == roomID })
        else { return }
        
        projects[projectIndex].rooms[roomIndex].name = draft.name
        projects[projectIndex].rooms[roomIndex].notes = draft.notes
        projects[projectIndex].rooms[roomIndex].defaults = draft.defaults
        save()
    }
    
    func deleteRooms(projectID: UUID, at offsets: IndexSet) {
        guard let projectIndex = projects.firstIndex(where: { $0.id == projectID }) else { return }
        
        projects[projectIndex].rooms.remove(atOffsets: offsets)
        save()
    }
    
    func addWall(projectID: UUID, roomID: UUID, draft: WallDraft) {
        guard
            let projectIndex = projects.firstIndex(where: { $0.id == projectID }),
            let roomIndex = projects[projectIndex].rooms.firstIndex(where: { $0.id == roomID })
        else { return }
        
        let savedSegments = draft.generatedSegments.isEmpty
        ? draft.resolvedSegments
        : draft.generatedSegments
        
        let wall = WallSpec(
            name: draft.name,
            totalWidth: draft.totalWidth,
            ruleSet: draft.ruleSet,
            notes: draft.notes,
            chainString: draft.chainString,
            verticalChainString: draft.verticalChainString,
            segments: savedSegments,
            usesOverrides: draft.usesOverrides,
            overrides: draft.usesOverrides ? draft.overrides : nil
        )
        
        projects[projectIndex].rooms[roomIndex].wallSpecs.append(wall)
        save()
    }
    
    func updateWall(projectID: UUID, roomID: UUID, wallID: UUID, draft: WallDraft) {
        guard
            let projectIndex = projects.firstIndex(where: { $0.id == projectID }),
            let roomIndex = projects[projectIndex].rooms.firstIndex(where: { $0.id == roomID }),
            let wallIndex = projects[projectIndex].rooms[roomIndex].wallSpecs.firstIndex(where: { $0.id == wallID })
        else { return }
        
        let savedSegments = draft.generatedSegments.isEmpty
        ? draft.resolvedSegments
        : draft.generatedSegments
        
        projects[projectIndex].rooms[roomIndex].wallSpecs[wallIndex].name = draft.name
        projects[projectIndex].rooms[roomIndex].wallSpecs[wallIndex].totalWidth = draft.totalWidth
        projects[projectIndex].rooms[roomIndex].wallSpecs[wallIndex].ruleSet = draft.ruleSet
        projects[projectIndex].rooms[roomIndex].wallSpecs[wallIndex].notes = draft.notes
        projects[projectIndex].rooms[roomIndex].wallSpecs[wallIndex].chainString = draft.chainString
        projects[projectIndex].rooms[roomIndex].wallSpecs[wallIndex].verticalChainString = draft.verticalChainString
        projects[projectIndex].rooms[roomIndex].wallSpecs[wallIndex].segments = savedSegments
        projects[projectIndex].rooms[roomIndex].wallSpecs[wallIndex].usesOverrides = draft.usesOverrides
        projects[projectIndex].rooms[roomIndex].wallSpecs[wallIndex].overrides = draft.usesOverrides ? draft.overrides : nil
        save()
    }
    
    func deleteWalls(projectID: UUID, roomID: UUID, at offsets: IndexSet) {
        guard
            let projectIndex = projects.firstIndex(where: { $0.id == projectID }) else { return }
        
        guard let roomIndex = projects[projectIndex].rooms.firstIndex(where: { $0.id == roomID })
        else { return }
        
        projects[projectIndex].rooms[roomIndex].wallSpecs.remove(atOffsets: offsets)
        save()
    }
    
    // MARK: - Persistence
    // Writes to the app's Documents directory as a JSON file. This is more reliable
    // in Swift Playgrounds than UserDefaults, which can be cleared between runs.
    // Falls back to UserDefaults on read if the file doesn't exist (migration).
    
    private var fileURL: URL? {
        guard let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        return dir.appendingPathComponent(fileName)
    }
    
    func save() {
        do {
            let data = try JSONEncoder().encode(projects)
            
            if let url = fileURL {
                try data.write(to: url, options: [.atomic])
            }
            
            // Also mirror to UserDefaults as a belt-and-suspenders backup
            UserDefaults.standard.set(data, forKey: saveKey)
        } catch {
            print("Failed to save projects: \(error)")
        }
    }
    
    func load() {
        // Try file first
        if let url = fileURL,
           FileManager.default.fileExists(atPath: url.path),
           let data = try? Data(contentsOf: url) {
            do {
                projects = try JSONDecoder().decode([Project].self, from: data)
                return
            } catch {
                print("Failed to decode file, trying UserDefaults: \(error)")
            }
        }
        
        // Fallback: UserDefaults (for migration from older builds)
        guard let data = UserDefaults.standard.data(forKey: saveKey) else { return }
        
        do {
            projects = try JSONDecoder().decode([Project].self, from: data)
            // Migrate to file storage
            save()
        } catch {
            print("Failed to load projects: \(error)")
            projects = []
        }
    }
    
    func clearSavedData() {
        if let url = fileURL {
            try? FileManager.default.removeItem(at: url)
        }
        UserDefaults.standard.removeObject(forKey: saveKey)
        projects = []
    }
}
