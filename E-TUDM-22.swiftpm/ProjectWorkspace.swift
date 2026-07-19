import SwiftUI

struct ProjectWorkspace: View {
    
    let project: Project
    
    var body: some View {
        
        List {
            
            Section("Project") {
                
                Text(project.name)
            }
            
            Section("Rooms") {
                
                ForEach(project.rooms) { room in
                    
                    NavigationLink {
                        
                        AuthorityWorkspace(
                            project: project.selectingRoom(
                                code: room.code
                            )
                        )
                        
                    } label: {
                        
                        HStack {
                            
                            Image(systemName: "door.left.hand.open")
                            
                            VStack(alignment: .leading, spacing: 4) {
                                
                                Text(room.name)
                                
                                Text(room.code)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            Text(
                                "\(room.authority.records.count) records"
                            )
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            
            Section("Workspace") {
                
                Text("Design")
                Text("Tasks")
                Text("Outputs")
            }
        }
        .navigationTitle(project.name)
    }
}
