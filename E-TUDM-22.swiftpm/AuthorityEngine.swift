import Foundation

struct AuthorityEngine {
    
    let authority: RoomAuthority
    
    init(
        authority: RoomAuthority
    ) {
        
        self.authority = authority
        
    }
    
    // MARK: Graph
    
    var graph: AuthorityGraph {
        
        AuthorityGraphBuilder.build(
            from: authority
        )
        
    }
    
    // MARK: Relationships
    
    var relationships: [AuthorityRelationship] {
        
        AuthorityRelationshipEngine.build(
            from: authority
        )
        
    }
    
    // MARK: Validation
    
    var validationIssues: [AuthorityValidationIssue] {
        
        AuthorityGraphValidator.validate(
            graph
        )
        
    }
    
    // MARK: Convenience
    
    func wall(
        code: String
    ) -> WallTopology? {
        
        graph.wall(
            code: code
        )
        
    }
    
    func node(
        code: String
    ) -> StructuralNode? {
        
        graph.node(
            code: code
        )
        
    }
    
}

