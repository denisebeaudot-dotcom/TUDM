import Foundation

struct Room: Identifiable {
    
    let id = UUID()
    
    let code: String
    let name: String
    
    /// Existing authority system (v21)
    var authority: RoomAuthority
    
    /// NEW: Structural topology layer (v22)
    ///
    /// Describes how every structural element in the room is connected.
    /// This is intentionally separate from RoomAuthority so existing
    /// authority workflows continue to function during the migration.
    var topology: RoomTopology
    
    init(
        code: String,
        name: String,
        authority: RoomAuthority,
        topology: RoomTopology = RoomTopology()
    ) {
        
        self.code = code
        self.name = name
        self.authority = authority
        self.topology = topology
    }
}
