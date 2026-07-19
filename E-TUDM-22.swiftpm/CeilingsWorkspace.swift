import SwiftUI

struct CeilingsWorkspace: View {
    
    let project: Project
    
    private var selectedRoom: Room? {
        project.selectedRoom
    }
    
    private var ceilings: [AuthorityCeilingRecord] {
        selectedRoom?.authority.ceilings.allCeilings ?? []
    }
    
    var body: some View {
        
        Group {
            
            if let room = selectedRoom {
                
                ceilingsContent(
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
        .navigationTitle("Ceiling")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    @ViewBuilder
    private func ceilingsContent(
        room: Room
    ) -> some View {
        
        if ceilings.isEmpty {
            
            ContentUnavailableView(
                "No Ceiling Authority",
                systemImage: "arrow.up.and.down",
                description: Text(
                    "No ceiling authority exists for \(room.name)."
                )
            )
            
        } else {
            
            List {
                
                ForEach(ceilings) { ceiling in
                    
                    CeilingAuthorityRow(
                        ceiling: ceiling
                    )
                }
            }
        }
    }
}

private struct CeilingAuthorityRow: View {
    
    let ceiling: AuthorityCeilingRecord
    
    private var heightText: String {
        ceiling.height.formatted(
            .number.precision(.fractionLength(2))
        )
    }
    
    var body: some View {
        
        HStack(alignment: .top, spacing: 12) {
            
            Image(systemName: "arrow.up.and.down")
            
            VStack(alignment: .leading, spacing: 4) {
                
                Text(ceiling.code)
                    .font(.headline)
                
                Text("Height: \(heightText) in")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Text("Finish: \(ceiling.finish)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                if !ceiling.notes.isEmpty {
                    
                    Text(ceiling.notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}
