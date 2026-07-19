import SwiftUI

struct RoomDefaultsWorkspace: View {

    @Environment(\.dismiss) private var dismiss

    let project: Project
    let room: Room

    @State private var defaults = StoredRoomDefaults()
    @State private var savedConfirmation = false
    @State private var saveFailureMessage = ""
    @State private var showingSaveFailure = false
    @State private var showingPostSaveOptions = false
    @State private var navigateToWallCorrections = false

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

        Form {

            Section("ROOM") {

                LabeledContent(
                    "Room",
                    value: room.name
                )

                LabeledContent(
                    "Code",
                    value: room.code
                )
            }

            Section("DEFAULT HEIGHTS") {

                RoomDefaultMeasurementRow(
                    title: "Wall Height",
                    value: $defaults.wallHeight,
                    optional: true
                )

                RoomDefaultMeasurementRow(
                    title: "Ceiling Height",
                    value: $defaults.ceilingHeight,
                    optional: true
                )

                RoomDefaultMeasurementRow(
                    title: "Beam Underside Height",
                    value: $defaults.beamUndersideHeight,
                    optional: true
                )
            }

            Section("DEFAULT MOLDING AND BASEBOARD") {

                RoomDefaultMeasurementRow(
                    title: "Crown Molding Height",
                    value: $defaults.crownMoldingHeight,
                    optional: true
                )

                TextField(
                    "Crown molding notes",
                    text: $defaults.crownMoldingNotes,
                    axis: .vertical
                )

                RoomDefaultMeasurementRow(
                    title: "Baseboard Height",
                    value: $defaults.baseboardHeight,
                    optional: true
                )

                TextField(
                    "Baseboard notes",
                    text: $defaults.baseboardNotes,
                    axis: .vertical
                )

                Text(
                    "Enter 0 when crown molding or baseboard is absent throughout the room."
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Section("DEFAULT COLUMN MEASUREMENTS") {

                RoomDefaultMeasurementRow(
                    title: "Column Width",
                    value: $defaults.columnWidth,
                    optional: true
                )

                RoomDefaultMeasurementRow(
                    title: "Column Depth",
                    value: $defaults.columnDepth,
                    optional: true
                )

                RoomDefaultMeasurementRow(
                    title: "Column Height",
                    value: $defaults.columnHeight,
                    optional: true
                )

                TextField(
                    "Column finish",
                    text: $defaults.columnFinish
                )
            }

            Section("DEFAULT BEAM MEASUREMENTS") {

                Picker(
                    "Beam Type",
                    selection: $defaults.beamType
                ) {

                    ForEach(
                        beamTypes,
                        id: \.self
                    ) { type in

                        Text(type)
                            .tag(type)
                    }
                }

                RoomDefaultMeasurementRow(
                    title: "Beam Width",
                    value: $defaults.beamWidth,
                    optional: true
                )

                RoomDefaultMeasurementRow(
                    title: "Beam Height / Depth",
                    value: $defaults.beamHeight,
                    optional: true
                )

                RoomDefaultMeasurementRow(
                    title: "Beam Underside Height AFF",
                    value: $defaults.beamUnderside,
                    optional: true
                )

                RoomDefaultMeasurementRow(
                    title: "Beam Projection From Wall",
                    value: $defaults.beamProjection,
                    optional: true
                )

                TextField(
                    "Beam finish",
                    text: $defaults.beamFinish
                )

                Picker(
                    "Crown Relationship",
                    selection: $defaults.beamCrownRelationship
                ) {

                    ForEach(
                        crownRelationships,
                        id: \.self
                    ) { relationship in

                        Text(relationship)
                            .tag(relationship)
                    }
                }
            }

            Section("APPLICATION") {

                Text(
                    "Enter structural defaults once for the room. New columns and beams inherit these values. Wall-specific and individual-element edits remain editable and take priority."
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Section {

                Button {

                    saveDefaults()

                } label: {

                    HStack {

                        Spacer()

                        Text("Save Room Defaults")
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

                        Text("Room defaults saved to JSON.")
                    }
                }
            }
        }
        .navigationTitle("Room Defaults")
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
            "Room defaults saved. Where would you like to go?",
            isPresented: $showingPostSaveOptions,
            titleVisibility: .visible
        ) {

            Button("Next: Wall Corrections") {
                navigateToWallCorrections = true
            }

            Button("Back to Structure") {
                dismiss()
            }

            Button("Stay Here", role: .cancel) { }
        }
        .background {

            NavigationLink(
                isActive: $navigateToWallCorrections
            ) {

                WallCorrectionsWorkspace(
                    project: project,
                    room: room
                )

            } label: {

                EmptyView()
            }
            .hidden()
        }
        .onAppear {

            loadDefaults()
        }
    }

    private func loadDefaults() {

        defaults = AuthorityJSONStore.loadRoomDefaults(
            projectID: project.id,
            roomCode: room.code
        )

        guard isCompletelyEmpty(defaults) else {
            return
        }

        if let firstRecord = room.authority.records.first,
           let geometry = room.authority.geometryRecord(code: firstRecord.code) {

            defaults.wallHeight = format(geometry.height)
            defaults.ceilingHeight = format(geometry.ceilingHeight)
            defaults.beamUndersideHeight = format(geometry.beamHeight)
        }

        if let firstColumn = room.authority.structure.allColumns.first {

            defaults.columnWidth = format(firstColumn.width)
            defaults.columnDepth = format(firstColumn.depth)
            defaults.columnHeight = format(firstColumn.height)
            defaults.columnFinish = firstColumn.finish
        }

        if let firstBeam = room.authority.structure.allBeams.first {

            defaults.beamWidth = format(firstBeam.width)
            defaults.beamHeight = format(firstBeam.height)
            defaults.beamUnderside = format(firstBeam.undersideHeight)
            defaults.beamFinish = firstBeam.finish
        } else if defaults.beamUnderside.isEmpty {

            defaults.beamUnderside = defaults.beamUndersideHeight
        }
    }

    private func saveDefaults() {

        do {

            try AuthorityJSONStore.saveRoomDefaults(
                defaults,
                project: project,
                roomCode: room.code
            )

            let verified = AuthorityJSONStore.loadRoomDefaults(
                projectID: project.id,
                roomCode: room.code
            )

            guard verified.wallHeight == defaults.wallHeight,
                  verified.ceilingHeight == defaults.ceilingHeight,
                  verified.beamUndersideHeight == defaults.beamUndersideHeight,
                  verified.crownMoldingHeight == defaults.crownMoldingHeight,
                  verified.crownMoldingNotes == defaults.crownMoldingNotes,
                  verified.baseboardHeight == defaults.baseboardHeight,
                  verified.baseboardNotes == defaults.baseboardNotes,
                  verified.columnWidth == defaults.columnWidth,
                  verified.columnDepth == defaults.columnDepth,
                  verified.columnHeight == defaults.columnHeight,
                  verified.columnFinish == defaults.columnFinish,
                  verified.beamType == defaults.beamType,
                  verified.beamWidth == defaults.beamWidth,
                  verified.beamHeight == defaults.beamHeight,
                  verified.beamUnderside == defaults.beamUnderside,
                  verified.beamProjection == defaults.beamProjection,
                  verified.beamFinish == defaults.beamFinish,
                  verified.beamCrownRelationship == defaults.beamCrownRelationship else {

                throw AuthorityJSONStore.SaveError.verificationFailed
            }

            savedConfirmation = true
            showingPostSaveOptions = true

        } catch {

            savedConfirmation = false
            saveFailureMessage = error.localizedDescription
            showingSaveFailure = true
        }
    }

    private func isCompletelyEmpty(
        _ values: StoredRoomDefaults
    ) -> Bool {

        values.wallHeight.isEmpty &&
        values.ceilingHeight.isEmpty &&
        values.beamUndersideHeight.isEmpty &&
        values.crownMoldingHeight.isEmpty &&
        values.crownMoldingNotes.isEmpty &&
        values.baseboardHeight.isEmpty &&
        values.baseboardNotes.isEmpty &&
        values.columnWidth.isEmpty &&
        values.columnDepth.isEmpty &&
        values.columnHeight.isEmpty &&
        values.columnFinish.isEmpty &&
        values.beamWidth.isEmpty &&
        values.beamHeight.isEmpty &&
        values.beamUnderside.isEmpty &&
        values.beamProjection.isEmpty &&
        values.beamFinish.isEmpty
    }

    private func format(
        _ value: Double
    ) -> String {

        value.formatted(
            .number.precision(.fractionLength(0...2))
        )
    }
}

private struct RoomDefaultMeasurementRow: View {

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
