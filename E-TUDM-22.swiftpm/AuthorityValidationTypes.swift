import Foundation

enum AuthorityValidationSeverity {
    
    case info
    case warning
    case error
    
}

struct AuthorityValidationIssue: Identifiable {
    
    let id = UUID()
    
    let severity: AuthorityValidationSeverity
    
    let code: String
    
    let message: String
    
}
