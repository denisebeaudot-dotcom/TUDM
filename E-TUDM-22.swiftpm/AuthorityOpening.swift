import Foundation

struct AuthorityOpening: Identifiable {
    
    let id = UUID()
    
    let code: String
    var name: String
    var type: String
    
    var width: Double
    var height: Double
    var sillHeight: Double?
    
    init(
        code: String,
        name: String,
        type: String,
        width: Double,
        height: Double,
        sillHeight: Double? = nil
    ) {
        self.code = code
        self.name = name
        self.type = type
        self.width = width
        self.height = height
        self.sillHeight = sillHeight
    }
}
