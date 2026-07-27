import SwiftUI
import UniformTypeIdentifiers

enum InteriorRoute: Hashable {
    case project(UUID)
    case designProcess(projectID: UUID)
    case room(projectID: UUID, roomID: UUID)
}

struct InteriorAuthorityRootView: View {
    @Environment(InteriorAuthorityStore.self) private var store
    @Environment(ManifestSyncFolder.self) private var syncFolder
    @State private var showingNewProject = false
    @State private var showingProjectExporter = false
    @State private var showingProjectImporter = false
    @State private var pendingImportedProjects: [Project] = []
    @State private var showingImportChoice = false
    @State private var showingImportError = false
    @State private var importErrorMessage = ""
    @State private var showingExportResult = false
    @State private var exportResultMessage = ""
    @State private var showingSyncFolderPicker = false
    @State private var showingSyncFolderError = false
    @State private var syncFolderErrorMessage = ""
    @State private var showingAdvancedSync = false
    
    var body: some View {
        NavigationStack {
            List {
                // MARK: Projects (top)
                Section("Projects") {
                    if store.projects.isEmpty {
                        ContentUnavailableView(
                            "No Projects",
                            systemImage: "folder",
                            description: Text("Create your first project to begin.")
                        )
                    } else {
                        ForEach(store.projects) { project in
                            NavigationLink(value: InteriorRoute.project(project.id)) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(project.name)
                                        .font(.headline)
                                    
                                    if !project.clientName.trimmed.isEmpty {
                                        Text(project.clientName)
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                    
                                    if !project.location.trimmed.isEmpty {
                                        Text(project.location)
                                            .font(.caption)
                                            .foregroundStyle(.tertiary)
                                    }
                                }
                                .padding(.vertical, 2)
                            }
                        }
                        .onDelete(perform: store.deleteProjects)
                    }
                }
                
                // MARK: Housekeeping (bottom)
                Section("Manifest Sync") {
                    if let path = syncFolder.displayPath {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Folder:")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(path)
                                .font(.footnote)
                                .lineLimit(2)
                                .truncationMode(.middle)
                        }
                        if let ts = syncFolder.lastWriteAt {
                            HStack {
                                Text("Last write:")
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text(ts.formatted(date: .abbreviated, time: .shortened))
                            }
                            .font(.caption)
                        }
                        if let status = syncFolder.lastWriteStatus, status != "ok" {
                            Text(status)
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                        Button {
                            _ = syncFolder.writeManifest(projects: store.projects)
                        } label: {
                            Label("Sync Now", systemImage: "arrow.triangle.2.circlepath")
                        }
                        Text("Sync only writes \(ManifestTxtWriter.filename) into the folder. It never deletes or clears your projects, rooms, walls, or anything already in the folder.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Pick a Files folder (your Working Copy TUDM repo) and the app will auto-write wall_manifests.txt every time you save.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        Button {
                            showingSyncFolderPicker = true
                        } label: {
                            Label("Set Sync Folder", systemImage: "folder.badge.plus")
                        }
                    }
                }
                
            }
            .navigationTitle("Projects")
            .navigationDestination(for: InteriorRoute.self) { route in
                switch route {
                case .project(let projectID):
                    ProjectDetailView(projectID: projectID)
                case .designProcess(let projectID):
                    DesignProcessView(projectID: projectID)
                case .room(let projectID, let roomID):
                    RoomDetailView(projectID: projectID, roomID: roomID)
                }
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingNewProject = true
                    } label: {
                        Label("New Project", systemImage: "plus")
                    }
                }
                ToolbarItem(placement: .secondaryAction) {
                    Menu {
                        Button {
                            showingProjectExporter = true
                        } label: {
                            Label("Export Projects to JSON", systemImage: "square.and.arrow.up.on.square")
                        }
                        .disabled(store.projects.isEmpty)
                        
                        Button {
                            showingProjectImporter = true
                        } label: {
                            Label("Import Projects from JSON", systemImage: "square.and.arrow.down.on.square")
                        }

                        Divider()

                        Button {
                            showingAdvancedSync = true
                        } label: {
                            Label("Advanced Sync Settings", systemImage: "wrench.and.screwdriver")
                        }
                        .disabled(syncFolder.displayPath == nil)
                    } label: {
                        Label("Git Bridge", systemImage: "externaldrive.badge.timemachine")
                    }
                }
            }
            .sheet(isPresented: $showingNewProject) {
                ProjectFormView(mode: .create) { draft in
                    store.addProject(draft)
                }
                .interactiveDismissDisabled()
            }
            // Export to JSON (Files app picker — pick your Working Copy repo folder)
            .fileExporter(
                isPresented: $showingProjectExporter,
                document: ProjectJSONDocument(projects: store.projects),
                contentType: .json,
                defaultFilename: ProjectJSONBridge.defaultFilename
            ) { result in
                switch result {
                case .success(let url):
                    exportResultMessage = "Saved to \(url.lastPathComponent). Commit and push from Working Copy so Perplexity can pull it."
                    showingExportResult = true
                case .failure(let error):
                    exportResultMessage = "Export failed: \(error.localizedDescription)"
                    showingExportResult = true
                }
            }
            // Import from JSON (Files app picker — pick tudm_projects.json from your Working Copy repo folder)
            .fileImporter(
                isPresented: $showingProjectImporter,
                allowedContentTypes: [.json],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    guard let url = urls.first else { return }
                    let didStart = url.startAccessingSecurityScopedResource()
                    defer { if didStart { url.stopAccessingSecurityScopedResource() } }
                    do {
                        let data = try Data(contentsOf: url)
                        let projects = try ProjectJSONBridge.decode(data: data)
                        pendingImportedProjects = projects
                        showingImportChoice = true
                    } catch {
                        importErrorMessage = "Could not parse JSON: \(error.localizedDescription)"
                        showingImportError = true
                    }
                case .failure(let error):
                    importErrorMessage = "Import cancelled or failed: \(error.localizedDescription)"
                    showingImportError = true
                }
            }
            .confirmationDialog(
                "Import Projects",
                isPresented: $showingImportChoice,
                titleVisibility: .visible
            ) {
                Button("Replace All (\(pendingImportedProjects.count) projects)", role: .destructive) {
                    store.replaceProjects(with: pendingImportedProjects)
                    pendingImportedProjects = []
                }
                Button("Merge (keep existing, upsert by ID)") {
                    store.mergeProjects(with: pendingImportedProjects)
                    pendingImportedProjects = []
                }
                Button("Cancel", role: .cancel) {
                    pendingImportedProjects = []
                }
            } message: {
                Text("Replace will erase everything currently in the app and load only what is in the JSON. Merge upserts by UUID and keeps other work intact.")
            }
            .alert("Import Error", isPresented: $showingImportError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(importErrorMessage)
            }
            .alert("Export", isPresented: $showingExportResult) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(exportResultMessage)
            }
            // Sync folder picker (Files app — pick your Working Copy TUDM repo folder)
            .fileImporter(
                isPresented: $showingSyncFolderPicker,
                allowedContentTypes: [.folder],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    guard let url = urls.first else { return }
                    do {
                        try syncFolder.setFolder(from: url)
                        // Write immediately so the file appears in Working Copy right away.
                        _ = syncFolder.writeManifest(projects: store.projects)
                    } catch {
                        syncFolderErrorMessage = error.localizedDescription
                        showingSyncFolderError = true
                    }
                case .failure(let error):
                    syncFolderErrorMessage = error.localizedDescription
                    showingSyncFolderError = true
                }
            }
            .alert("Sync Folder Error", isPresented: $showingSyncFolderError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(syncFolderErrorMessage)
            }
            .sheet(isPresented: $showingAdvancedSync) {
                AdvancedSyncSettingsView()
            }
        }
    }
}

struct ProjectDetailView: View {
    @Environment(InteriorAuthorityStore.self) private var store
    
    let projectID: UUID
    
    @State private var showingEditProject = false
    @State private var showingNewRoom = false
    
    private var projectIndex: Int? {
        store.projects.firstIndex(where: { $0.id == projectID })
    }
    
    private var project: Project? {
        guard let projectIndex else { return nil }
        return store.projects[projectIndex]
    }
    
    var body: some View {
        Group {
            if let project {
                List {
                    Section("Project Info") {
                        if !project.clientName.trimmed.isEmpty {
                            LabeledContent("Client", value: project.clientName)
                        }
                        
                        if !project.location.trimmed.isEmpty {
                            LabeledContent("Location", value: project.location)
                        }
                        
                        if !project.notes.trimmed.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Notes")
                                    .font(.headline)
                                Text(project.notes)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    
                    Section("Design Process") {
                        NavigationLink(value: InteriorRoute.designProcess(projectID: projectID)) {
                            HStack(spacing: 12) {
                                Image(systemName: "list.bullet.rectangle.portrait")
                                    .font(.title2)
                                    .foregroundStyle(Color.accentColor)
                                    .frame(width: 32)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Design Process")
                                        .font(.headline)
                                    Text("12 phases across Groundwork, Design, Workboards, Execution.")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    
                    Section("Rooms") {
                        if project.rooms.isEmpty {
                            Text("No rooms yet")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(project.rooms) { room in
                                NavigationLink(value: InteriorRoute.room(projectID: projectID, roomID: room.id)) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(room.name)
                                            .font(.headline)
                                        
                                        if !room.notes.trimmed.isEmpty {
                                            Text(room.notes)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                                .lineLimit(2)
                                        }
                                    }
                                    .padding(.vertical, 2)
                                }
                            }
                            .onDelete { offsets in
                                store.deleteRooms(projectID: projectID, at: offsets)
                            }
                        }
                    }
                }
                .navigationTitle(project.name)
                .toolbar {
                    ToolbarItemGroup(placement: .primaryAction) {
                        Button("Edit") {
                            showingEditProject = true
                        }
                        
                        Button {
                            showingNewRoom = true
                        } label: {
                            Label("New Room", systemImage: "plus")
                        }
                    }
                }
                .sheet(isPresented: $showingEditProject) {
                    ProjectFormView(mode: .edit(project)) { draft in
                        store.updateProject(projectID, draft: draft)
                    }
                    .interactiveDismissDisabled()
                }
                .sheet(isPresented: $showingNewRoom) {
                    RoomFormView(mode: .create(projectID: projectID)) { draft in
                        store.addRoom(to: projectID, draft: draft)
                    }
                    .interactiveDismissDisabled()
                }
            } else {
                ContentUnavailableView("Project Missing", systemImage: "folder.badge.questionmark")
            }
        }
    }
}

struct RoomDetailView: View {
    @Environment(InteriorAuthorityStore.self) private var store
    
    let projectID: UUID
    let roomID: UUID
    
    @State private var showingEditRoom = false
    @State private var showingDefaults = false
    @State private var showingNewWall = false
    @State private var editingWall: WallSpec?
    @State private var showingWorksheet = false
    @State private var showingNewBeam = false
    @State private var editingBeam: RoomBeam?
    @State private var pushingWall: LockedWall?
    @State private var showingChainEntry = false
    @State private var showingNewAlcove = false
    @State private var editingAlcove: RoomAlcove?
    @State private var previewingAlcove: RoomAlcove?
    
    private var projectIndex: Int? {
        store.projects.firstIndex(where: { $0.id == projectID })
    }
    
    private var roomIndex: Int? {
        guard let projectIndex else { return nil }
        return store.projects[projectIndex].rooms.firstIndex(where: { $0.id == roomID })
    }
    
    private var project: Project? {
        guard let projectIndex else { return nil }
        return store.projects[projectIndex]
    }
    
    private var room: Room? {
        guard let projectIndex, let roomIndex else { return nil }
        return store.projects[projectIndex].rooms[roomIndex]
    }
    
    var body: some View {
        Group {
            if let room, let project {
                List {
                    Section("Room Info") {
                        if !room.notes.trimmed.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Notes")
                                    .font(.headline)
                                Text(room.notes)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    
                    Section("Defaults") {
                        LabeledContent("Ceiling Height", value: room.defaults.ceilingHeight.formatted(.number.precision(.fractionLength(2))))
                        LabeledContent("Crown Height", value: room.defaults.crownHeight.formatted(.number.precision(.fractionLength(2))))
                        LabeledContent("Baseboard Height", value: room.defaults.baseboardHeight.formatted(.number.precision(.fractionLength(2))))
                        LabeledContent("Beam Height", value: room.defaults.beamHeight.formatted(.number.precision(.fractionLength(2))))
                        LabeledContent("Beam Range AFF", value: room.defaults.beamRangeAFF.isEmpty ? "—" : room.defaults.beamRangeAFF)
                        LabeledContent("Column Width", value: room.defaults.columnWidth.formatted(.number.precision(.fractionLength(2))))
                        LabeledContent("Column Depth", value: room.defaults.columnDepth.formatted(.number.precision(.fractionLength(2))))
                        LabeledContent("Column Height", value: room.defaults.columnHeight.formatted(.number.precision(.fractionLength(2))))
                    }
                    
                    Section("Walls") {
                        if room.wallSpecs.isEmpty {
                            Text("No walls yet")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(room.wallSpecs) { wall in
                                Button {
                                    editingWall = wall
                                } label: {
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(wall.name)
                                            .font(.headline)
                                            .foregroundStyle(.primary)
                                        
                                        Text("Width: \(String(format: "%.2f", wall.totalWidth))")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        
                                        if !wall.ruleSet.trimmed.isEmpty {
                                            Text(wall.ruleSet)
                                                .font(.caption2)
                                                .foregroundStyle(.tertiary)
                                        }
                                        
                                        WallElevationThumbnail(
                                            wall: wall,
                                            defaults: wall.usesOverrides ? (wall.overrides ?? room.defaults) : room.defaults,
                                            verticalChain: wall.verticalChainString,
                                            allWalls: room.wallSpecs,
                                            roomBeams: room.beams
                                        )
                                        .frame(height: 90)
                                        .background(Color(.secondarySystemBackground))
                                        .clipShape(RoundedRectangle(cornerRadius: 6))
                                        .padding(.top, 4)
                                        
                                        if !wall.chainString.trimmed.isEmpty {
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text("Horizontal")
                                                    .font(.caption2)
                                                    .foregroundStyle(.tertiary)
                                                Text(wall.chainString)
                                                    .font(.system(.caption, design: .monospaced))
                                                    .foregroundStyle(.primary)
                                                    .fixedSize(horizontal: false, vertical: true)
                                            }
                                            .padding(.top, 2)
                                        }
                                        
                                        if !wall.verticalChainString.trimmed.isEmpty {
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text("Vertical")
                                                    .font(.caption2)
                                                    .foregroundStyle(.tertiary)
                                                Text(wall.verticalChainString)
                                                    .font(.system(.caption, design: .monospaced))
                                                    .foregroundStyle(.primary)
                                                    .fixedSize(horizontal: false, vertical: true)
                                            }
                                            .padding(.top, 2)
                                        }
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                            .onDelete { offsets in
                                store.deleteWalls(projectID: projectID, roomID: roomID, at: offsets)
                            }
                        }
                        
                        Button {
                            showingNewWall = true
                        } label: {
                            Label("Add Wall", systemImage: "plus")
                        }
                    }
                    
                    Section {
                        ForEach(room.wallSpecs) { wall in
                            Button {
                                pushingWall = wall.locked
                            } label: {
                                Label(
                                    wall.name.trimmed.isEmpty ? "Untitled wall" : wall.name,
                                    systemImage: "paperplane"
                                )
                            }
                        }

                        Button {
                            showingChainEntry = true
                        } label: {
                            Label("Chain Entry / Editor", systemImage: "list.number")
                        }
                    } header: {
                        Text("Perplexity Wall Registry")
                    } footer: {
                        Text("Validate a wall's measured chain and push it to your backend proxy as the render source of truth. Chain Entry / Editor lets you type or paste a chain by hand, starting from the Wall 1 template.")
                    }
                    
                    Section("Alcoves") {
                        if room.alcoves.isEmpty {
                            Text("No alcoves. Alcoves are corner features (wood stove, corner fireplace, nook, bar) that span two walls.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(room.alcoves) { alcove in
                                Button {
                                    editingAlcove = alcove
                                } label: {
                                    alcoveRow(alcove: alcove, walls: room.wallSpecs)
                                }
                            }
                            .onDelete { offsets in
                                store.deleteAlcoves(projectID: projectID, roomID: roomID, at: offsets)
                            }
                        }
                        
                        Button {
                            showingNewAlcove = true
                        } label: {
                            Label("Add Alcove", systemImage: "plus")
                        }
                        .disabled(room.wallSpecs.count < 2)
                        
                        if room.wallSpecs.count < 2 {
                            Text("Add at least two walls before creating a corner alcove.")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                        
                        if FamilyRoomWoodStoveSeed.matches(room: room)
                            && !FamilyRoomWoodStoveSeed.alreadySeeded(room: room) {
                            Button {
                                if let alcove = FamilyRoomWoodStoveSeed.makeAlcove(for: room) {
                                    store.addAlcove(projectID: projectID, roomID: roomID, alcove: alcove)
                                }
                            } label: {
                                Label("Seed Family Room Wood Stove Corner", systemImage: "flame.fill")
                            }
                            .foregroundStyle(.orange)
                        }
                    }
                    
                    Section("Room Beams") {
                        if room.beams.isEmpty {
                            Text("No beams. Beams span between columns across walls.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(room.beams) { beam in
                                Button {
                                    editingBeam = beam
                                } label: {
                                    beamRow(beam: beam, walls: room.wallSpecs)
                                }
                            }
                            .onDelete { offsets in
                                store.deleteBeams(projectID: projectID, roomID: roomID, at: offsets)
                            }
                        }
                        
                        Button {
                            showingNewBeam = true
                        } label: {
                            Label("Add Beam", systemImage: "plus")
                        }
                        .disabled(BeamColumnRef.gather(from: room.wallSpecs).count < 2)
                        
                        if BeamColumnRef.gather(from: room.wallSpecs).count < 2 {
                            Text("Add at least two columns across your walls before creating a beam.")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
                .navigationTitle(room.name)
                .toolbar {
                    ToolbarItemGroup(placement: .primaryAction) {
                        Button {
                            showingWorksheet = true
                        } label: {
                            Label("Worksheet", systemImage: "printer.fill")
                        }
                        
                        Button("Edit") {
                            showingEditRoom = true
                        }
                        
                        Button("Defaults") {
                            showingDefaults = true
                        }
                    }
                }
                .sheet(isPresented: $showingEditRoom) {
                    RoomFormView(mode: .edit(projectID: projectID, room: room)) { draft in
                        store.updateRoom(projectID: projectID, roomID: roomID, draft: draft)
                    }
                    .interactiveDismissDisabled()
                }
                .sheet(isPresented: $showingDefaults) {
                    RoomDefaultsFormView(initialDefaults: room.defaults) { defaults in
                        var draft = RoomDraft(room: room)
                        draft.defaults = defaults
                        store.updateRoom(projectID: projectID, roomID: roomID, draft: draft)
                    }
                    .interactiveDismissDisabled()
                }
                .sheet(isPresented: $showingNewWall) {
                    WallFormView(
                        mode: .create(
                            projectID: projectID,
                            roomID: roomID,
                            roomDefaults: room.defaults
                        )
                    ) { draft in
                        store.addWall(projectID: projectID, roomID: roomID, draft: draft)
                    }
                    .interactiveDismissDisabled()
                }
                .sheet(item: $editingWall) { wall in
                    WallFormView(
                        mode: .edit(
                            projectID: projectID,
                            roomID: roomID,
                            roomDefaults: room.defaults,
                            wall: wall
                        )
                    ) { draft in
                        store.updateWall(projectID: projectID, roomID: roomID, wallID: wall.id, draft: draft)
                    }
                    .interactiveDismissDisabled()
                }
                .sheet(isPresented: $showingWorksheet) {
                    WorksheetPreviewSheet(project: project, room: room)
                }
                .sheet(item: $pushingWall) { wall in
                    WallRegistryPushView(wall: wall, room: room)
                }
                .sheet(isPresented: $showingChainEntry) {
                    WallRegistryChainEntryView(draft: chainEntryDraft(for: room))
                }
                .sheet(isPresented: $showingNewBeam) {
                    BeamFormView(
                        mode: .create,
                        availableColumns: BeamColumnRef.gather(from: room.wallSpecs)
                    ) { beam in
                        store.addBeam(projectID: projectID, roomID: roomID, beam: beam)
                    }
                    .interactiveDismissDisabled()
                }
                .sheet(item: $editingBeam) { beam in
                    BeamFormView(
                        mode: .edit(beam),
                        availableColumns: BeamColumnRef.gather(from: room.wallSpecs)
                    ) { updated in
                        store.updateBeam(projectID: projectID, roomID: roomID, beam: updated)
                    }
                    .interactiveDismissDisabled()
                }
                .sheet(isPresented: $showingNewAlcove) {
                    AlcoveFormView(
                        mode: .create,
                        availableWalls: room.wallSpecs
                    ) { alcove in
                        store.addAlcove(projectID: projectID, roomID: roomID, alcove: alcove)
                    }
                    .interactiveDismissDisabled()
                }
                .sheet(item: $editingAlcove) { alcove in
                    AlcoveFormView(
                        mode: .edit(alcove),
                        availableWalls: room.wallSpecs
                    ) { updated in
                        store.updateAlcove(projectID: projectID, roomID: roomID, alcove: updated)
                    }
                    .interactiveDismissDisabled()
                }
                .sheet(item: $previewingAlcove) { alcove in
                    NavigationStack {
                        AlcoveRealityPreview(alcove: alcove.locked)
                            .navigationTitle(alcove.name.isEmpty ? "Alcove 3D" : alcove.name)
                            .navigationBarTitleDisplayMode(.inline)
                            .toolbar {
                                ToolbarItem(placement: .cancellationAction) {
                                    Button("Done") {
                                        previewingAlcove = nil
                                    }
                                }
                            }
                    }
                }
            } else {
                ContentUnavailableView("Project Missing", systemImage: "folder.badge.questionmark")
            }
        }
    }
    
    /// Wall 1 stays the starter template; only the room ID is pre-filled from this room.
    private func chainEntryDraft(for room: Room) -> WallRegistryChainDraft {
        var draft = WallRegistryChainDraft.wall1Template()
        draft.roomId = WallRegistryBridge.slug(room.name)
        return draft
    }

    @ViewBuilder
    private func alcoveRow(alcove: RoomAlcove, walls: [WallSpec]) -> some View {
        let wallA = walls.first(where: { $0.id == alcove.anchor.wallA })
        let wallB = walls.first(where: { $0.id == alcove.anchor.wallB })
        let wallATotal = wallA?.totalWidth ?? 0
        let wallBTotal = wallB?.totalWidth ?? 0
        let displayName = alcove.name.trimmed.isEmpty ? "Untitled Alcove" : alcove.name
        
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Text(displayName)
                    .font(.headline)
                    .foregroundStyle(.primary)
                if alcove.isLocked {
                    Image(systemName: "lock.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button {
                    previewingAlcove = alcove
                } label: {
                    Label("3D View", systemImage: "cube.transparent")
                        .labelStyle(.iconOnly)
                        .font(.title3)
                        .foregroundStyle(.tint)
                }
                .buttonStyle(.plain)
            }
            
            Text(payloadDescription(alcove.payload))
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Text("\(wallA?.name ?? "?"): \(String(format: "%.2f", alcove.anchor.footprintA))in · \(wallB?.name ?? "?"): \(String(format: "%.2f", alcove.anchor.footprintB))in")
                .font(.caption2)
                .foregroundStyle(.tertiary)
            
            Text("Platform \(String(format: "%.2f", alcove.platform.height))in \(alcove.platform.shape.rawValue) \(alcove.platform.material.rawValue) · Back \(alcove.back.style.rawValue) \(alcove.back.material.rawValue)")
                .font(.caption2)
                .foregroundStyle(.tertiary)
            
            AlcovePlanThumbnail(
                alcove: alcove.locked,
                wallATotalWidth: wallATotal,
                wallBTotalWidth: wallBTotal
            )
            .frame(height: 90)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .padding(.top, 4)
            
            if !alcove.notes.trimmed.isEmpty {
                Text(alcove.notes)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func payloadDescription(_ payload: AlcovePayload) -> String {
        switch payload {
        case .empty:
            return "Empty"
        case .woodStove(let spec):
            let man = spec.manufacturer.trimmed
            let model = spec.modelName.trimmed
            let stem = [man, model].filter { !$0.isEmpty }.joined(separator: " ")
            if stem.isEmpty {
                return "Wood Stove"
            }
            return "Wood Stove · \(stem)"
        }
    }
    
    @ViewBuilder
    private func beamRow(beam: RoomBeam, walls: [WallSpec]) -> some View {
        let refs = BeamColumnRef.gather(from: walls)
        let fromRef = refs.first(where: { $0.id == beam.fromColumnID })
        let toRef = refs.first(where: { $0.id == beam.toColumnID })
        
        VStack(alignment: .leading, spacing: 4) {
            Text(beam.label.isEmpty ? "Beam" : beam.label)
                .font(.headline)
                .foregroundStyle(.primary)
            
            Text("\(fromRef?.displayName ?? "?") → \(toRef?.displayName ?? "?")")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Text("\(String(format: "%.2f", beam.thickness))\" thick · \(String(format: "%.2f", beam.height))\" tall · \(beam.position.rawValue)")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 2)
    }
}
