import Foundation

struct AuthorityColumn: Identifiable {
    
    let id = UUID()
    
    /// Permanent authority identifier.
    /// Examples:
    /// C1
    /// C2
    /// C9
    var code: String
    
    /// Display name shown in the UI.
    var name: String
    
    var width: Double
    var depth: Double
    var height: Double
    
    var finish: String
    
    // MARK: - Primary Initializer
    
    init(
        code: String,
        name: String,
        width: Double,
        depth: Double,
        height: Double,
        finish: String
    ) {
        
        self.code = code
        self.name = name
        
        self.width = width
        self.depth = depth
        self.height = height
        
        self.finish = finish
    }
    
    // MARK: - Compatibility Initializer
    // Allows all existing code to continue compiling.
    
    init(
        name: String,
        width: Double,
        depth: Double,
        height: Double,
        finish: String
    ) {
        
        self.code = name
        self.name = name
        
        self.width = width
        self.depth = depth
        self.height = height
        
        self.finish = finish
    }
    
}
