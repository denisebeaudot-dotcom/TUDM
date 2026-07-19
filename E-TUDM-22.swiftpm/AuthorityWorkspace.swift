import SwiftUI

struct AuthorityWorkspace: View {

    let project: Project

    private var selectedRoom: Room? {
        project.selectedRoom
    }

    var body: some View {

        Group {

            if let room = selectedRoom {

                authorityList(
                    room: room
                )

            } else {

                ContentUnavailableView(
                    "Room Missing",
                    systemImage: "door.left.hand.closed",
                    description: Text(
                        "No room exists for code \(project.selectedRoomCode)."
                    )
                )
            }
        }
        .navigationTitle(
            selectedRoom?.name ?? "Authority"
        )
        .navigationBarTitleDisplayMode(.inline)
    }

    private func authorityList(
        room: Room
    ) -> some View {

        List {

            ForEach(room.authority.records) { record in

                let wall = AuthorityJSONStore.effectiveWall(
                    project: project,
                    room: room,
                    wallRecord: record
                )

                let geometry = AuthorityJSONStore.effectiveGeometry(
                    project: project,
                    room: room,
                    wallRecord: record
                )

                NavigationLink {

                    authorityDestination(
                        record: record,
                        title: wall.wallName,
                        geometry: geometry
                    )

                } label: {

                    AuthoritySummaryCard(
                        record: AuthorityRecord(
                            code: record.code,
                            name: wall.wallName,
                            type: record.type,
                            status: record.status
                        ),
                        geometry: geometry
                    )
                }
            }
        }
    }

    @ViewBuilder
    private func authorityDestination(
        record: AuthorityRecord,
        title: String,
        geometry: AuthorityGeometryRecord?
    ) -> some View {

        if let geometry {

            AuthorityRecordView(
                project: project,
                title: title,
                type: record.type.rawValue,
                geometry: geometry
            )

        } else {

            ContentUnavailableView(
                "Geometry Missing",
                systemImage: "ruler",
                description: Text(
                    "No geometry authority exists for \(record.code)."
                )
            )
        }
    }
}
