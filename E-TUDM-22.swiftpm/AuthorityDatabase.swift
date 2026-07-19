import Foundation

struct AuthorityDatabase {
    
    static let familyRoom = Room(
        code: "FR",
        name: "Family Room",
        authority: RoomAuthority(
            
            records: [
                
                AuthorityRecord(
                    code: "W1",
                    name: "Window Wall",
                    type: .wall,
                    status: .verified
                ),
                
                AuthorityRecord(
                    code: "W2",
                    name: "Door Wall",
                    type: .wall,
                    status: .verified
                ),
                
                AuthorityRecord(
                    code: "W3",
                    name: "Stair Wall",
                    type: .wall,
                    status: .verified
                ),
                
                AuthorityRecord(
                    code: "W4",
                    name: "TV Wall",
                    type: .wall,
                    status: .verified
                )
            ],
            
            geometry: RoomGeometry(
                records: [
                    
                    AuthorityGeometryRecord(
                        code: "W1",
                        width: 246,
                        height: 96,
                        ceilingHeight: 96,
                        beamHeight: 88
                    ),
                    
                    AuthorityGeometryRecord(
                        code: "W2",
                        width: 150,
                        height: 96,
                        ceilingHeight: 96,
                        beamHeight: 88
                    ),
                    
                    AuthorityGeometryRecord(
                        code: "W3",
                        width: 149.5,
                        height: 96,
                        ceilingHeight: 96,
                        beamHeight: 88
                    ),
                    
                    AuthorityGeometryRecord(
                        code: "W4",
                        width: 149,
                        height: 96,
                        ceilingHeight: 96,
                        beamHeight: 88
                    )
                ]
            ),
            
            structure: RoomStructure(
                records: [
                    
                    AuthorityStructureRecord(
                        code: "W1",
                        columns: [
                            AuthorityColumn(
                                name: "C1",
                                width: 8,
                                depth: 9.25,
                                height: 88,
                                finish: "Plaster"
                            ),
                            AuthorityColumn(
                                name: "C2",
                                width: 8,
                                depth: 9.25,
                                height: 88,
                                finish: "Plaster"
                            ),
                            AuthorityColumn(
                                name: "C3",
                                width: 8,
                                depth: 9.25,
                                height: 88,
                                finish: "Plaster"
                            ),
                            AuthorityColumn(
                                name: "C4",
                                width: 8,
                                depth: 9.25,
                                height: 88,
                                finish: "Plaster"
                            )
                        ],
                        beams: []
                    ),
                    
                    AuthorityStructureRecord(
                        code: "W2"
                    ),
                    
                    AuthorityStructureRecord(
                        code: "W3"
                    ),
                    
                    AuthorityStructureRecord(
                        code: "W4"
                    )
                ]
            ),
            
            openings: RoomOpenings(
                records: [
                    
                    AuthorityOpeningRecord(
                        code: "W1",
                        openings: [
                            AuthorityOpening(
                                code: "W1-WINDOW-1",
                                name: "Main Window",
                                type: "Window",
                                width: 96,
                                height: 60
                            )
                        ]
                    ),
                    
                    AuthorityOpeningRecord(
                        code: "W2",
                        openings: [
                            AuthorityOpening(
                                code: "W2-DOOR-1",
                                name: "Main Door",
                                type: "Door",
                                width: 30,
                                height: 76
                            )
                        ]
                    ),
                    
                    AuthorityOpeningRecord(
                        code: "W3"
                    ),
                    
                    AuthorityOpeningRecord(
                        code: "W4"
                    )
                ]
            ),
            
            ceilings: RoomCeilings(
                records: [
                    
                    AuthorityCeilingRecord(
                        code: "FR-CEILING-1",
                        height: 96,
                        finish: "Plaster",
                        notes: "Primary Family Room ceiling authority."
                    )
                ]
            )
        )
    )
    
    static let rooms: [Room] = [
        familyRoom
    ]
    
    static func room(
        code: String
    ) -> Room? {
        
        rooms.first {
            $0.code == code
        }
    }
    
    static func record(
        roomCode: String,
        wall: Wall
    ) -> AuthorityRecord? {
        
        room(
            code: roomCode
        )?
            .authority
            .record(
                code: wall.rawValue
            )
    }
    
    static func geometry(
        roomCode: String,
        wall: Wall
    ) -> AuthorityGeometryRecord? {
        
        room(
            code: roomCode
        )?
            .authority
            .geometryRecord(
                code: wall.rawValue
            )
    }
    
    static func structure(
        roomCode: String,
        wall: Wall
    ) -> AuthorityStructureRecord? {
        
        room(
            code: roomCode
        )?
            .authority
            .structureRecord(
                code: wall.rawValue
            )
    }
    
    static func openings(
        roomCode: String,
        wall: Wall
    ) -> [AuthorityOpening] {
        
        room(
            code: roomCode
        )?
            .authority
            .openingRecords(
                code: wall.rawValue
            ) ?? []
    }
    
    static func ceiling(
        roomCode: String,
        code: String
    ) -> AuthorityCeilingRecord? {
        
        room(
            code: roomCode
        )?
            .authority
            .ceilingRecord(
                code: code
            )
    }
}
