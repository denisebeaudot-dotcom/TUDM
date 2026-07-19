import Foundation

extension AuthorityEngine {
    
    // MARK: - Walls
    
    var walls: [WallTopology] {
        
        graph.allWalls
        
    }
    
    func nodes(
        for wallCode: String
    ) -> [StructuralNode] {
        
        graph
            .chain(
                wallCode: wallCode
            )?
            .nodes ?? []
        
    }
    
    func columns(
        for wallCode: String
    ) -> [StructuralNode] {
        
        nodes(
            for: wallCode
        )
        .filter {
            
            $0.type == .column
            
        }
        
    }
    
    func beams(
        for wallCode: String
    ) -> [StructuralNode] {
        
        nodes(
            for: wallCode
        )
        .filter {
            
            $0.type == .beam
            
        }
        
    }
    
}
