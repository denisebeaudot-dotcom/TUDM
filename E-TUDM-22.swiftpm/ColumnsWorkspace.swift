import SwiftUI

struct ColumnsWorkspace: View {

    let project: Project

    private var selectedRoom: Room? {
        project.selectedRoom
    }

    var body: some View {

        Group {

            if let room = selectedRoom {

                columnsContent(
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
        .navigationTitle("Columns")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func columnsContent(
        room: Room
    ) -> some View {

        let columns = AuthorityJSONStore.allColumns(
            project: project,
            room: room
        )

        if columns.isEmpty {

            ContentUnavailableView(
                "No Columns",
                systemImage: "building.columns",
                description: Text(
                    "No column authority exists for \(room.name)."
                )
            )

        } else {

            List {

                ForEach(columns) { column in

                    StoredColumnAuthorityRow(
                        column: column
                    )
                }
            }
        }
    }
}

private struct StoredColumnAuthorityRow: View {

    let column: StoredColumnAuthority

    var body: some View {

        HStack(alignment: .top, spacing: 12) {

            Image(systemName: "building.columns")

            VStack(alignment: .leading, spacing: 4) {

                Text(column.name.isEmpty ? "Unnamed Column" : column.name)
                    .font(.headline)

                Text(
                    "\(display(column.width)) in W × \(display(column.depth)) in D × \(display(column.height)) in H"
                )
                .font(.caption)
                .foregroundStyle(.secondary)

                Text(column.finish.isEmpty ? "Finish not entered" : column.finish)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func display(
        _ value: String
    ) -> String {
        value.isEmpty ? "—" : value
    }
}
