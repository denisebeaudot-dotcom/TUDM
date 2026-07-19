import SwiftUI

struct AuthorityRecordView: View {
    
    let project: Project
    let title: String
    let type: String
    let geometry: AuthorityGeometryRecord
    
    var body: some View {
        
        List {
            
            Section("General Dimensions") {
                
                AuthorityGeometryCard(
                    geometry: geometry
                )
            }
            
            Section("Authority Sections") {
                
                NavigationLink {
                    
                    StructureWorkspace(
                        project: project
                    )
                    
                } label: {
                    
                    sectionRow(
                        title: "Structure",
                        symbol: "building.columns"
                    )
                }
                
                unavailableRow(
                    title: "Measurements",
                    symbol: "ruler"
                )
                
                unavailableRow(
                    title: "Room Registry",
                    symbol: "square.grid.3x3"
                )
                
                unavailableRow(
                    title: "SVG Authority",
                    symbol: "doc.text"
                )
                
                unavailableRow(
                    title: "Retained Items",
                    symbol: "archivebox"
                )
            }
        }
        .navigationTitle(title)
        .navigationSubtitle(type)
    }
    
    private func sectionRow(
        title: String,
        symbol: String
    ) -> some View {
        
        HStack {
            
            Image(systemName: symbol)
            
            Text(title)
        }
    }
    
    private func unavailableRow(
        title: String,
        symbol: String
    ) -> some View {
        
        HStack {
            
            Image(systemName: symbol)
            
            Text(title)
            
            Spacer()
            
            Text("Coming Soon")
                .foregroundStyle(.secondary)
        }
    }
}
