import Foundation

// MARK: - Family Room Wood Stove Corner Seed
//
// Step 8. Instantiates Denise's actual family-room wood stove corner as a
// RoomAlcove entity using her real measurements. This is a one-tap seed: it
// creates the alcove entity attached to whatever room you invoke it from,
// with the walls detected by their totalWidth (Wall 3 = 246.00 in, Wall 4 =
// 150.00 in).
//
// Structural fidelity contract:
//   - Wall 3 footprint 53.5 in, anchored at .corner end
//   - Wall 4 footprint 40.75 in, anchored at .origin end
//   - Platform 12 in tall, convex curved front, red brick
//   - Column A (SC9, W3 side): 8 x 9.25 x 84, red brick
//   - Column B (SC10, W4 side): 8 x 9.25 x 84, red brick
//   - Back: concave curved, 84 in tall, feed brick, spans SC9-outer to
//     SC10-outer
//   - 2.25 in asymmetry between SC9 and OP1 is preserved by construction:
//     SC9 sits at the inboard end of the 53.5 in footprint on W3, so its
//     inboard face is at station (W3.totalWidth - 53.5) = 192.5. OP1 ends at
//     station 190.25 (8+39.5+8+48+... - see wall registry). The 2.25 in gap
//     between them is a real-world asymmetry, not something the alcove
//     model creates or hides.
//   - Payload: wood stove with 24 x 22 x 32 stove body sitting on the
//     platform with a 16 in front hearth extension. Adjustable via the
//     alcove editor after seeding.
//   - Alcove is created LOCKED. Structural data is real-wall truth. Unlock
//     via the alcove editor if a genuine measurement changes.

enum FamilyRoomWoodStoveSeed {
    
    /// Signature check: does this room look like the family room this seed is
    /// designed for. Requires exactly one wall at 246.00 in and one at 150.00
    /// in among its walls, with at least four walls total.
    static func matches(room: Room) -> Bool {
        guard room.wallSpecs.count >= 4 else { return false }
        let w246 = room.wallSpecs.contains { abs($0.totalWidth - 246.0) < 0.01 }
        let w150 = room.wallSpecs.contains { abs($0.totalWidth - 150.0) < 0.01 }
        return w246 && w150
    }
    
    /// True once this room already has an alcove with the seed name.
    static func alreadySeeded(room: Room) -> Bool {
        room.alcoves.contains {
            $0.name.trimmingCharacters(in: .whitespaces) == seedName
        }
    }
    
    static let seedName = "Wood Stove Corner"
    
    /// Build the alcove for the given room. Returns nil if the walls needed
    /// cannot be found. Safe to call — does not touch the store; caller
    /// invokes store.addAlcove(...) with the returned value.
    static func makeAlcove(for room: Room) -> RoomAlcove? {
        guard
            let wall3 = room.wallSpecs.first(where: { abs($0.totalWidth - 246.0) < 0.01 }),
            let wall4 = room.wallSpecs.first(where: { abs($0.totalWidth - 150.0) < 0.01 })
        else { return nil }
        
        let anchor = AlcoveCornerAnchor(
            wallA: wall3.id,
            footprintA: 53.5,
            wallB: wall4.id,
            footprintB: 40.75,
            anchorA: .corner,
            anchorB: .origin
        )
        
        let platform = AlcovePlatform(
            height: 12,
            shape: .convexCurvedFront,
            material: .redBrick
        )
        
        let sc9 = AlcoveColumnSpec(
            label: "SC9",
            width: 8,
            depth: 9.25,
            height: 84,
            material: .redBrick,
            notes: "W3 side. Inboard face at station 192.50. 2.25 in gap to OP1 outboard edge is real-wall asymmetry."
        )
        
        let sc10 = AlcoveColumnSpec(
            label: "SC10",
            width: 8,
            depth: 9.25,
            height: 84,
            material: .redBrick,
            notes: "W4 side. Inboard face at station 32.75 measured from W4.origin."
        )
        
        let back = AlcoveBackSpec(
            style: .concaveCurved,
            height: 84,
            material: .feedBrick,
            notes: "Feed brick concave curve arcing between SC9 outer face and SC10 outer face."
        )
        
        let stove = WoodStoveSpec(
            modelName: "",
            manufacturer: "",
            stoveWidth: 24,
            stoveDepth: 22,
            stoveHeight: 32,
            flueDiameter: 6,
            clearanceRating: "12 in rear, 18 in side (typical, verify per model)",
            hearthExtension: 16,
            notes: "Placeholder body dimensions. Update once specific stove model is chosen."
        )
        
        return RoomAlcove(
            name: seedName,
            notes: "Family Room northeast corner. Seeded from real-world measurements. Structural data is ground truth; renderers must respect asymmetry.",
            anchor: anchor,
            platform: platform,
            columnA: sc9,
            columnB: sc10,
            back: back,
            payload: .woodStove(stove),
            isLocked: true
        )
    }
}
