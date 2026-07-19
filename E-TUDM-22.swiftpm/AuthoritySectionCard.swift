import SwiftUI

struct AuthoritySectionCard<Content: View>: View {
    
    let title: String
    
    @State
    private var isExpanded = true
    
    @ViewBuilder
    let content: () -> Content
    
    var body: some View {
        
        Section {
            
            DisclosureGroup(
                isExpanded: $isExpanded
            ) {
                
                content()
                    .padding(.top, 6)
                
            } label: {
                
                Text(title)
                    .font(.headline)
                
            }
            
        }
        
    }
    
}
