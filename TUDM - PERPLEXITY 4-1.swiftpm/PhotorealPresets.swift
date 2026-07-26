import Foundation

// MARK: - Photoreal render preset
//
// A preset captures every non-structural decision that goes into a
// photoreal render: aesthetic language, palette, materials, atmosphere,
// staging rules, and negative constraints. Structure is never encoded
// here — structure lives in the wall itself (LockedWall + RoomDefaults)
// and in the RealityKit blueprint.
//
// A render request is always the pair:
//     LockedWall + RoomDefaults    → structural blueprint (RealityKit)
//     PhotorealPreset              → styling
//
// Presets are Codable so they can be saved into the project, edited
// through a form, duplicated, and versioned. Bumping `version` lets us
// invalidate old cached renders when a preset materially changes.

struct PhotorealPreset: Codable, Hashable, Identifiable {
    var id: UUID
    var name: String
    var version: Int
    var notes: String
    
    // Aesthetic language
    var aestheticLine: String            // one-line summary, e.g. "boho modern editorial"
    var atmosphereLine: String           // e.g. "warm morning light, quiet, no people"
    
    // Palette
    var wallPlasterHex: String           // e.g. "#F3EEE5"
    var wallReturnAccentHex: String      // sage / clay / neutral — separates return zone from column
    var casingWhiteHex: String           // e.g. "#F7F4EE"
    var beamWoodHex: String              // beam header wood tone
    var floorWoodHex: String             // floor tone
    var upholsteryHex: String            // sofa
    var pillowAccentHex: String          // pillow accent
    var metalHardwareHex: String         // curtain rod, iron
    var rattanHex: String                // side tables, baskets
    
    // Materials
    var upholsteryMaterial: String       // "cream linen"
    var curtainMaterial: String          // "ivory linen"
    var blindMaterial: String            // "warm cream linen roman blinds"
    var floorMaterial: String            // "warm honey oak plank"
    var wallMaterial: String             // "hand-troweled plaster"
    var shelfMaterial: String            // "solid warm oak boards"
    var coffeeTableMaterial: String      // "warm oak with twin pedestals"
    var sideTableMaterial: String        // "natural rattan drum"
    var lampShadeMaterial: String        // "linen drum shade, warm glow"
    
    // Staging rules (props on shelves, plants, etc.)
    var shelfStaging: String
    var plantStaging: String
    var artStaging: String
    
    // Quality controls
    var qualityFlags: String             // "4k detail, photorealistic materials, architectural rendering"
    var cameraLine: String               // "face-on elevation, no perspective distortion"
    
    // Negative constraints
    var negatives: [String]
    
    // Model + aspect
    var modelName: String                // "gpt_image_2"
    var aspectRatio: String              // "16:9"
    
    // Metadata
    var createdAt: Date
    var updatedAt: Date
    
    // Compose the full prompt string. Structural details are injected
    // separately by WallPhotorealRenderer from the wall's own data —
    // this preset only supplies styling language.
    func compose(structural: String) -> String {
        let negativesText = negatives.joined(separator: ", ")
        let negativesLine = negatives.isEmpty ? "" : " Avoid: \(negativesText). "
        return """
        Photorealistic architectural interior render, \(cameraLine). \
        Editorial magazine quality, \(aestheticLine). \(atmosphereLine).
        
        Use the reference image as strict structural blueprint. Every \
        structural element — column count, shelf count per bay, window \
        panel split, muntin grid, beam header, wall returns, casing, \
        curtain rod, blinds, sofa, side tables, coffee table, rug — \
        must match exactly in count, position, and proportion.
        
        Structural detail carried forward from the wall's own data: \
        \(structural)
        
        Palette (approximate hex references): wall plaster \(wallPlasterHex), \
        wall return accent \(wallReturnAccentHex), casing \(casingWhiteHex), \
        beam wood \(beamWoodHex), floor \(floorWoodHex), \
        upholstery \(upholsteryHex), pillow accent \(pillowAccentHex), \
        metal hardware \(metalHardwareHex), rattan \(rattanHex).
        
        Materials: sofa in \(upholsteryMaterial); curtain panels in \(curtainMaterial); \
        blinds in \(blindMaterial); floor in \(floorMaterial); walls in \(wallMaterial); \
        shelves in \(shelfMaterial); coffee table in \(coffeeTableMaterial); \
        side tables in \(sideTableMaterial); lamp shades in \(lampShadeMaterial).
        
        Staging: \(shelfStaging) \(plantStaging) \(artStaging)
        
        Quality: \(qualityFlags).\(negativesLine)
        """
    }
}

// MARK: - Preset library
//
// The library ships with a locked baseline preset — Boho Morning Editorial —
// captured from the accepted Wall 1 v4 photoreal. This preset is what
// makes future renders (Wall 2, Wall 3, Wall 4, any future walls) look
// like they belong in the same room as Wall 1.
//
// Users can duplicate the baseline and edit copies. The baseline itself
// is loaded from a static definition so it is always available even if
// the user hasn't opened the preset editor yet.

enum PhotorealPresetLibrary {
    
    // The locked baseline. This is the aesthetic the accepted Wall 1
    // photoreal was rendered in.
    static var bohoMorningEditorial: PhotorealPreset {
        let now = Date(timeIntervalSince1970: 1_785_000_000)  // stable stamp for the seed
        return PhotorealPreset(
            id: UUID(uuidString: "B0F0B0F0-0001-0001-0001-000000000001")!,
            name: "Boho Morning Editorial",
            version: 1,
            notes: "Baseline preset captured from Wall 1 v4 render. Locked. Duplicate before editing.",
            
            aestheticLine: "boho modern editorial with a warm neutral hand",
            atmosphereLine: "soft morning light from the window, quiet, uncluttered, no people, no visible technology",
            
            wallPlasterHex: "#F3EEE5",
            wallReturnAccentHex: "#A8B69E",     // soft sage
            casingWhiteHex: "#F7F4EE",
            beamWoodHex: "#B48A5F",
            floorWoodHex: "#C99C6E",
            upholsteryHex: "#EDE6D6",
            pillowAccentHex: "#8FA084",         // sage green pillow accent
            metalHardwareHex: "#22201E",
            rattanHex: "#A97A50",
            
            upholsteryMaterial: "cream linen with a soft slubby weave",
            curtainMaterial: "ivory linen, floor length, gathered",
            blindMaterial: "warm cream linen roman blinds pulled to the top third of the window",
            floorMaterial: "warm honey oak plank floor with light natural grain",
            wallMaterial: "hand-troweled matte plaster",
            shelfMaterial: "solid warm oak boards, exposed edges, no cabinet box",
            coffeeTableMaterial: "warm oak round table with twin block pedestals",
            sideTableMaterial: "natural rattan drum with woven weave",
            lampShadeMaterial: "linen drum shade with warm interior glow",
            
            shelfStaging: "shelves lightly styled with a mix of books stacked and standing, a small framed landscape, a ceramic vessel or two, one trailing plant, no more than four objects per shelf.",
            plantStaging: "one live plant per side of the room, warm green, natural not glossy.",
            artStaging: "no artwork on the wall behind the sofa, only the window.",
            
            qualityFlags: "4k detail, photorealistic materials, architectural rendering quality, natural depth of field",
            cameraLine: "face-on elevation view, no perspective distortion, no vanishing point, straight architectural framing",
            
            negatives: [
                "people",
                "text",
                "watermarks",
                "artwork on the wall behind the sofa",
                "modern electronics or screens",
                "clutter",
                "extra columns beyond the four specified",
                "extra shelves beyond the four per bay specified",
                "additional windows",
                "curved or arched openings",
                "perspective distortion"
            ],
            
            modelName: "gpt_image_2",
            aspectRatio: "16:9",
            
            createdAt: now,
            updatedAt: now
        )
    }
    
    // Bundled read-only presets that ship with the app. Users can
    // duplicate any of these to make an editable copy.
    static var bundled: [PhotorealPreset] {
        [bohoMorningEditorial]
    }
    
    // Persistence path for user-created presets.
    static var userPresetsURL: URL {
        let base = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return base.appendingPathComponent("photoreal_presets.json")
    }
    
    // Load all presets (bundled + user).
    static func load() -> [PhotorealPreset] {
        var all = bundled
        if let data = try? Data(contentsOf: userPresetsURL),
           let userPresets = try? JSONDecoder().decode([PhotorealPreset].self, from: data) {
            // Avoid duplicating bundled presets that the user hasn't edited.
            let bundledIDs = Set(bundled.map { $0.id })
            let userOnly = userPresets.filter { !bundledIDs.contains($0.id) }
            all.append(contentsOf: userOnly)
        }
        return all
    }
    
    // Save user presets (bundled ones are filtered out before writing).
    static func save(_ presets: [PhotorealPreset]) {
        let bundledIDs = Set(bundled.map { $0.id })
        let userOnly = presets.filter { !bundledIDs.contains($0.id) }
        do {
            let data = try JSONEncoder().encode(userOnly)
            try data.write(to: userPresetsURL, options: .atomic)
        } catch {
            // Non-fatal: presets that fail to save just aren't persisted.
            // The bundled baseline is always available regardless.
        }
    }
}
