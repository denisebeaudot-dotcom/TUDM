import Foundation
import Observation

@Observable
final class InteriorAuthorityStore {
    var projects: [Project] = []
    
    /// Optional sync target for automatic wall_manifests.txt writes on save().
    /// Wired in InteriorAuthorityApp after both are constructed.
    var manifestSyncFolder: ManifestSyncFolder?
    
    private let saveKey = "InteriorAuthorityProjects"
    
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
            let projectIndex = projects.firstIndex(where: { $0.id == projectID }),
            let roomIndex = projects[projectIndex].rooms.firstIndex(where: { $0.id == roomID })
        else { return }
        
        projects[projectIndex].rooms[roomIndex].wallSpecs.remove(atOffsets: offsets)
        save()
    }
    
    // MARK: - Alcoves (Step 7)
    
    func addAlcove(projectID: UUID, roomID: UUID, alcove: RoomAlcove) {
        guard
            let projectIndex = projects.firstIndex(where: { $0.id == projectID }),
            let roomIndex = projects[projectIndex].rooms.firstIndex(where: { $0.id == roomID })
        else { return }
        
        projects[projectIndex].rooms[roomIndex].alcoves.append(alcove)
        save()
    }
    
    func updateAlcove(projectID: UUID, roomID: UUID, alcove: RoomAlcove) {
        guard
            let projectIndex = projects.firstIndex(where: { $0.id == projectID }),
            let roomIndex = projects[projectIndex].rooms.firstIndex(where: { $0.id == roomID }),
            let alcoveIndex = projects[projectIndex].rooms[roomIndex].alcoves.firstIndex(where: { $0.id == alcove.id })
        else { return }
        
        // Immutability contract: a locked alcove refuses in-place updates. Callers
        // that legitimately need to edit a locked alcove must clear isLocked first.
        if projects[projectIndex].rooms[roomIndex].alcoves[alcoveIndex].isLocked && alcove.isLocked {
            print("updateAlcove ignored: alcove \(alcove.id) is locked. Unlock before editing.")
            return
        }
        
        projects[projectIndex].rooms[roomIndex].alcoves[alcoveIndex] = alcove
        save()
    }
    
    func deleteAlcoves(projectID: UUID, roomID: UUID, at offsets: IndexSet) {
        guard
            let projectIndex = projects.firstIndex(where: { $0.id == projectID }),
            let roomIndex = projects[projectIndex].rooms.firstIndex(where: { $0.id == roomID })
        else { return }
        
        projects[projectIndex].rooms[roomIndex].alcoves.remove(atOffsets: offsets)
        save()
    }
    
    /// Convenience lookup: return the alcove-id-keyed map for a given room so
    /// AlcoveValidation and wall-side rendering can resolve refs quickly.
    func alcoveLookup(projectID: UUID, roomID: UUID) -> [UUID: RoomAlcove] {
        guard
            let projectIndex = projects.firstIndex(where: { $0.id == projectID }),
            let roomIndex = projects[projectIndex].rooms.firstIndex(where: { $0.id == roomID })
        else { return [:] }
        
        var result: [UUID: RoomAlcove] = [:]
        for alcove in projects[projectIndex].rooms[roomIndex].alcoves {
            result[alcove.id] = alcove
        }
        return result
    }
    
    // MARK: - Beams
    
    func addBeam(projectID: UUID, roomID: UUID, beam: RoomBeam) {
        guard
            let projectIndex = projects.firstIndex(where: { $0.id == projectID }),
            let roomIndex = projects[projectIndex].rooms.firstIndex(where: { $0.id == roomID })
        else { return }
        
        projects[projectIndex].rooms[roomIndex].beams.append(beam)
        save()
    }
    
    func updateBeam(projectID: UUID, roomID: UUID, beam: RoomBeam) {
        guard
            let projectIndex = projects.firstIndex(where: { $0.id == projectID }),
            let roomIndex = projects[projectIndex].rooms.firstIndex(where: { $0.id == roomID }),
            let beamIndex = projects[projectIndex].rooms[roomIndex].beams.firstIndex(where: { $0.id == beam.id })
        else { return }
        
        projects[projectIndex].rooms[roomIndex].beams[beamIndex] = beam
        save()
    }
    
    func deleteBeams(projectID: UUID, roomID: UUID, at offsets: IndexSet) {
        guard
            let projectIndex = projects.firstIndex(where: { $0.id == projectID }),
            let roomIndex = projects[projectIndex].rooms.firstIndex(where: { $0.id == roomID })
        else { return }
        
        projects[projectIndex].rooms[roomIndex].beams.remove(atOffsets: offsets)
        save()
    }
    
    func save() {
        do {
            let data = try JSONEncoder().encode(projects)
            UserDefaults.standard.set(data, forKey: saveKey)
        } catch {
            print("Failed to save projects: \(error)")
        }
        // Auto-write the human-readable manifest to the user's designated Files folder
        // (typically the Working Copy repo folder). Silent no-op if no folder is set.
        manifestSyncFolder?.writeManifest(projects: projects)
    }
    
    func load() {
        guard let data = UserDefaults.standard.data(forKey: saveKey) else { return }
        
        do {
            projects = try JSONDecoder().decode([Project].self, from: data)
        } catch {
            print("Failed to load projects: \(error)")
            projects = []
        }
    }
    
    func clearSavedData() {
        UserDefaults.standard.removeObject(forKey: saveKey)
        projects = []
    }
    
    // MARK: - Project JSON Bridge (Path C)
    
    /// Replace all in-memory projects with the ones loaded from an external JSON file
    /// (e.g. tudm_projects.json pulled from Working Copy / GitHub). Persists to UserDefaults.
    func replaceProjects(with newProjects: [Project]) {
        projects = newProjects
        save()
    }
    
    /// Merge imported projects into the current store. If a project shares the same UUID
    /// as an existing one, the imported version replaces it. Otherwise it is appended.
    /// This lets a user import a single wall/room/project without wiping their other work.
    func mergeProjects(with imported: [Project]) {
        for incoming in imported {
            if let idx = projects.firstIndex(where: { $0.id == incoming.id }) {
                projects[idx] = incoming
            } else {
                projects.append(incoming)
            }
        }
        save()
    }
}
