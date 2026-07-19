import Foundation

enum Wall: String, CaseIterable, Identifiable {
    
    case w1 = "W1"
    case w2 = "W2"
    case w3 = "W3"
    case w4 = "W4"
    
    var id: String {
        rawValue
    }
}
