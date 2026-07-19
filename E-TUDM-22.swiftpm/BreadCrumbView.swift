import SwiftUI

struct BreadcrumbView: View {
    
    let items: [String]
    
    var body: some View {
        
        ScrollView(.horizontal, showsIndicators: false) {
            
            HStack(spacing: 6) {
                
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    
                    if index > 0 {
                        
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        
                    }
                    
                    Text(item)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                }
                
            }
            
            .padding(.vertical, 2)
            
        }
        
    }
    
}
