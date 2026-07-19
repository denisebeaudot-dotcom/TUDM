import SwiftUI

struct WallsWorkspace: View {
    
    let project: Project
    
    var body: some View {
        
        List {
            
            ForEach(Wall.allCases) { wall in
                
                NavigationLink {
                    
                    WallWorkspace(
                        project: project,
                        wall: wall
                    )
                    
                } label: {
                    
                    Text(wall.rawValue)
                    
                }
                
            }
            
        }
        .navigationTitle("Walls")
        
    }
    
}
