import Foundation

/// Topology describes how the structural chains of a room
/// are organized and connected.
///
/// It intentionally contains no geometry.
/// Geometry remains in the Authority system.
///
/// Topology answers:
///
/// - What walls exist?
/// - What structural chain belongs to each wall?
/// - How do I retrieve a wall's chain?
///
struct RoomTopology {
    
    private(set) var walls: [WallTopology]
    
    init(
        walls: [WallTopology] = []
    ) {
        self.walls = walls
    }
    
    // MARK: - Editing
    
    mutating func add(
        _ wall: WallTopology
    ) {
        walls.removeAll {
            $0.code == wall.code
        }
        
        walls.append(wall)
    }
    
    mutating func remove(
        code: String
    ) {
        walls.removeAll {
            $0.code == code
        }
    }
    
    // MARK: - Lookup
    
    func wall(
        code: String
    ) -> WallTopology? {
        
        walls.first {
            $0.code == code
        }
    }
    
    func chain(
        code: String
    ) -> StructuralChain? {
        
        wall(
            code: code
        )?.chain
    }
}
