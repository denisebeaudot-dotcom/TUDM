import SwiftUI

struct StructureWorkspace: View {

    let project: Project

    private var selectedRoom: Room? {
        project.selectedRoom
    }

    var body: some View {

        Group {

            if let room = selectedRoom {

                structureList(
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
        .navigationTitle("Structure")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func structureList(
        room: Room
    ) -> some View {

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

            Section("EDIT AUTHORITY") {

                NavigationLink {

                    RoomDefaultsWorkspace(
                        project: project,
                        room: room
                    )

                } label: {

                    HStack {

                        Image(systemName: "slider.horizontal.3")

                        Text("Room Defaults")
                    }
                }

                NavigationLink {

                    WallCorrectionsWorkspace(
                        project: project,
                        room: room
                    )

                } label: {

                    HStack {

                        Image(systemName: "square.and.pencil")

                        Text("Wall Corrections")
                    }
                }
            }

            Section("STRUCTURAL AUTHORITY") {

                NavigationLink {

                    StructuralChainWorkspace(
                        project: project
                    )

                } label: {

                    HStack {

                        Image(
                            systemName:
                                "point.3.connected.trianglepath.dotted"
                        )

                        Text("Structural Chain")
                    }
                }
            }

            Section("STRUCTURAL COMPONENTS") {

                NavigationLink {

                    ColumnsWorkspace(
                        project: project
                    )

                } label: {

                    componentRow(
                        title: "Columns",
                        symbol: "building.columns",
                        count: AuthorityJSONStore.allColumns(
                            project: project,
                            room: room
                        ).count
                    )
                }

                NavigationLink {

                    BeamsWorkspace(
                        project: project
                    )

                } label: {

                    componentRow(
                        title: "Beams",
                        symbol: "rectangle.3.group",
                        count: AuthorityJSONStore.allBeams(
                            project: project,
                            room: room
                        ).count
                    )
                }

                NavigationLink {

                    OpeningsWorkspace(
                        project: project
                    )

                } label: {

                    componentRow(
                        title: "Openings",
                        symbol: "square.split.2x1",
                        count: AuthorityJSONStore.totalOpeningCount(
                            project: project,
                            room: room
                        )
                    )
                }

                NavigationLink {

                    CeilingsWorkspace(
                        project: project
                    )

                } label: {

                    componentRow(
                        title: "Ceiling",
                        symbol: "arrow.up.and.down",
                        count: room.authority.ceilings.allCeilings.count
                    )
                }
            }

            Section("PERSISTENCE") {

                HStack {

                    Image(systemName: "doc.badge.checkmark")

                    Text("Authority Storage")

                    Spacer()

                    Text("JSON")
                        .foregroundStyle(.green)
                }

                Text(
                    "Wall dimensions, molding, baseboards, columns, beams, and openings are saved in project-authority.json."
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
    }

    private func componentRow(
        title: String,
        symbol: String,
        count: Int
    ) -> some View {

        HStack {

            Image(systemName: symbol)

            Text(title)

            Spacer()

            Text("\(count)")
                .foregroundStyle(.secondary)
        }
    }
}
