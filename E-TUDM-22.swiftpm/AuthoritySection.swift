import Foundation

enum AuthoritySection: String, CaseIterable, Identifiable {
    
    case structure = "Structure"
    case measurements = "Measurements"
    case roomRegistry = "Room Registry"
    case svgAuthority = "SVG Authority"
    case retainedItems = "Retained Items"
    
    var id: String { rawValue }
    
    var symbol: String {
        
        switch self {
            
        case .structure:
            return "building.columns"
            
        case .measurements:
            return "ruler"
            
        case .roomRegistry:
            return "square.grid.3x3"
            
        case .svgAuthority:
            return "doc.text"
            
        case .retainedItems:
            return "archivebox"
            
        }
        
    }
    
}
