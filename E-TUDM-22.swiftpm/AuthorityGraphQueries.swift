import Foundation

extension AuthorityGraph {
    
    // MARK: - Wall Queries
    
    func containsWall(
        code: String
    ) -> Bool {
        
        wall(
            code: code
        ) != nil
    }
    
    // MARK: - Node Queries
    
    func containsNode(
        code: String
    ) -> Bool {
        
        node(
            code: code
        ) != nil
    }
    
    func nodes(
        onWall wallCode: String
    ) -> [StructuralNode] {
        
        chain(
            wallCode: wallCode
        )?.nodes ?? []
    }
    
    // MARK: - Neighbour Queries
    
    func previousNode(
        before code: String
    ) -> StructuralNode? {
        
        for wall in allWalls {
            
            if let node = wall.previousNode(
                before: code
            ) {
                
                return node
                
            }
            
        }
        
        return nil
        
    }
    
    func nextNode(
        after code: String
    ) -> StructuralNode? {
        
        for wall in allWalls {
            
            if let node = wall.nextNode(
                after: code
            ) {
                
                return node
                
            }
            
        }
        
        return nil
        
    }
    
}
