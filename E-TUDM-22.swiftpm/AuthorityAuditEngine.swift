import Foundation

struct AuthorityAuditEngine {
    
    let authority: RoomAuthority
    
    init(
        authority: RoomAuthority
    ) {
        self.authority = authority
    }
    
    // MARK: Public
    
    func audit() -> [AuthorityValidationIssue] {
        
        var issues: [AuthorityValidationIssue] = []
        
        issues.append(
            contentsOf: auditGraph()
        )
        
        issues.append(
            contentsOf: auditStructure()
        )
        
        issues.append(
            contentsOf: auditGeometry()
        )
        
        issues.append(
            contentsOf: auditOpenings()
        )
        
        return issues
    }
    
    // MARK: Graph
    
    private func auditGraph() -> [AuthorityValidationIssue] {
        
        AuthorityGraphValidator.validate(
            authority.graph
        )
    }
    
    // MARK: Structure
    
    private func auditStructure() -> [AuthorityValidationIssue] {
        
        []
        
    }
    
    // MARK: Geometry
    
    private func auditGeometry() -> [AuthorityValidationIssue] {
        
        []
        
    }
    
    // MARK: Openings
    
    private func auditOpenings() -> [AuthorityValidationIssue] {
        
        []
        
    }
    
}
