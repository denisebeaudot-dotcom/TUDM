import SwiftUI

struct StructuralChainWorkspace: View {
    
    let project: Project
    
    private var selectedRoom: Room? {
        project.selectedRoom
    }
    
    var body: some View {
        
        Group {
            
            if let room = selectedRoom {
                
                structuralChainList(
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
        .navigationTitle("Structural Chain")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func structuralChainList(
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
            
            Section("CHAIN") {
                
                NavigationLink {
                    
                    WallsWorkspace(
                        project: project
                    )
                    
                } label: {
                    
                    structuralRow(
                        title: "Walls",
                        symbol: "square.split.2x2",
                        count: room.authority.records.count
                    )
                }
                
                NavigationLink {
                    
                    ColumnsWorkspace(
                        project: project
                    )
                    
                } label: {
                    
                    structuralRow(
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
                    
                    structuralRow(
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
                    
                    structuralRow(
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
                    
                    structuralRow(
                        title: "Ceiling",
                        symbol: "arrow.up.and.down",
                        count: room.authority.ceilings.allCeilings.count
                    )
                }
            }
            
            Section("CHAIN STATUS") {
                
                HStack {
                    
                    Image(systemName: "checkmark.shield")
                    
                    Text("Authority Status")
                    
                    Spacer()
                    
                    Text("Verified")
                        .foregroundStyle(.green)
                }
            }
        }
    }
    
    private func structuralRow(
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
