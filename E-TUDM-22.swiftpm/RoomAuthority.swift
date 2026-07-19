import Foundation

struct RoomAuthority {
    
    // MARK: - Authority Collections
    
    var records: [AuthorityRecord]
    
    var geometry: RoomGeometry
    
    var structure: RoomStructure
    
    var openings: RoomOpenings
    
    var ceilings: RoomCeilings
    
    // MARK: - Authority Graph
    
    /// Canonical authority graph generated from the
    /// current authority records.
    ///
    /// The graph is rebuilt whenever it is requested,
    /// ensuring it always reflects the latest authority.
    var graph: AuthorityGraph {
        
        AuthorityGraphBuilder.build(
            from: self
        )
        
    }
    
    // MARK: - Records
    
    func record(
        code: String
    ) -> AuthorityRecord? {
        
        records.first {
            $0.code == code
        }
        
    }
    
    // MARK: - Geometry
    
    func geometryRecord(
        code: String
    ) -> AuthorityGeometryRecord? {
        
        geometry.geometry(
            for: code
        )
        
    }
    
    // MARK: - Structure
    
    func structureRecord(
        code: String
    ) -> AuthorityStructureRecord? {
        
        structure.structure(
            for: code
        )
        
    }
    
    // MARK: - Graph
    
    func wallTopology(
        code: String
    ) -> WallTopology? {
        
        graph.wall(
            code: code
        )
        
    }
    
    // MARK: - Openings
    
    func openingRecords(
        code: String
    ) -> [AuthorityOpening] {
        
        openings.openings(
            for: code
        )
        
    }
    
    // MARK: - Ceilings
    
    func ceilingRecord(
        code: String
    ) -> AuthorityCeilingRecord? {
        
        ceilings.ceiling(
            for: code
        )
        
    }
    
}
