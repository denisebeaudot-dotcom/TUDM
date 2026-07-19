import Foundation

struct AuthorityBeam: Identifiable {
    
    let id = UUID()
    
    /// Permanent authority identifier.
    /// Examples:
    /// B1
    /// B2
    var code: String
    
    /// Display name shown in the UI.
    var name: String
    
    var width: Double
    var height: Double
    
    var undersideHeight: Double
    
    var startColumn: String
    var endColumn: String
    
    var finish: String
    
    // MARK: - Primary Initializer
    
    init(
        code: String,
        name: String,
        width: Double,
        height: Double,
        undersideHeight: Double,
        startColumn: String,
        endColumn: String,
        finish: String
    ) {
        
        self.code = code
        self.name = name
        
        self.width = width
        self.height = height
        
        self.undersideHeight = undersideHeight
        
        self.startColumn = startColumn
        self.endColumn = endColumn
        
        self.finish = finish
    }
    
    // MARK: - Compatibility Initializer
    // Allows all existing code to continue compiling.
    
    init(
        name: String,
        width: Double,
        height: Double,
        undersideHeight: Double,
        startColumn: String,
        endColumn: String,
        finish: String
    ) {
        
        self.code = name
        self.name = name
        
        self.width = width
        self.height = height
        
        self.undersideHeight = undersideHeight
        
        self.startColumn = startColumn
        self.endColumn = endColumn
        
        self.finish = finish
    }
    
}
