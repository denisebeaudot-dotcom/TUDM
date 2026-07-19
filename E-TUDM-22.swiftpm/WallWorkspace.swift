import SwiftUI

struct WallWorkspace: View {

    let project: Project
    let wall: Wall

    private var selectedRoom: Room? {
        project.selectedRoom
    }

    private var record: AuthorityRecord? {
        selectedRoom?
            .authority
            .record(code: wall.rawValue)
    }

    var body: some View {

        Group {

            if let room = selectedRoom,
               let record {

                let storedWall = AuthorityJSONStore.effectiveWall(
                    project: project,
                    room: room,
                    wallRecord: record
                )

                let geometry = AuthorityJSONStore.effectiveGeometry(
                    project: project,
                    room: room,
                    wallRecord: record
                )

                if let geometry {

                    AuthorityRecordView(
                        project: project,
                        title: storedWall.wallName,
                        type: record.type.rawValue,
                        geometry: geometry
                    )

                } else {

                    missingAuthority
                }

            } else {

                missingAuthority
            }
        }
        .navigationTitle(wall.rawValue)
    }

    private var missingAuthority: some View {

        ContentUnavailableView(
            "Authority Missing",
            systemImage: "exclamationmark.triangle",
            description: Text(
                "No authority record exists for \(wall.rawValue) in the selected room."
            )
        )
    }
}
