import Foundation

struct AuthorityRelationship: Identifiable, Hashable {
    
    let id = UUID()
    
    let source: String
    
    let destination: String
    
    let type: AuthorityRelationshipType
    
}
