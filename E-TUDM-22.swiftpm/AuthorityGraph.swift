import Foundation

/// The master navigation graph for a room.
///
/// The graph does NOT own authority.
/// It organizes authority.
///
/// RoomAuthority remains the source of truth.
/// AuthorityGraph provides navigation,
/// traversal and validation.
struct AuthorityGraph {
    
    /// Topology for the room.
    private(set) var topology: RoomTopology
    
    init(
        topology: RoomTopology = RoomTopology()
    ) {
        self.topology = topology
    }
    
    // MARK: - Editing
    
    mutating func addWall(
        _ wall: WallTopology
    ) {
        
        topology.add(wall)
    }
    
    mutating func removeWall(
        code: String
    ) {
        
        topology.remove(
            code: code
        )
    }
    
    // MARK: - Lookup
    
    func wall(
        code: String
    ) -> WallTopology? {
        
        topology.wall(
            code: code
        )
    }
    
    func chain(
        wallCode: String
    ) -> StructuralChain? {
        
        topology.chain(
            code: wallCode
        )
    }
    
    func node(
        code: String
    ) -> StructuralNode? {
        
        for wall in topology.walls {
            
            if let node = wall.node(
                code: code
            ) {
                
                return node
            }
        }
        
        return nil
    }
    
    var allWalls: [WallTopology] {
        
        topology.walls
    }
    
    var isEmpty: Bool {
        
        topology.walls.isEmpty
    }
}
