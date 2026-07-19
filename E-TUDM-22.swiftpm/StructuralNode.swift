import Foundation

/// A single structural point within a room.
///
/// Nodes form the foundation of the Structural Chain.
/// They represent physical architectural elements such as
/// walls, columns, beams, doors, windows or transition points.
///
/// Nodes are intentionally generic so they can support
/// any room in the future.
struct StructuralNode: Identifiable, Hashable {
    
    let id = UUID()
    
    /// Unique authority identifier.
    ///
    /// Examples:
    /// W1
    /// C4
    /// B2
    /// W2-DOOR-1
    let code: String
    
    /// User-friendly name.
    let name: String
    
    /// Type of architectural element.
    let type: AuthorityType
    
    /// Optional notes.
    var notes: String?
    
    init(
        code: String,
        name: String,
        type: AuthorityType,
        notes: String? = nil
    ) {
        
        self.code = code
        self.name = name
        self.type = type
        self.notes = notes
    }
}
