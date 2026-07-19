import SwiftUI

struct DeveloperManifestView: View {
    
    var body: some View {
        
        List {
            
            Section("Application") {
                
                Text("MyApp")
                Text("ApplicationShell")
                Text("ContentView")
                
            }
            
            Section("Navigation") {
                
                Text("NavigationRoot")
                Text("AppScreen")
                
            }
            
            Section("Projects") {
                
                Text("Project")
                Text("ProjectWorkspace")
                Text("ProjectCreateScreen")
                
            }
            
            Section("Authority") {
                
                Text("AuthorityWorkspace")
                Text("AuthorityRecordView")
                Text("AuthoritySection")
                Text("HelpRow")
                Text("StatusRow")
                
            }
            
            Section("Structure") {
                
                Text("StructureWorkspace")
                Text("StructuralChainWorkspace")
                Text("WallsWorkspace")
                Text("WallWorkspace")
                Text("Wall")
                
            }
            
        }
        .navigationTitle("Developer Manifest")
        
    }
    
}
