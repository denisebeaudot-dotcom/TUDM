import SwiftUI

struct WallCorrectionsWorkspace: View {

    let project: Project
    let room: Room

    var body: some View {

        List {

            Section("WALLS") {

                ForEach(room.authority.records) { wallRecord in

                    NavigationLink {

                        WallAuthorityEditor(
                            project: project,
                            room: room,
                            wallRecord: wallRecord
                        )

                    } label: {

                        WallCorrectionRow(
                            project: project,
                            room: room,
                            wallRecord: wallRecord
                        )
                    }
                }
            }

            Section("INSTRUCTIONS") {

                Text(
                    "Select a wall to correct its name, geometry, molding, baseboard, columns, beams, and built-ins. Zero is a valid value."
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Wall Corrections")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct WallCorrectionRow: View {

    let project: Project
    let room: Room
    let wallRecord: AuthorityRecord

    private var wall: StoredWallAuthority {
        AuthorityJSONStore.effectiveWall(
            project: project,
            room: room,
            wallRecord: wallRecord
        )
    }

    var body: some View {

        HStack {

            Image(systemName: "square.and.pencil")

            VStack(alignment: .leading, spacing: 4) {

                Text("\(wall.wallCode) - \(wall.wallName)")

                Text("\(wall.width) in W × \(wall.height) in H")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text("\(wall.columns.count) C / \(wall.beams.count) B / \(wall.builtIns.count) BI")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

private struct WallAuthorityEditor: View {

    @Environment(\.dismiss) private var dismiss

    let project: Project
    let room: Room
    let wallRecord: AuthorityRecord

    @State private var wall = StoredWallAuthority(wallCode: "")
    @State private var savedConfirmation = false
    @State private var saveFailureMessage = ""
    @State private var showingSaveFailure = false
    @State private var showingPostSaveOptions = false
    @State private var navigateToNextWall = false
    @State private var navigateToOrtho = false
    @State private var orthoWall = StoredWallAuthority(wallCode: "")
    @State private var approvalErrors: [String] = []
    @State private var showingApprovalErrors = false

    private var roomDefaults: StoredRoomDefaults {
        AuthorityJSONStore.loadRoomDefaults(
            projectID: project.id,
            roomCode: room.code
        )
    }

    var body: some View {

        Form {

            Section("WALL IDENTITY") {

                LabeledContent(
                    "Code",
                    value: wallRecord.code
                )

                TextField(
                    "Wall name",
                    text: $wall.wallName
                )
            }

            Section("GEOMETRY") {

                JSONMeasurementRow(
                    title: "Wall Width",
                    value: $wall.width
                )

                JSONMeasurementRow(
                    title: "Wall Height",
                    value: $wall.height
                )

                JSONMeasurementRow(
                    title: "Ceiling Height",
                    value: $wall.ceilingHeight
                )

                JSONMeasurementRow(
                    title: "Beam Underside Height",
                    value: $wall.beamHeight
                )
            }

            Section("MOLDING AND BASEBOARD") {

                JSONMeasurementRow(
                    title: "Crown Molding Height",
                    value: $wall.crownMoldingHeight,
                    optional: true
                )

                TextField(
                    "Crown molding notes",
                    text: $wall.crownMoldingNotes,
                    axis: .vertical
                )

                JSONMeasurementRow(
                    title: "Baseboard Height",
                    value: $wall.baseboardHeight,
                    optional: true
                )

                TextField(
                    "Baseboard notes",
                    text: $wall.baseboardNotes,
                    axis: .vertical
                )

                Text(
                    "Enter 0 when a molding or baseboard is absent."
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Section("OPENINGS") {

                NavigationLink {

                    WallOpeningsEditor(
                        project: project,
                        room: room,
                        wallRecord: wallRecord
                    )

                } label: {

                    HStack {

                        Image(systemName: wall.openings.isEmpty ? "square" : "square.split.2x1")

                        VStack(alignment: .leading, spacing: 4) {

                            Text("Edit Wall Openings")

                            Text(openingsSummary)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Text("\(wall.openings.count)")
                            .foregroundStyle(.secondary)
                    }
                }

                Text(
                    "Windows, doors, architectural openings, openings with steps, casing, returns, mullions, muntins, offsets, structures above and below, and stair details are edited here for this wall."
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Section("STRUCTURE DEFAULTS") {

                Button("Fill Blank Structural Fields From Room Defaults") {
                    applyRoomDefaultsToBlankFields()
                }

                Text(
                    "Room defaults are used for new columns and beams. This button fills only blank fields, so existing wall-specific tweaks are preserved."
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Section("COLUMNS") {

                KeyboardIntegerField(
                    title: "Column Count",
                    value: columnCountBinding,
                    range: 0...30
                )

                ForEach(wall.columns.indices, id: \.self) { index in

                    ColumnEditor(
                        number: index + 1,
                        column: $wall.columns[index]
                    )
                }
            }

            Section("BEAM / UPPER WALL CONSTRAINTS") {

                KeyboardIntegerField(
                    title: "Wall-Linked Beam Count",
                    value: beamCountBinding,
                    range: 0...30
                )

                ForEach(wall.beams.indices, id: \.self) { index in

                    BeamEditor(
                        number: index + 1,
                        beam: $wall.beams[index]
                    )
                }
            }

            Section("BUILT-INS") {

                KeyboardIntegerField(
                    title: "Built-In Count",
                    value: builtInCountBinding,
                    range: 0...30
                )

                ForEach(wall.builtIns.indices, id: \.self) { index in

                    BuiltInEditor(
                        number: index + 1,
                        builtIn: $wall.builtIns[index]
                    )
                }
            }

            Section("APPROVAL / ORTHOGRAPHIC AUTHORITY") {

                Button("Approve Wall and Generate Deterministic Ortho") {
                    approveAndGenerateOrtho()
                }
                .fontWeight(.semibold)

                if wall.isApproved {
                    LabeledContent("Status", value: "APPROVED / LOCKED")
                    LabeledContent("Checksum", value: String(wall.approvedChecksum.prefix(16)))
                    LabeledContent("Image", value: wall.orthoImageFilename)
                } else {
                    Text("Approval is blocked until wall geometry and every positioned element have complete deterministic coordinates.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section {

                Button {

                    do {

                        try AuthorityJSONStore.saveWall(
                            wall,
                            project: project,
                            roomCode: room.code
                        )

                        let verifiedWall = AuthorityJSONStore.loadWall(
                            projectID: project.id,
                            roomCode: room.code,
                            wallCode: wallRecord.code
                        )

                        guard verifiedWall.wallName == wall.wallName,
                              verifiedWall.width == wall.width,
                              verifiedWall.height == wall.height,
                              verifiedWall.ceilingHeight == wall.ceilingHeight,
                              verifiedWall.beamHeight == wall.beamHeight,
                              verifiedWall.crownMoldingHeight == wall.crownMoldingHeight,
                              verifiedWall.baseboardHeight == wall.baseboardHeight,
                              verifiedWall.openings.count == wall.openings.count,
                              verifiedWall.columns.count == wall.columns.count,
                              verifiedWall.beams.count == wall.beams.count,
                              verifiedWall.builtIns.count == wall.builtIns.count else {

                            throw AuthorityJSONStore.SaveError.verificationFailed
                        }

                        savedConfirmation = true
                        showingPostSaveOptions = true

                    } catch {

                        savedConfirmation = false
                        saveFailureMessage = error.localizedDescription
                        showingSaveFailure = true
                    }

                } label: {

                    HStack {

                        Spacer()

                        Text("Save Wall Authority")
                            .fontWeight(.semibold)

                        Spacer()
                    }
                }
            }

            if savedConfirmation {

                Section {

                    HStack {

                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)

                        Text("Wall authority saved to JSON.")
                    }
                }
            }
        }
        .navigationTitle(wallRecord.code)
        .navigationBarTitleDisplayMode(.inline)
        .alert(
            "Save Failed",
            isPresented: $showingSaveFailure
        ) {

            Button("OK", role: .cancel) { }

        } message: {

            Text(saveFailureMessage)
        }
        .alert(
            "Approval Blocked",
            isPresented: $showingApprovalErrors
        ) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(approvalErrors.joined(separator: "\n"))
        }
        .confirmationDialog(
            "Wall authority saved. Where would you like to go?",
            isPresented: $showingPostSaveOptions,
            titleVisibility: .visible
        ) {

            if let nextWallRecord {

                Button("Next Wall: \(nextWallRecord.code)") {
                    navigateToNextWall = true
                }
            }

            Button("Back to Wall List") {
                dismiss()
            }

            Button("Stay Here", role: .cancel) { }
        }
        .background {

            NavigationLink(isActive: $navigateToOrtho) {
                OrthographicAuthorityWorkspace(wall: orthoWall)
            } label: {
                EmptyView()
            }
            .hidden()

            if let nextWallRecord {

                NavigationLink(
                    isActive: $navigateToNextWall
                ) {

                    WallAuthorityEditor(
                        project: project,
                        room: room,
                        wallRecord: nextWallRecord
                    )

                } label: {

                    EmptyView()
                }
                .hidden()
            }
        }
        .onAppear {

            wall = AuthorityJSONStore.effectiveWall(
                project: project,
                room: room,
                wallRecord: wallRecord
            )
        }
    }

    private var openingsSummary: String {

        guard !wall.openings.isEmpty else {
            return "No openings"
        }

        return wall.openings
            .map { $0.name.isEmpty ? $0.type : $0.name }
            .joined(separator: ", ")
    }

    private var nextWallRecord: AuthorityRecord? {

        guard let currentIndex = room.authority.records.firstIndex(
            where: { $0.code == wallRecord.code }
        ) else {
            return nil
        }

        let nextIndex = currentIndex + 1

        guard room.authority.records.indices.contains(nextIndex) else {
            return nil
        }

        return room.authority.records[nextIndex]
    }

    private var columnCountBinding: Binding<Int> {

        Binding(
            get: { wall.columns.count },
            set: { newCount in

                savedConfirmation = false

                let defaults = AuthorityJSONStore.loadRoomDefaults(
                    projectID: project.id,
                    roomCode: room.code
                )

                while wall.columns.count < newCount {
                    wall.columns.append(
                        StoredColumnAuthority(
                            width: defaults.columnWidth,
                            depth: defaults.columnDepth,
                            height: defaults.columnHeight,
                            finish: defaults.columnFinish
                        )
                    )
                }

                if wall.columns.count > newCount {
                    wall.columns.removeLast(
                        wall.columns.count - newCount
                    )
                }
            }
        )
    }

    private var beamCountBinding: Binding<Int> {

        Binding(
            get: { wall.beams.count },
            set: { newCount in

                savedConfirmation = false

                while wall.beams.count < newCount {
                    wall.beams.append(
                        defaultBeam()
                    )
                }

                if wall.beams.count > newCount {
                    wall.beams.removeLast(
                        wall.beams.count - newCount
                    )
                }
            }
        )
    }

    private var builtInCountBinding: Binding<Int> {

        Binding(
            get: { wall.builtIns.count },
            set: { newCount in

                savedConfirmation = false

                while wall.builtIns.count < newCount {
                    wall.builtIns.append(
                        StoredBuiltInAuthority()
                    )
                }

                if wall.builtIns.count > newCount {
                    wall.builtIns.removeLast(
                        wall.builtIns.count - newCount
                    )
                }
            }
        )
    }

    @MainActor
    private func approveAndGenerateOrtho() {

        do {
            var candidate = wall
            candidate.isApproved = false
            candidate.approvedChecksum = ""
            candidate.approvedUTC = ""
            candidate.orthoImageFilename = ""

            let validation = AuthorityOrthoEngine.validate(candidate)

            guard validation.isValid else {
                approvalErrors = validation.errors
                showingApprovalErrors = true
                return
            }

            candidate.approvedChecksum = try AuthorityOrthoEngine.checksum(for: candidate)
            candidate.approvedUTC = ISO8601DateFormatter().string(from: Date())
            candidate.isApproved = true
            candidate.orthoImageFilename = try AuthorityOrthoEngine.renderPNG(
                wall: candidate,
                projectID: project.id,
                roomCode: room.code
            )

            try AuthorityJSONStore.saveWall(
                candidate,
                project: project,
                roomCode: room.code
            )

            let verified = AuthorityJSONStore.loadWall(
                projectID: project.id,
                roomCode: room.code,
                wallCode: wallRecord.code
            )

            guard verified.isApproved,
                  verified.approvedChecksum == candidate.approvedChecksum,
                  verified.orthoImageFilename == candidate.orthoImageFilename else {
                throw AuthorityJSONStore.SaveError.verificationFailed
            }

            wall = verified
            orthoWall = verified
            navigateToOrtho = true

        } catch {
            approvalErrors = [error.localizedDescription]
            showingApprovalErrors = true
        }
    }

    private func defaultBeam() -> StoredBeamAuthority {

        StoredBeamAuthority(
            type: roomDefaults.beamType,
            width: roomDefaults.beamWidth,
            height: roomDefaults.beamHeight,
            undersideHeight: roomDefaults.beamUnderside.isEmpty
                ? roomDefaults.beamUndersideHeight
                : roomDefaults.beamUnderside,
            projection: roomDefaults.beamProjection,
            finish: roomDefaults.beamFinish,
            crownRelationship: roomDefaults.beamCrownRelationship
        )
    }

    private func applyRoomDefaultsToBlankFields() {

        savedConfirmation = false

        for index in wall.columns.indices {

            if wall.columns[index].width.isEmpty {
                wall.columns[index].width = roomDefaults.columnWidth
            }

            if wall.columns[index].depth.isEmpty {
                wall.columns[index].depth = roomDefaults.columnDepth
            }

            if wall.columns[index].height.isEmpty {
                wall.columns[index].height = roomDefaults.columnHeight
            }

            if wall.columns[index].finish.isEmpty {
                wall.columns[index].finish = roomDefaults.columnFinish
            }
        }

        for index in wall.beams.indices {

            if wall.beams[index].type.isEmpty {
                wall.beams[index].type = roomDefaults.beamType
            }

            if wall.beams[index].width.isEmpty {
                wall.beams[index].width = roomDefaults.beamWidth
            }

            if wall.beams[index].height.isEmpty {
                wall.beams[index].height = roomDefaults.beamHeight
            }

            if wall.beams[index].undersideHeight.isEmpty {
                wall.beams[index].undersideHeight = roomDefaults.beamUnderside.isEmpty
                    ? roomDefaults.beamUndersideHeight
                    : roomDefaults.beamUnderside
            }

            if wall.beams[index].projection.isEmpty {
                wall.beams[index].projection = roomDefaults.beamProjection
            }

            if wall.beams[index].finish.isEmpty {
                wall.beams[index].finish = roomDefaults.beamFinish
            }

            if wall.beams[index].crownRelationship.isEmpty ||
                wall.beams[index].crownRelationship == "None" {

                wall.beams[index].crownRelationship = roomDefaults.beamCrownRelationship
            }
        }
    }
}

private struct ColumnEditor: View {

    let number: Int
    @Binding var column: StoredColumnAuthority

    var body: some View {

        DisclosureGroup("Column \(number)") {

            TextField("Name", text: $column.name)

            JSONMeasurementRow(
                title: "Start X From Wall Left",
                value: $column.startX
            )

            JSONMeasurementRow(
                title: "Bottom Height AFF",
                value: $column.bottomAFF
            )

            JSONMeasurementRow(
                title: "Width",
                value: $column.width
            )

            JSONMeasurementRow(
                title: "Depth",
                value: $column.depth
            )

            JSONMeasurementRow(
                title: "Height",
                value: $column.height
            )

            TextField("Finish", text: $column.finish)
        }
    }
}

private struct BeamEditor: View {

    let number: Int
    @Binding var beam: StoredBeamAuthority

    private let beamTypes = [
        "Perimeter Beam",
        "Transverse Beam",
        "Header Beam",
        "Decorative Beam",
        "Other"
    ]

    private let crownRelationships = [
        "None",
        "Crown Stops Below Beam",
        "Crown Meets Beam",
        "Crown Mounted On Beam",
        "Beam Replaces Crown",
        "Custom"
    ]

    var body: some View {

        DisclosureGroup("Beam \(number)") {

            TextField("Beam name", text: $beam.name)

            Picker("Beam Type", selection: $beam.type) {

                ForEach(beamTypes, id: \.self) { type in
                    Text(type).tag(type)
                }
            }

            JSONMeasurementRow(
                title: "Width",
                value: $beam.width
            )

            JSONMeasurementRow(
                title: "Height / Depth",
                value: $beam.height
            )

            JSONMeasurementRow(
                title: "Underside Height AFF",
                value: $beam.undersideHeight
            )

            JSONMeasurementRow(
                title: "Projection From Wall",
                value: $beam.projection,
                optional: true
            )

            JSONMeasurementRow(
                title: "Start X From Wall Left",
                value: $beam.startX
            )

            JSONMeasurementRow(
                title: "End X From Wall Left",
                value: $beam.endX
            )

            TextField("Start point description", text: $beam.startPoint)
            TextField("End point description", text: $beam.endPoint)
            TextField("Start column", text: $beam.startColumn)
            TextField("End column", text: $beam.endColumn)
            TextField("Finish", text: $beam.finish)

            Picker("Crown Relationship", selection: $beam.crownRelationship) {

                ForEach(crownRelationships, id: \.self) { relationship in
                    Text(relationship).tag(relationship)
                }
            }

            TextField(
                "Decorative constraint notes",
                text: $beam.decorativeConstraintNotes,
                axis: .vertical
            )

            Text(
                "This beam is saved under this wall and also appears in the room-wide Beams list. Use the notes to record limits on crown, curtains, built-ins, artwork, or wall treatments."
            )
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }
}

private struct BuiltInEditor: View {

    let number: Int
    @Binding var builtIn: StoredBuiltInAuthority

    private let builtInTypes = [
        "Bookcase",
        "Bench",
        "Window Seat",
        "Cabinet",
        "Shelving",
        "Media Unit",
        "Storage Bench",
        "Custom"
    ]

    private let placementOptions = [
        "Centered",
        "Offset",
        "Between Structures",
        "Custom"
    ]

    private let offsetDirections = [
        "None",
        "Left",
        "Right"
    ]

    private let openClosedStyles = [
        "Open",
        "Closed",
        "Mixed",
        "Custom"
    ]

    var body: some View {

        DisclosureGroup("Built-In \(number)") {

            TextField("Built-in name", text: $builtIn.name)

            Picker("Built-In Type", selection: $builtIn.type) {
                ForEach(builtInTypes, id: \.self) { type in
                    Text(type).tag(type)
                }
            }

            JSONMeasurementRow(
                title: "Start X From Wall Left",
                value: $builtIn.startX
            )

            JSONMeasurementRow(
                title: "Bottom Height AFF",
                value: $builtIn.bottomAFF
            )

            JSONMeasurementRow(
                title: "Width",
                value: $builtIn.width
            )

            JSONMeasurementRow(
                title: "Height",
                value: $builtIn.height
            )

            JSONMeasurementRow(
                title: "Depth",
                value: $builtIn.depth,
                optional: true
            )

            KeyboardIntegerField(
                title: "Bay Count",
                value: Binding(
                    get: { builtIn.bayCount },
                    set: { builtIn.bayCount = $0 }
                ),
                range: 0...30
            )

            KeyboardIntegerField(
                title: "Shelf Count",
                value: Binding(
                    get: { builtIn.shelfCount },
                    set: { builtIn.shelfCount = $0 }
                ),
                range: 0...60
            )

            Picker("Open / Closed Style", selection: $builtIn.openClosedStyle) {
                ForEach(openClosedStyles, id: \.self) { style in
                    Text(style).tag(style)
                }
            }

            Picker("Placement", selection: $builtIn.placement) {
                ForEach(placementOptions, id: \.self) { option in
                    Text(option).tag(option)
                }
            }

            TextField("Reference structure at start", text: $builtIn.referenceStructureStart)
            TextField("Reference structure at end", text: $builtIn.referenceStructureEnd)

            Picker("Offset Direction", selection: $builtIn.offsetDirection) {
                ForEach(offsetDirections, id: \.self) { direction in
                    Text(direction).tag(direction)
                }
            }

            JSONMeasurementRow(
                title: "Offset Distance",
                value: $builtIn.offsetDistance,
                optional: true
            )

            TextField("Finish", text: $builtIn.finish)

            TextField(
                "Notes",
                text: $builtIn.notes,
                axis: .vertical
            )

            Text(
                "Use built-ins for bookcases, benches, cabinets, shelving, window seats, or similar fixed elements that must appear in the wall elevation."
            )
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }
}

private struct JSONMeasurementRow: View {

    let title: String
    @Binding var value: String
    var optional = false

    var body: some View {

        HStack {

            VStack(alignment: .leading, spacing: 2) {

                Text(title)

                if optional {

                    Text("Optional")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            TextField(
                "0",
                text: $value
            )
            .multilineTextAlignment(.trailing)
            .frame(width: 90)

            Text("in")
                .foregroundStyle(.secondary)
        }
    }
}
