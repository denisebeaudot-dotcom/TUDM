import Foundation

struct AuthorityCeilingRecord: Identifiable {
    
    let id = UUID()
    
    let code: String
    
    var height: Double
    var finish: String
    var notes: String
    
    init(
        code: String,
        height: Double,
        finish: String,
        notes: String = ""
    ) {
        self.code = code
        self.height = height
        self.finish = finish
        self.notes = notes
    }
}
