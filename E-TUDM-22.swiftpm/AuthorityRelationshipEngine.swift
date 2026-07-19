import Foundation

struct AuthorityRelationshipEngine {
    
    static func build(
        from authority: RoomAuthority
    ) -> [AuthorityRelationship] {
        
        var relationships: [AuthorityRelationship] = []
        
        relationships.append(
            contentsOf: buildBeamRelationships(
                authority
            )
        )
        
        return relationships
        
    }
    
}

// MARK: - Private

private extension AuthorityRelationshipEngine {
    
    static func buildBeamRelationships(
        _ authority: RoomAuthority
    ) -> [AuthorityRelationship] {
        
        var relationships: [AuthorityRelationship] = []
        
        for record in authority.structure.records {
            
            for beam in record.beams {
                
                relationships.append(
                    
                    AuthorityRelationship(
                        
                        source: beam.code,
                        
                        destination: beam.startColumn,
                        
                        type: .beginsAt
                        
                    )
                    
                )
                
                relationships.append(
                    
                    AuthorityRelationship(
                        
                        source: beam.code,
                        
                        destination: beam.endColumn,
                        
                        type: .endsAt
                        
                    )
                    
                )
                
            }
            
        }
        
        return relationships
        
    }
    
}
