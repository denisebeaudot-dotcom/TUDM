import SwiftUI

struct HelpRow: View {
    
    let title: String
    let description: String
    
    @State
    private var showingHelp = false
    
    var body: some View {
        
        HStack {
            
            Text(title)
            
            Spacer()
            
            Button {
                
                showingHelp.toggle()
                
            } label: {
                
                Image(systemName: "info.circle")
                
            }
            
        }
        .sheet(isPresented: $showingHelp) {
            
            NavigationStack {
                
                ScrollView {
                    
                    Text(description)
                        .padding()
                    
                }
                .navigationTitle(title)
                
            }
            
        }
        
    }
    
}
