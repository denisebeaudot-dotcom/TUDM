import SwiftUI

struct BeamsWorkspace: View {

    let project: Project

    private var selectedRoom: Room? {
        project.selectedRoom
    }

    var body: some View {

        Group {

            if let room = selectedRoom {

                beamsContent(
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
        .navigationTitle("Beams")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func beamsContent(
        room: Room
    ) -> some View {

        let beams = AuthorityJSONStore.allBeams(
            project: project,
            room: room
        )

        if beams.isEmpty {

            ContentUnavailableView(
                "No Beams",
                systemImage: "rectangle.3.group",
                description: Text(
                    "No beam authority exists for \(room.name)."
                )
            )

        } else {

            List {

                ForEach(beams) { beam in

                    StoredBeamAuthorityRow(
                        beam: beam
                    )
                }
            }
        }
    }
}

private struct StoredBeamAuthorityRow: View {

    let beam: StoredBeamAuthority

    var body: some View {

        HStack(alignment: .top, spacing: 12) {

            Image(systemName: "rectangle.3.group")

            VStack(alignment: .leading, spacing: 4) {

                Text(beam.name.isEmpty ? "Unnamed Beam" : beam.name)
                    .font(.headline)

                Text(beam.type.isEmpty ? "Beam type not entered" : beam.type)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(
                    "\(display(beam.width)) in W × \(display(beam.height)) in H · underside \(display(beam.undersideHeight)) in AFF"
                )
                .font(.caption)
                .foregroundStyle(.secondary)

                if !beam.projection.isEmpty {

                    Text("Projection: \(beam.projection) in")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Text(spanText)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(beam.finish.isEmpty ? "Finish not entered" : beam.finish)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if !beam.crownRelationship.isEmpty,
                   beam.crownRelationship != "None" {

                    Text("Crown: \(beam.crownRelationship)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if !beam.decorativeConstraintNotes.isEmpty {

                    Text(beam.decorativeConstraintNotes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }


    private var spanText: String {

        let start = beam.startPoint.isEmpty
            ? display(beam.startColumn)
            : beam.startPoint

        let end = beam.endPoint.isEmpty
            ? display(beam.endColumn)
            : beam.endPoint

        return "\(start) → \(end)"
    }

    private func display(
        _ value: String
    ) -> String {
        value.isEmpty ? "—" : value
    }
}
