import SwiftUI

struct OpeningsWorkspace: View {
    
    let project: Project
    
    private var selectedRoom: Room? {
        project.selectedRoom
    }
    
    var body: some View {
        
        Group {
            
            if let room = selectedRoom {
                
                OpeningsWallList(
                    project: project,
                    room: room
                )
                
            } else {
                
                ContentUnavailableView(
                    "Room Missing",
                    systemImage: "door.left.hand.closed",
                    description: Text("Select a valid room first.")
                )
            }
        }
        .navigationTitle("Openings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct OpeningsWallList: View {
    
    let project: Project
    let room: Room
    
    var body: some View {
        
        List {
            
            Section("ROOM") {
                
                HStack {
                    
                    Image(systemName: "door.left.hand.open")
                    
                    VStack(alignment: .leading, spacing: 4) {
                        
                        Text(room.name)
                        
                        Text(room.code)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Section("OPENING AUTHORITY") {
                
                ForEach(room.authority.records) { wallRecord in
                    
                    NavigationLink {
                        
                        WallOpeningsEditor(
                            project: project,
                            room: room,
                            wallRecord: wallRecord
                        )
                        
                    } label: {
                        
                        WallOpeningSummaryRow(
                            project: project,
                            room: room,
                            wallRecord: wallRecord
                        )
                    }
                }
            }
            
            Section("INSTRUCTIONS") {
                
                Text(
                    "Select a wall. Set the number of openings from 0 upward, then define the type and measurements for every opening."
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
    }
}

private struct WallOpeningSummaryRow: View {
    
    let project: Project
    let room: Room
    let wallRecord: AuthorityRecord
    
    private var savedOpenings: [EditableOpening] {
        AuthorityJSONStore.loadWall(
            projectID: project.id,
            roomCode: room.code,
            wallCode: wallRecord.code
        ).openings
    }
    
    var body: some View {
        
        HStack(spacing: 12) {
            
            Image(
                systemName: savedOpenings.isEmpty
                ? "square"
                : "square.split.2x1"
            )
            
            VStack(alignment: .leading, spacing: 4) {
                
                Text("\(wallRecord.code) - \(wallRecord.name)")
                
                Text(summaryText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Text("\(savedOpenings.count)")
                .foregroundStyle(.secondary)
        }
    }
    
    private var summaryText: String {
        
        guard !savedOpenings.isEmpty else {
            return "No openings"
        }
        
        return savedOpenings
            .map { $0.name.isEmpty ? $0.type : $0.name }
            .joined(separator: ", ")
    }
}

struct WallOpeningsEditor: View {

    @Environment(\.dismiss) private var dismiss
    
    let project: Project
    let room: Room
    let wallRecord: AuthorityRecord
    
    @State private var openings: [EditableOpening] = []
    @State private var baseboardHeight = ""
    @State private var baseboardNotes = ""
    @State private var savedConfirmation = false
    @State private var saveFailureMessage = ""
    @State private var showingSaveFailure = false
    @State private var showingPostSaveOptions = false
    @State private var navigateToNextWall = false
    @State private var navigateToOrtho = false
    @State private var orthoWall = StoredWallAuthority(wallCode: "")
    @State private var approvalErrors: [String] = []
    @State private var showingApprovalErrors = false
    
    var body: some View {
        
        Form {
            
            Section("WALL") {
                
                LabeledContent(
                    "Room",
                    value: room.name
                )
                
                LabeledContent(
                    "Wall",
                    value: wallRecord.code
                )
                
                LabeledContent(
                    "Wall Name",
                    value: wallRecord.name
                )
            }
            
            Section("BASEBOARD") {

                MeasurementField(
                    title: "Baseboard Height",
                    value: $baseboardHeight,
                    optional: true
                )

                TextField(
                    "Baseboard notes",
                    text: $baseboardNotes,
                    axis: .vertical
                )

                Text(
                    "Enter 0 when there is no baseboard on this wall."
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Section("NUMBER OF OPENINGS") {
                
                KeyboardIntegerField(
                    title: "Opening Count",
                    value: openingCountBinding,
                    range: 0...12
                )
                
                Text(
                    "Choose 0 when the wall has no opening."
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            
            ForEach(openings.indices, id: \.self) { index in
                
                OpeningEditorSection(
                    number: index + 1,
                    opening: $openings[index]
                )
            }
            
            Section {
                
                Button {
                    
                    var updatedWall = AuthorityJSONStore.effectiveWall(
                        project: project,
                        room: room,
                        wallRecord: wallRecord
                    )

                    updatedWall.baseboardHeight = baseboardHeight
                    updatedWall.baseboardNotes = baseboardNotes
                    updatedWall.openings = openings

                    do {

                        try AuthorityJSONStore.saveWall(
                            updatedWall,
                            project: project,
                            roomCode: room.code
                        )

                        let verifiedWall = AuthorityJSONStore.loadWall(
                            projectID: project.id,
                            roomCode: room.code,
                            wallCode: wallRecord.code
                        )

                        guard verifiedWall.openings.count == openings.count,
                              verifiedWall.baseboardHeight == baseboardHeight,
                              verifiedWall.baseboardNotes == baseboardNotes else {

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
                        
                        Text("Save Opening Authority")
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
                        
                        Text("Opening authority saved.")
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
        .confirmationDialog(
            "Opening authority saved. Where would you like to go?",
            isPresented: $showingPostSaveOptions,
            titleVisibility: .visible
        ) {

            Button("Create \(wallRecord.code) Ortho Now") {
                createOrthoNow()
            }

            if let nextWallRecord {

                Button("Next Wall: \(nextWallRecord.code)") {
                    navigateToNextWall = true
                }
            }

            Button("Back to Opening List") {
                dismiss()
            }

            Button("Stay Here", role: .cancel) { }
        }
        .background {

            ZStack {

                if let nextWallRecord {

                    NavigationLink(
                        isActive: $navigateToNextWall
                    ) {

                        WallOpeningsEditor(
                            project: project,
                            room: room,
                            wallRecord: nextWallRecord
                        )

                    } label: {

                        EmptyView()
                    }
                    .hidden()
                }

                NavigationLink(
                    isActive: $navigateToOrtho
                ) {

                    OrthographicAuthorityWorkspace(wall: orthoWall)

                } label: {

                    EmptyView()
                }
                .hidden()
            }
        }
        .alert(
            "Cannot Create Ortho",
            isPresented: $showingApprovalErrors
        ) {

            Button("OK", role: .cancel) { }

        } message: {

            Text(approvalErrors.joined(separator: "\n"))
        }
        .onAppear {
            
            let savedWall = AuthorityJSONStore.loadWall(
                projectID: project.id,
                roomCode: room.code,
                wallCode: wallRecord.code
            )

            openings = savedWall.openings
            baseboardHeight = savedWall.baseboardHeight
            baseboardNotes = savedWall.baseboardNotes
        }
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

    @MainActor
    private func createOrthoNow() {

        do {
            var candidate = AuthorityJSONStore.effectiveWall(
                project: project,
                room: room,
                wallRecord: wallRecord
            )

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

            orthoWall = verified
            navigateToOrtho = true

        } catch {
            approvalErrors = [error.localizedDescription]
            showingApprovalErrors = true
        }
    }

    private var openingCountBinding: Binding<Int> {
        
        Binding(
            get: {
                openings.count
            },
            set: { newCount in
                
                savedConfirmation = false
                
                if newCount > openings.count {
                    
                    let quantityToAdd = newCount - openings.count
                    
                    for _ in 0..<quantityToAdd {
                        openings.append(
                            EditableOpening()
                        )
                    }
                    
                } else if newCount < openings.count {
                    
                    openings.removeLast(
                        openings.count - newCount
                    )
                }
            }
        )
    }
}

private struct OpeningEditorSection: View {
    
    let number: Int
    
    @Binding var opening: EditableOpening
    
    private let openingTypes = [
        "Window",
        "Door",
        "Architectural Opening",
        "Opening With Steps",
        "Pass-Through",
        "Other"
    ]
    
    var body: some View {
        
        Section("OPENING \(number)") {
            
            TextField(
                "Opening name",
                text: $opening.name
            )
            
            Picker(
                "Opening Type",
                selection: $opening.type
            ) {
                
                ForEach(
                    openingTypes,
                    id: \.self
                ) { type in
                    
                    Text(type)
                        .tag(type)
                }
            }
            
            MeasurementField(
                title: "Overall Width",
                value: $opening.width
            )
            
            MeasurementField(
                title: "Overall Height",
                value: $opening.height
            )

            MeasurementField(
                title: "Start X From Wall Left",
                value: $opening.startX
            )

            MeasurementField(
                title: "Bottom Height AFF",
                value: $opening.bottomAFF
            )

            OpeningPlacementFields(
                opening: $opening
            )
            
            typeSpecificFields

            AdjacentStructureFields(
                opening: $opening
            )
            
            TextField(
                "Notes",
                text: $opening.notes,
                axis: .vertical
            )
        }
    }
    
    @ViewBuilder
    private var typeSpecificFields: some View {
        
        switch opening.type {
            
        case "Window":
            
            WindowOpeningFields(
                opening: $opening
            )
            
        case "Door":
            
            DoorOpeningFields(
                opening: $opening
            )
            
        case "Opening With Steps":
            
            StepOpeningFields(
                opening: $opening
            )
            
        default:
            
            GenericOpeningFields(
                opening: $opening
            )
        }
    }
}

private struct OpeningPlacementFields: View {

    @Binding var opening: EditableOpening

    var body: some View {

        Picker(
            "Placement",
            selection: $opening.placement
        ) {
            Text("Centered").tag("Centered")
            Text("Offset").tag("Offset")
            Text("Between Structures").tag("Between Structures")
            Text("Custom").tag("Custom")
        }

        TextField(
            "Reference structure at start / left",
            text: $opening.referenceStructureStart
        )

        TextField(
            "Reference structure at end / right",
            text: $opening.referenceStructureEnd
        )

        if opening.placement == "Offset" || opening.placement == "Custom" {

            Picker(
                "Offset Direction",
                selection: $opening.offsetDirection
            ) {
                Text("None").tag("None")
                Text("From Left / Start").tag("From Left / Start")
                Text("From Right / End").tag("From Right / End")
                Text("From Centerline").tag("From Centerline")
                Text("Other").tag("Other")
            }

            MeasurementField(
                title: "Offset Distance",
                value: $opening.offsetDistance,
                optional: true
            )
        }
    }
}

private struct AdjacentStructureFields: View {

    @Binding var opening: EditableOpening

    private let structureTypes = [
        "None",
        "Crown / Header Trim",
        "Beam",
        "Shelf",
        "Platform",
        "Hearth",
        "Stove / Appliance",
        "Built-In",
        "Step / Landing",
        "Other"
    ]

    var body: some View {

        Picker(
            "Structure Above",
            selection: $opening.structureAboveType
        ) {
            ForEach(structureTypes, id: \.self) { type in
                Text(type).tag(type)
            }
        }

        if opening.structureAboveType != "None" {

            MeasurementField(
                title: "Above Structure Height",
                value: $opening.structureAboveHeight,
                optional: true
            )

            MeasurementField(
                title: "Above Structure Projection",
                value: $opening.structureAboveProjection,
                optional: true
            )

            TextField(
                "Structure above notes",
                text: $opening.structureAboveNotes,
                axis: .vertical
            )
        }

        Picker(
            "Structure Below",
            selection: $opening.structureBelowType
        ) {
            ForEach(structureTypes, id: \.self) { type in
                Text(type).tag(type)
            }
        }

        if opening.structureBelowType != "None" {

            MeasurementField(
                title: "Below Structure Height",
                value: $opening.structureBelowHeight,
                optional: true
            )

            MeasurementField(
                title: "Below Structure Depth",
                value: $opening.structureBelowDepth,
                optional: true
            )

            TextField(
                "Structure below notes",
                text: $opening.structureBelowNotes,
                axis: .vertical
            )
        }
    }
}

private struct WindowOpeningFields: View {
    
    @Binding var opening: EditableOpening
    
    private let windowTypes = [
        "Picture Window",
        "Bay Window",
        "Bow Window",
        "Casement Window",
        "Double-Hung Window",
        "Sliding Window",
        "Window With Sidelights",
        "Custom"
    ]
    
    private let assemblyTypes = [
        "Single Section",
        "Two Sections",
        "Three Sections",
        "Center With Two Sidelights",
        "Custom Assembly"
    ]
    
    var body: some View {
        
        Picker(
            "Window Type",
            selection: $opening.windowType
        ) {
            
            ForEach(
                windowTypes,
                id: \.self
            ) { type in
                
                Text(type)
                    .tag(type)
            }
        }
        
        Picker(
            "Window Assembly",
            selection: $opening.windowAssembly
        ) {
            
            ForEach(
                assemblyTypes,
                id: \.self
            ) { assembly in
                
                Text(assembly)
                    .tag(assembly)
            }
        }
        
        IntegerField(
            title: "Section Count",
            value: $opening.sectionCount
        )
        
        MeasurementField(
            title: "Left Section Width",
            value: $opening.leftSectionWidth,
            optional: true
        )
        
        MeasurementField(
            title: "Center Section Width",
            value: $opening.centerSectionWidth,
            optional: true
        )
        
        MeasurementField(
            title: "Right Section Width",
            value: $opening.rightSectionWidth,
            optional: true
        )
        
        IntegerField(
            title: "Mullion Count",
            value: $opening.mullionCount
        )
        
        MeasurementField(
            title: "Mullion Width",
            value: $opening.mullionWidth,
            optional: true
        )
        
        TextField(
            "Muntin pattern",
            text: $opening.muntinPattern
        )
        
        MeasurementField(
            title: "Sill Height",
            value: $opening.sillHeight,
            optional: true
        )
        
        MeasurementField(
            title: "Sill Depth",
            value: $opening.sillDepth,
            optional: true
        )
        
        MeasurementField(
            title: "Casing Width",
            value: $opening.casingWidth,
            optional: true
        )
        
        MeasurementField(
            title: "Return Depth",
            value: $opening.returnDepth,
            optional: true
        )
        
        MeasurementField(
            title: "Header Trim Height",
            value: $opening.headerHeight,
            optional: true
        )
        
        MeasurementField(
            title: "Crown Molding Height",
            value: $opening.crownMoldingHeight,
            optional: true
        )
        
        TextField(
            "Trim finish",
            text: $opening.trimFinish
        )
    }
}

private struct DoorOpeningFields: View {
    
    @Binding var opening: EditableOpening
    
    private let doorTypes = [
        "Single Door",
        "Double Door",
        "French Doors",
        "Pocket Door",
        "Sliding Door",
        "Cased Opening",
        "Custom"
    ]
    
    var body: some View {
        
        Picker(
            "Door Type",
            selection: $opening.doorType
        ) {
            
            ForEach(
                doorTypes,
                id: \.self
            ) { type in
                
                Text(type)
                    .tag(type)
            }
        }
        
        MeasurementField(
            title: "Door Leaf Width",
            value: $opening.doorLeafWidth,
            optional: true
        )
        
        MeasurementField(
            title: "Door Leaf Height",
            value: $opening.doorLeafHeight,
            optional: true
        )
        
        MeasurementField(
            title: "Door Casing Width",
            value: $opening.doorCasingWidth,
            optional: true
        )
        
        MeasurementField(
            title: "Door Header Trim Height",
            value: $opening.doorHeaderHeight,
            optional: true
        )

        MeasurementField(
            title: "Crown Molding Height",
            value: $opening.crownMoldingHeight,
            optional: true
        )

        MeasurementField(
            title: "Return Depth",
            value: $opening.returnDepth,
            optional: true
        )

        TextField(
            "Trim finish",
            text: $opening.trimFinish
        )

        Picker(
            "Hinge Side",
            selection: $opening.doorHingeSide
        ) {
            Text("Left").tag("Left")
            Text("Right").tag("Right")
            Text("Double / Both").tag("Double / Both")
            Text("Not Applicable").tag("Not Applicable")
        }

        Picker(
            "Door Swing",
            selection: $opening.doorSwingDirection
        ) {
            Text("Into Room").tag("Into Room")
            Text("Out of Room").tag("Out of Room")
            Text("Sliding").tag("Sliding")
            Text("Pocket").tag("Pocket")
            Text("No Swing").tag("No Swing")
            Text("Other").tag("Other")
        }

        MeasurementField(
            title: "Swing Angle",
            value: $opening.doorSwingAngle,
            optional: true,
            unit: "deg"
        )
    }
}

private struct StepOpeningFields: View {
    
    @Binding var opening: EditableOpening
    
    var body: some View {
        
        IntegerField(
            title: "Step Count",
            value: $opening.stepCount
        )

        Picker(
            "Travel Direction",
            selection: $opening.stepDirection
        ) {
            Text("Up").tag("Up")
            Text("Down").tag("Down")
            Text("Up Then Turn").tag("Up Then Turn")
            Text("Down Then Turn").tag("Down Then Turn")
            Text("Mixed / Landing").tag("Mixed / Landing")
        }
        
        MeasurementField(
            title: "Riser Height",
            value: $opening.riserHeight,
            optional: true
        )
        
        MeasurementField(
            title: "Tread Depth",
            value: $opening.treadDepth,
            optional: true
        )
        
        MeasurementField(
            title: "First Step Inset",
            value: $opening.firstStepInset,
            optional: true
        )
        
        MeasurementField(
            title: "Casing Width",
            value: $opening.casingWidth,
            optional: true
        )
        
        MeasurementField(
            title: "Return Depth",
            value: $opening.returnDepth,
            optional: true
        )

        MeasurementField(
            title: "Header Trim Height",
            value: $opening.headerHeight,
            optional: true
        )

        MeasurementField(
            title: "Crown Molding Height",
            value: $opening.crownMoldingHeight,
            optional: true
        )

        TextField(
            "Trim finish",
            text: $opening.trimFinish
        )
    }
}

private struct GenericOpeningFields: View {
    
    @Binding var opening: EditableOpening
    
    var body: some View {
        
        MeasurementField(
            title: "Casing Width",
            value: $opening.casingWidth,
            optional: true
        )
        
        MeasurementField(
            title: "Return Depth",
            value: $opening.returnDepth,
            optional: true
        )
        
        MeasurementField(
            title: "Header Trim Height",
            value: $opening.headerHeight,
            optional: true
        )

        MeasurementField(
            title: "Crown Molding Height",
            value: $opening.crownMoldingHeight,
            optional: true
        )

        TextField(
            "Trim finish",
            text: $opening.trimFinish
        )
    }
}

private struct MeasurementField: View {
    
    let title: String
    
    @Binding var value: String
    
    var optional = false
    var unit = "in"
    
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
            
            if !unit.isEmpty {
                Text(unit)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct IntegerField: View {

    let title: String
    @Binding var value: Int

    var body: some View {

        KeyboardIntegerField(
            title: title,
            value: $value,
            range: 0...30
        )
    }
}
