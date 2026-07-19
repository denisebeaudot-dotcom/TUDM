import SwiftUI

struct GeometryEditor: View {
    
    @State
    private var geometry = Geometry()
    
    var body: some View {
        
        Form {
            
            Section("Geometry") {
                
                TextField(
                    "Width",
                    text: $geometry.width
                )
                    
                TextField(
                    "Height",
                    text: $geometry.height
                )
                    
                TextField(
                    "Beam Height",
                    text: $geometry.beamHeight
                )
                    
            }
            
            Section("Summary") {
                
                LabeledContent("Width") {
                    Text(
                        geometry.width.isEmpty
                        ? "—"
                        : geometry.width
                    )
                }
                
                LabeledContent("Height") {
                    Text(
                        geometry.height.isEmpty
                        ? "—"
                        : geometry.height
                    )
                }
                
                LabeledContent("Beam Height") {
                    Text(
                        geometry.beamHeight.isEmpty
                        ? "—"
                        : geometry.beamHeight
                    )
                }
                
            }
            
        }
        .navigationTitle("Geometry")
        
    }
    
}
