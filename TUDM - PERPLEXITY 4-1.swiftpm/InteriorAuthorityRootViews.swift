import SwiftUI

enum InteriorRoute: Hashable {
    case project(UUID)
    case room(projectID: UUID, roomID: UUID)
}

struct InteriorAuthorityRootView: View {
    @Environment(InteriorAuthorityStore.self) private var store
    @State private var showingNewProject = false
    
    var body: some View {
        NavigationStack {
            List {
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
            .navigationTitle("Projects")
            .navigationDestination(for: InteriorRoute.self) { route in
                switch route {
                case .project(let projectID):
                    ProjectDetailView(projectID: projectID)
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
            }
            .sheet(isPresented: $showingNewProject) {
                ProjectFormView(mode: .create) { draft in
                    store.addProject(draft)
                }
                .interactiveDismissDisabled()
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
                                            verticalChain: wall.verticalChainString
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
            } else {
                ContentUnavailableView("Project Missing", systemImage: "folder.badge.questionmark")
            }
        }
    }
}
