import SwiftUI

struct StatusRow: View {
    
    let title: String
    let status: String
    let progress: String
    
    var body: some View {
        
        VStack(alignment: .leading, spacing: 4) {
            
            HStack {
                
                Text(title)
                    .font(.headline)
                
                Spacer()
                
                Text(status)
                    .foregroundStyle(.secondary)
                
            }
            
            Text(progress)
                .font(.caption)
                .foregroundStyle(.secondary)
            
        }
        .padding(.vertical, 4)
        
    }
}
