import Foundation

struct AuthorityGraphBuilder {
    
    static func build(
        from authority: RoomAuthority
    ) -> AuthorityGraph {
        
        var graph = AuthorityGraph()
        
        graph = buildStructure(
            authority.structure,
            into: graph
        )
        
        return graph
    }
}

// MARK: - Private

private extension AuthorityGraphBuilder {
    
    static func buildStructure(
        _ structure: RoomStructure,
        into graph: AuthorityGraph
    ) -> AuthorityGraph {
        
        var graph = graph
        
        for record in structure.records {
            
            var wall = WallTopology(
                code: record.code,
                name: record.code
            )
            
            addColumns(
                record.columns,
                to: &wall
            )
            
            addBeams(
                record.beams,
                to: &wall
            )
            
            graph.addWall(wall)
            
        }
        
        return graph
    }
    
    static func addColumns(
        _ columns: [AuthorityColumn],
        to wall: inout WallTopology
    ) {
        
        for column in columns {
            
            wall.addNode(
                
                StructuralNode(
                    
                    code: column.name,
                    name: column.name,
                    type: .column
                    
                )
                
            )
            
        }
        
    }
    
    static func addBeams(
        _ beams: [AuthorityBeam],
        to wall: inout WallTopology
    ) {
        
        for beam in beams {
            
            wall.addNode(
                
                StructuralNode(
                    
                    code: beam.name,
                    name: beam.name,
                    type: .beam
                    
                )
                
            )
            
        }
        
    }
    
}
