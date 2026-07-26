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
//
// Optional "designer" fields at the bottom of the struct are the
// "full monty" language a professional interior designer would put on
// a client presentation board. They are optional so older JSON still
// decodes and simpler presets can leave them nil.

// A high-level tag for grouping presets in the picker. Optional so
// older saved JSON still decodes. Free-form so users can invent new
// families.
// Render speed tier. Maps to a specific image model. Draft is fast
// concept iteration, Standard is a balanced middle, Final is the
// slowest and highest-quality model. Every preset can be rendered at
// any tier without duplicating the preset.
enum RenderSpeed: String, Codable, Hashable, CaseIterable {
    case draft     // nano_banana_2, ~5-10s
    case standard  // nano_banana_pro, ~15-20s
    case final     // gpt_image_2, ~30-60s
    
    var modelName: String {
        switch self {
        case .draft:    return "nano_banana_2"
        case .standard: return "nano_banana_pro"
        case .final:    return "gpt_image_2"
        }
    }
    
    var label: String {
        switch self {
        case .draft:    return "Draft (fast)"
        case .standard: return "Standard"
        case .final:    return "Final (best)"
        }
    }
}

struct StyleFamily: Codable, Hashable, RawRepresentable {
    var rawValue: String
    init(rawValue: String) { self.rawValue = rawValue }
    
    static let boho             = StyleFamily(rawValue: "Boho")
    static let belgian          = StyleFamily(rawValue: "Belgian Transitional")
    static let japandi          = StyleFamily(rawValue: "Japandi")
    static let parisian         = StyleFamily(rawValue: "Parisian Classic")
    static let warmMinimal      = StyleFamily(rawValue: "Warm Minimal")
    static let englishCountry   = StyleFamily(rawValue: "English Country")
    static let scandi           = StyleFamily(rawValue: "Scandinavian")
    static let midCentury       = StyleFamily(rawValue: "Mid-Century Modern")
    static let gentlemansLibrary = StyleFamily(rawValue: "Gentleman's Library")
    static let custom           = StyleFamily(rawValue: "Custom")
}

struct PhotorealPreset: Codable, Hashable, Identifiable {
    var id: UUID
    var name: String
    var version: Int
    var notes: String
    var styleFamily: StyleFamily?
    
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
    
    // MARK: Full-monty designer language (all optional)
    
    // One-line editorial framing, the kind of tag line at the top of a
    // presentation board. Example: "A quiet morning corner in a Quebec
    // country home — considered, feminine, unhurried."
    var artDirection: String?
    
    // Lens and camera language a photographer would use. Example:
    // "shot on 50mm, sensor plane exactly parallel to the wall, no tilt"
    var lensAndCamera: String?
    
    // Rich time-of-day + light description that goes beyond atmosphereLine.
    // Example: "9:30 AM light entering from the left, warm 4200K bounce
    // off the oak floor, soft shadow line under the sofa, no direct sun on
    // upholstery."
    var timeOfDayAndLight: String?
    
    // 3-5 emotional adjectives. Example: "considered, unhurried, warm,
    // feminine, quietly confident"
    var moodDescriptors: String?
    
    // Designer-grade material specificity: weave, finish, patina, edge
    // treatment. Example: "linen sofa upholstery in a heavy weight with
    // visible slub, hand-oiled brass curtain rod with a matte patina,
    // unfilled oak grain with occasional knots, hand-worn floorboard
    // edges."
    var materialSpecificity: String?
    
    // Styling props at the level of a real stylist: specific books,
    // ceramics, textiles, greenery. Example: "a pair of hand-thrown
    // cream ceramic vessels on the third shelf, a stack of two art books
    // spine-out on the coffee table, one loosely folded oatmeal throw on
    // the sofa arm, a single stem of eucalyptus in a small clear vase."
    var stylingProps: String?
    
    // Subtle finishing notes: fabric wear, plant lean, wood knot
    // placement. Example: "linen curtain pooling slightly on the floor,
    // one pillow softly indented, eucalyptus stem leaning toward the
    // window, rug corner just barely turned up."
    var finishNotes: String?
    
    // The one-line "designer signature" line, the tone that closes the
    // prompt. Example: "Render as if photographed for the cover of an
    // interiors magazine — not staged, but styled with intent."
    var designerSignatureLine: String?
    
    // MARK: Compose
    
    // Compose the full prompt string. Structural details are injected
    // separately by WallPhotorealRenderer from the wall's own data —
    // this preset only supplies styling language.
    func compose(structural: String) -> String {
        let negativesText = negatives.joined(separator: ", ")
        let negativesLine = negatives.isEmpty ? "" : " Avoid: \(negativesText). "
        
        // Designer-language blocks (only appear when non-nil / non-empty)
        var designerBlocks: [String] = []
        
        if let art = artDirection, !art.isEmpty {
            designerBlocks.append("Art direction: \(art)")
        }
        if let lens = lensAndCamera, !lens.isEmpty {
            designerBlocks.append("Camera and lens: \(lens)")
        }
        if let tod = timeOfDayAndLight, !tod.isEmpty {
            designerBlocks.append("Time of day and light: \(tod)")
        }
        if let mood = moodDescriptors, !mood.isEmpty {
            designerBlocks.append("Mood: \(mood)")
        }
        if let matSpec = materialSpecificity, !matSpec.isEmpty {
            designerBlocks.append("Material specificity: \(matSpec)")
        }
        if let props = stylingProps, !props.isEmpty {
            designerBlocks.append("Styling props: \(props)")
        }
        if let finish = finishNotes, !finish.isEmpty {
            designerBlocks.append("Finishing notes: \(finish)")
        }
        
        let designerSection = designerBlocks.isEmpty
            ? ""
            : "\n\n" + designerBlocks.joined(separator: "\n\n") + "\n"
        
        let signatureLine = (designerSignatureLine?.isEmpty == false)
            ? "\n\n\(designerSignatureLine!)"
            : ""
        
        return """
        Photorealistic architectural interior render, \(cameraLine). \
        Editorial magazine quality, \(aestheticLine). \(atmosphereLine).
        
        THE REFERENCE IMAGE IS A DIMENSIONED ARCHITECTURAL ELEVATION MASK, \
        not a photograph. Every zone width, column position, shelf edge, \
        window mullion, and furniture silhouette in the reference is the \
        exact real-world geometry of the wall. Do not adjust it, do not \
        center it, do not balance it, do not resize any zone. Match every \
        horizontal position and every vertical height exactly, then paint \
        materials, lighting, and atmosphere on top of this geometry.
        
        COMPLETE PALETTE AND MATERIAL REPLACEMENT. The flat colors in the \
        reference are zone markers only, not the target palette. Apply the \
        materials specified below across every zone. Ignore the reference \
        image's colors, textures, and lighting entirely.
        
        FRAMING: face-on architectural elevation. Sensor plane parallel to \
        the wall. No perspective, no vanishing point, no lens tilt. The \
        wall fills the frame edge-to-edge. The first column sits flush at \
        the left frame edge and the last column sits flush at the right \
        frame edge. Nothing exists beyond either outer column — no plaster \
        returns, no adjacent rooms, no fireplaces, no mantels, no doorways, \
        no additional furniture, no framed art on outer walls.
        
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
        
        Staging: \(shelfStaging) \(plantStaging) \(artStaging)\(designerSection)
        Quality: \(qualityFlags).\(negativesLine)\(signatureLine)
        """
    }
}

// MARK: - Preset library
//
// The library ships with locked baseline presets — Boho Morning Editorial
// (pragmatic v1) and Boho Morning Editorial — Signature (full-monty v2),
// captured from the accepted Wall 1 v4 photoreal and elevated with
// designer-portfolio language. These presets are what make future
// renders (Wall 2, Wall 3, Wall 4, any future walls) look like they
// belong in the same home as Wall 1.
//
// Users can duplicate any bundled preset and edit copies. The baselines
// are loaded from static definitions so they are always available even
// if the user hasn't opened the preset editor yet.

enum PhotorealPresetLibrary {
    
    // MARK: v1 — Pragmatic baseline
    //
    // The locked baseline. Concise prompt that produced the accepted
    // Wall 1 v4 render. Use when Signature is too maximalist.
    static var bohoMorningEditorial: PhotorealPreset {
        let now = Date(timeIntervalSince1970: 1_785_000_000)  // stable stamp for the seed
        return PhotorealPreset(
            id: UUID(uuidString: "B0F0B0F0-0001-0001-0001-000000000001")!,
            name: "Boho Morning Editorial",
            version: 1,
            notes: "Baseline preset captured from Wall 1 v4 render. Locked. Duplicate before editing.",
            styleFamily: .boho,
            
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
            updatedAt: now,
            
            artDirection: nil,
            lensAndCamera: nil,
            timeOfDayAndLight: nil,
            moodDescriptors: nil,
            materialSpecificity: nil,
            stylingProps: nil,
            finishNotes: nil,
            designerSignatureLine: nil
        )
    }
    
    // MARK: v2 — Signature (full-monty designer preset)
    //
    // Elevated preset with the language a talented interior designer
    // would put on a client presentation board. Every field of the
    // designer section is populated. Use as your first-style render;
    // duplicate and dial back if too maximalist.
    static var bohoMorningEditorialSignature: PhotorealPreset {
        let now = Date(timeIntervalSince1970: 1_785_000_000)
        return PhotorealPreset(
            id: UUID(uuidString: "B0F0B0F0-0002-0002-0002-000000000002")!,
            name: "Boho Morning Editorial — Signature",
            version: 2,
            notes: "Full-monty preset. Designer presentation caliber. Locked. Duplicate before editing. Dial back individual designer fields if too maximalist.",
            styleFamily: .boho,
            
            aestheticLine: "considered boho modern editorial, warm neutral hand, quiet confidence, feminine but architectural",
            atmosphereLine: "soft morning light from the window, quiet, uncluttered, no people, no visible technology, an inhabited room caught in a still moment",
            
            wallPlasterHex: "#F3EEE5",
            wallReturnAccentHex: "#A8B69E",
            casingWhiteHex: "#F7F4EE",
            beamWoodHex: "#B48A5F",
            floorWoodHex: "#C99C6E",
            upholsteryHex: "#EDE6D6",
            pillowAccentHex: "#8FA084",
            metalHardwareHex: "#22201E",
            rattanHex: "#A97A50",
            
            upholsteryMaterial: "heavyweight cream linen with visible slub, softly rumpled, hand-loomed feel",
            curtainMaterial: "ivory linen floor-length panels, gathered on the rod, pooling by half an inch on the floor",
            blindMaterial: "warm cream linen roman blinds pulled to the top third of the window, soft folds",
            floorMaterial: "warm honey oak plank floor, wide boards, matte hand-oiled finish, occasional visible knot, no gloss",
            wallMaterial: "hand-troweled matte plaster with subtle tonal variation, no perfect uniformity",
            shelfMaterial: "solid warm oak boards, exposed edges, live-edge suggestion at ends, no cabinet box, no side panels, supported between columns",
            coffeeTableMaterial: "warm oak round table with twin block pedestals, matte hand-oiled finish, edge softened not sharp",
            sideTableMaterial: "natural rattan drum, tight open weave, honey-toned",
            lampShadeMaterial: "off-white linen drum shade with a warm interior glow, faint texture visible from the light",
            
            shelfStaging: "shelves styled with restraint — mix of books stacked horizontally and standing vertically, spines mostly linen and paper not glossy, a small framed vintage landscape, one or two hand-thrown ceramic vessels in warm off-white, one trailing plant per bay, no more than four objects per shelf, generous negative space.",
            plantStaging: "one live plant per side of the room, warm green foliage, natural not glossy, one leaf slightly turned toward the window.",
            artStaging: "no artwork on the wall behind the sofa, only the window and its light.",
            
            qualityFlags: "photorealistic architectural rendering, 4k detail, natural depth of field, film-grain-free but with subtle tonal richness, editorial magazine printing quality",
            cameraLine: "face-on elevation view, sensor plane exactly parallel to the wall, no perspective distortion, no vanishing point, no lens tilt, straight architectural framing with the wall filling the frame",
            
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
                "perspective distortion",
                "over-styling",
                "matched pairs of decorative objects",
                "glossy plastic finishes",
                "cool blue light",
                "harsh direct sunlight on upholstery",
                "obvious CGI artifacts",
                "geometric perfection in the fabric folds"
            ],
            
            modelName: "gpt_image_2",
            aspectRatio: "16:9",
            
            createdAt: now,
            updatedAt: now,
            
            artDirection: "A quiet morning corner in a Quebec country home — considered, feminine, unhurried, the kind of room where you would sit alone with coffee and a book and not reach for your phone.",
            
            lensAndCamera: "shot on a 50mm equivalent, sensor plane exactly parallel to the wall, no tilt, no shift, no vignette, aperture around f/5.6 for even sharpness across the wall with a subtle natural depth on the sofa and coffee table.",
            
            timeOfDayAndLight: "9:30 AM light entering the window from the exterior, warm neutral color temperature around 4200K, gentle bounce off the honey oak floor lifting the underside of the sofa, soft indirect shadow beneath the coffee table, no direct sun landing on the linen upholstery, sage returns catching a slightly cooler note than the plaster field.",
            
            moodDescriptors: "considered, unhurried, warm, feminine, quietly confident, lived-in, editorial",
            
            materialSpecificity: "linen upholstery in a heavy weight with visible slub, softly rumpled seat cushions not crisp; oiled brass or blackened iron curtain rod with a matte patina not shiny lacquer; unfilled oak grain with occasional visible knots on the shelves and floor; hand-worn floorboard edges softened at joints; ceramic vessels showing the throwing lines and a faint matte glaze; rattan side tables with a tight regular weave and honey-toned age.",
            
            stylingProps: "on the shelves: a pair of hand-thrown cream ceramic vessels grouped on one shelf, a stack of two horizontal art books on another, three linen-bound books standing on a third with a small vintage brass object as a bookend, one trailing pothos or philodendron softening a corner; on the coffee table: a stack of two horizontal design books spine-out with a small ceramic dish on top, no more; on the sofa: one loosely folded oatmeal linen throw draped over the arm, two pillows with the sage accent pillow slightly forward; a single stem of eucalyptus or olive branch in a small clear glass vase on the side table.",
            
            finishNotes: "linen curtain panels pooling slightly on the floor with an unhurried drape; one sofa pillow softly indented as though recently leaned on; eucalyptus stem leaning slightly toward the window light; rug corner just barely turned up nearest the sofa; one book on the coffee table sitting a quarter inch off-parallel to the table edge; a barely visible ceramic mug on one of the shelves suggesting the room is used.",
            
            designerSignatureLine: "Render as if photographed for the cover of an interiors magazine — not staged, but styled with intent. Every object earns its place. Restraint over abundance. Warmth over polish. Signed: a designer with a strong point of view."
        )
    }
    
    // MARK: v2 — Belgian Transitional Country House (full monty)
    //
    // The Axel Vervoordt / Vincent Van Duysen / Flamant world: warm
    // lime-washed plaster, aged oak, blackened iron, natural linen with
    // muted ivory and stone, restrained European elegance. Feels like
    // a Belgian farmhouse translated into a quiet living room.
    static var belgianTransitionalCountryHouse: PhotorealPreset {
        let now = Date(timeIntervalSince1970: 1_785_000_000)
        return PhotorealPreset(
            id: UUID(uuidString: "B0F0B0F0-0003-0003-0003-000000000003")!,
            name: "Belgian Transitional — Country House",
            version: 1,
            notes: "Full-monty preset. Belgian country house translated into a warm living room. Axel Vervoordt / Vincent Van Duysen / Flamant sensibility. Locked. Duplicate before editing.",
            styleFamily: .belgian,
            
            aestheticLine: "Belgian transitional country house, warm lime-washed plaster, aged oak, restrained European elegance",
            atmosphereLine: "overcast morning light through the window, quiet, uncluttered, no people, an old-world room caught mid-breath",
            
            wallPlasterHex: "#E8E1D3",           // warm lime-washed plaster
            wallReturnAccentHex: "#B5AA97",      // deeper stone / clay
            casingWhiteHex: "#EFE9DC",
            beamWoodHex: "#7A5A3C",              // darker aged oak
            floorWoodHex: "#8E6B48",             // reclaimed oak, deeper
            upholsteryHex: "#D8CFBE",            // heavy natural linen
            pillowAccentHex: "#7A6E5A",          // muted olive-taupe
            metalHardwareHex: "#1B1916",         // blackened iron
            rattanHex: "#8A6E4E",
            
            upholsteryMaterial: "heavyweight natural linen, softly rumpled, with the character of aged fabric",
            curtainMaterial: "heavy natural linen floor-length panels, gathered on iron rings on a matte black iron rod, pooling deliberately on the floor",
            blindMaterial: "none — curtains only",
            floorMaterial: "reclaimed European oak plank floor, wide boards, hand-scraped and oiled matte finish, visible patina and age",
            wallMaterial: "lime-washed matte plaster with intentional tonal variation, chalky depth, softly imperfect",
            shelfMaterial: "solid aged oak boards, dark honey tone, exposed edges, no cabinet box",
            coffeeTableMaterial: "aged oak plank coffee table with a hand-hewn base, matte oiled finish, softly worn edges",
            sideTableMaterial: "antique-inspired dark oak side tables with turned legs, or aged iron pedestals",
            lampShadeMaterial: "natural linen drum shade with a warm amber interior glow",
            
            shelfStaging: "shelves styled with restraint and age — leather-bound and linen-wrapped books, a small oil painting propped against the back of one shelf, one or two hand-thrown stoneware vessels in matte grey-cream, a single antique brass object, a trailing ivy or philodendron, no more than four objects per shelf, deliberate negative space.",
            plantStaging: "one large sculptural olive branch or ivy in a stoneware urn per side of the room, soft muted green, natural not glossy.",
            artStaging: "no artwork on the wall behind the sofa, only the window and its filtered light.",
            
            qualityFlags: "photorealistic architectural rendering, 4k detail, natural depth of field, matte tonal richness, editorial magazine printing quality with muted European light",
            cameraLine: "face-on elevation view, sensor plane exactly parallel to the wall, no perspective distortion, no vanishing point, no lens tilt, straight architectural framing with the wall filling the frame",
            
            negatives: [
                "people", "text", "watermarks",
                "artwork on the wall behind the sofa",
                "modern electronics or screens",
                "clutter",
                "extra columns beyond the four specified",
                "extra shelves beyond the four per bay specified",
                "additional windows",
                "curved or arched openings",
                "perspective distortion",
                "bright saturated colors",
                "orange or yellow undertones",
                "glossy finishes",
                "chrome or polished metal",
                "American farmhouse styling",
                "shiplap",
                "barn doors"
            ],
            
            modelName: "gpt_image_2",
            aspectRatio: "16:9",
            
            createdAt: now,
            updatedAt: now,
            
            artDirection: "An 18th-century Belgian farmhouse living room, translated into a working modern home. Old bones. Warm materials that have seen decades. The kind of room where nothing is new but everything is right.",
            
            lensAndCamera: "shot on a 50mm equivalent, sensor plane exactly parallel to the wall, no tilt, no shift, aperture around f/5.6, gentle natural falloff on the coffee table",
            
            timeOfDayAndLight: "overcast late morning light, cool-neutral around 5200K softened by lime-washed walls, no direct sun, even diffuse fill, deeper shadows in the return zones and behind the sofa, subtle amber glow from the lamp shades",
            
            moodDescriptors: "restrained, aged, considered, quietly luxurious, European, unornamented",
            
            materialSpecificity: "lime-washed plaster with a chalky matte finish and intentional cloud-like tonal variation; aged oak floorboards with visible saw marks, wormholes, and softened board edges; blackened iron rod with a hand-forged texture, matte not painted; heavy linen with a coarse open weave, softly wrinkled at the seams; stoneware ceramics with an unglazed matte body and a single soft glaze line; leather-bound books with visible wear on the spines",
            
            stylingProps: "on the shelves: a small oil painting on canvas propped against the shelf back, three leather-bound books lying horizontally, two standing books wrapped in linen, a single matte stoneware pitcher, an antique brass candlestick unlit, a trailing ivy softening one corner. On the coffee table: a stack of two large linen-covered art books with a small stoneware bowl on top, a matte pewter tray with nothing on it. On the sofa: one softly rumpled heavy linen throw folded once and draped over the arm, two pillows with the muted olive accent pillow leaning slightly forward. A single sculptural olive branch in a large hand-thrown stoneware urn on the floor beside the side table.",
            
            finishNotes: "curtain panels pooling on the floor with an intentional gathered fall; linen upholstery softly wrinkled at the seat cushion seams; one book on the coffee table sitting a half inch off-parallel; the olive branch leaning slightly toward the window; the rug corner nearest the sofa turned up by a hair; a faint softness of dust light in the air suggesting an old house that is still alive",
            
            designerSignatureLine: "Render as if photographed for a European interiors monograph — patient, restrained, quietly aristocratic. Nothing is new. Everything belongs. Signed: a designer working from memory of a Flemish country house."
        )
    }
    
    // MARK: v2 — Japandi Quiet Morning (full monty)
    //
    // The Norm Architects / Naoto Fukasawa world: pale oak, off-white
    // plaster, black iron, sculptural restraint, wabi-sabi imperfection,
    // a room that could be Tokyo or Copenhagen. Fewer objects, more air.
    static var japandiQuietMorning: PhotorealPreset {
        let now = Date(timeIntervalSince1970: 1_785_000_000)
        return PhotorealPreset(
            id: UUID(uuidString: "B0F0B0F0-0004-0004-0004-000000000004")!,
            name: "Japandi — Quiet Morning",
            version: 1,
            notes: "Full-monty preset. Norm Architects / Naoto Fukasawa sensibility. Wabi-sabi restraint. Locked. Duplicate before editing.",
            styleFamily: .japandi,
            
            aestheticLine: "Japandi — the intersection of Japanese wabi-sabi and Scandinavian restraint, pale oak and off-white plaster, sculptural minimalism with warmth",
            atmosphereLine: "cool morning light from the window, deeply quiet, uncluttered to the edge of empty, no people, no technology, air itself is the material",
            
            wallPlasterHex: "#EFEBE3",           // slightly cooler than boho plaster
            wallReturnAccentHex: "#C5BFB1",      // pale stone
            casingWhiteHex: "#F1EEE6",
            beamWoodHex: "#A88A66",              // pale oak beam
            floorWoodHex: "#D2B892",             // pale oak floor
            upholsteryHex: "#E0D9C6",            // stone-linen
            pillowAccentHex: "#2A2A28",          // near-black accent
            metalHardwareHex: "#161513",         // matte black iron
            rattanHex: "#8E7451",                // pale rattan
            
            upholsteryMaterial: "pale stone linen with a clean flat weave, quiet drape, no visible rumple",
            curtainMaterial: "off-white linen floor-length panels, hanging clean and straight, minimal pooling, on a matte black iron rod",
            blindMaterial: "pale natural bamboo or wood-slat blind pulled to the top of the window",
            floorMaterial: "pale oak plank floor, wide boards, matte finish, minimal grain contrast, softly clean",
            wallMaterial: "matte lime-plaster in a cool off-white, very subtle tonal variation, nearly uniform",
            shelfMaterial: "pale oak boards, thin profile, exposed edges, no cabinet box, nearly floating",
            coffeeTableMaterial: "low pale oak plank coffee table on a single sculptural pedestal, softened edges",
            sideTableMaterial: "low pale oak or hand-thrown ceramic pedestal side tables, sculptural",
            lampShadeMaterial: "paper or rice-paper drum shade, softly warm interior glow",
            
            shelfStaging: "shelves nearly empty — one hand-thrown ceramic vessel per shelf at most, a single stoneware bowl, one small book lying horizontally, a single sculptural branch of dried grass. Two shelves may be entirely empty. Air is the primary object.",
            plantStaging: "one sculptural branch — dried pampas grass, a single bare wood stem, or a small bonsai — per side of the room, muted natural tone, deliberately sparse.",
            artStaging: "no artwork anywhere, only the wall itself and the window.",
            
            qualityFlags: "photorealistic architectural rendering, 4k detail, natural depth of field, quiet tonal minimalism, editorial magazine printing quality with soft cool morning light",
            cameraLine: "face-on elevation view, sensor plane exactly parallel to the wall, no perspective distortion, no vanishing point, no lens tilt, straight architectural framing",
            
            negatives: [
                "people", "text", "watermarks",
                "artwork on the wall behind the sofa",
                "modern electronics or screens",
                "clutter",
                "any object density that fills more than 20 percent of a shelf",
                "extra columns beyond the four specified",
                "extra shelves beyond the four per bay specified",
                "additional windows",
                "curved or arched openings",
                "perspective distortion",
                "warm orange light",
                "boho macramé or fringe",
                "pillows in more than two colors",
                "pattern of any kind",
                "glossy finishes"
            ],
            
            modelName: "gpt_image_2",
            aspectRatio: "16:9",
            
            createdAt: now,
            updatedAt: now,
            
            artDirection: "A morning room where the air itself is the primary material. Fewer objects than feels comfortable, held together by proportion and light. Half Copenhagen, half Kyoto.",
            
            lensAndCamera: "shot on a 50mm equivalent, sensor plane exactly parallel to the wall, no tilt, no shift, aperture around f/5.6, uniform sharpness, quiet composition",
            
            timeOfDayAndLight: "cool morning light entering the window, color temperature around 5600K, no direct sun, diffuse and even, very soft shadows, pale oak floor picking up a gentle warm bounce that never turns yellow",
            
            moodDescriptors: "quiet, spare, sculptural, still, patient, wabi-sabi, meditative",
            
            materialSpecificity: "pale oak with a matte hand-oiled finish and near-invisible grain; matte black iron with a soft brushed texture; plaster walls with the faintest cloud-like tonal wash; linen upholstery in a clean flat weave with almost no visible slub; stoneware ceramics with an unglazed matte body and asymmetric hand-formed edges; bamboo or wood-slat blind with visible weave and slight color variation between slats",
            
            stylingProps: "on the shelves: one matte black stoneware vessel per shelf at most, a single horizontal book on one shelf, a small ceramic bowl on another, one shelf entirely empty. On the coffee table: a single stoneware bowl, nothing else. On the sofa: one folded natural linen throw over the arm, two pillows only, the accent pillow in near-black stone-linen. A single dried pampas stem or bare branch in a pale ceramic vase on the floor beside the side table.",
            
            finishNotes: "curtain panels hanging clean and vertical with minimal pooling; the pampas stem tilted three degrees off vertical; one shelf deliberately left empty; the throw folded once with a hand-flattened crease; the rug corner set precisely square",
            
            designerSignatureLine: "Render as if photographed for Kinfolk or Openhouse magazine — restraint as the loudest gesture. Silence as decoration. Signed: a designer who values the space between objects more than the objects."
        )
    }
    
    // MARK: v2 — Parisian Classic Morning Salon (full monty)
    //
    // The Joseph Dirand / India Mahdavi / Studio KO world: creamy off-
    // white walls with the whisper of grey undertone, warm oak or
    // walnut, aged brass, velvet or bouclé upholstery, one confident
    // color accent, a room that could be in the 6th arrondissement.
    static var parisianClassicMorningSalon: PhotorealPreset {
        let now = Date(timeIntervalSince1970: 1_785_000_000)
        return PhotorealPreset(
            id: UUID(uuidString: "B0F0B0F0-0005-0005-0005-000000000005")!,
            name: "Parisian Classic — Morning Salon",
            version: 1,
            notes: "Full-monty preset. Joseph Dirand / India Mahdavi sensibility. Restrained French elegance, one confident color note. Locked. Duplicate before editing.",
            styleFamily: .parisian,
            
            aestheticLine: "Parisian classic morning salon, creamy off-white walls with a whisper of grey, warm walnut, aged brass, quiet French elegance with one confident color note",
            atmosphereLine: "soft filtered morning light, quiet, composed, no people, an unhurried salon on the Left Bank",
            
            wallPlasterHex: "#EDE7DC",           // creamy off-white with grey whisper
            wallReturnAccentHex: "#C7B7A1",      // aged putty
            casingWhiteHex: "#F3EEE4",
            beamWoodHex: "#6E4E33",              // deep walnut beam
            floorWoodHex: "#8B5E3C",             // walnut herringbone tone
            upholsteryHex: "#D9C9AE",            // bouclé cream
            pillowAccentHex: "#5F2A2A",          // one deep burgundy accent
            metalHardwareHex: "#7A5A2E",         // aged brass
            rattanHex: "#7A5636",
            
            upholsteryMaterial: "cream bouclé sofa upholstery with a soft nubby texture, gently rumpled",
            curtainMaterial: "heavy cream silk-linen blend floor-length panels, softly gathered, on an aged brass rod with matching finials",
            blindMaterial: "none — curtains only",
            floorMaterial: "warm walnut plank floor, matte hand-oiled finish, subtle grain, no herringbone (respect the wall’s straight geometry)",
            wallMaterial: "hand-troweled matte plaster in creamy off-white with a barely perceptible grey undertone, softly imperfect",
            shelfMaterial: "solid walnut boards with a warm honey undertone, exposed edges, no cabinet box",
            coffeeTableMaterial: "warm walnut round coffee table with a single turned pedestal base, matte hand-oiled finish",
            sideTableMaterial: "aged brass drum side tables with a soft patina, matte not shiny",
            lampShadeMaterial: "cream silk drum shade with a warm interior glow",
            
            shelfStaging: "shelves styled with confident restraint — leather-bound French novels stacked horizontally and standing vertically, a small oil portrait or landscape propped on one shelf, one aged brass object, one hand-thrown ceramic vessel in matte cream, a small stack of Cahiers d'Art or similar art monographs, no more than four objects per shelf, generous negative space.",
            plantStaging: "one large sculptural fig or olive tree in an aged terracotta pot on one side of the room, one small sprig of dried flowers in a slim glass vase on the other side.",
            artStaging: "no artwork on the wall behind the sofa, only the window and its filtered light. A small oil painting may lean on a shelf.",
            
            qualityFlags: "photorealistic architectural rendering, 4k detail, natural depth of field, subtle tonal warmth, editorial magazine printing quality with filtered Parisian morning light",
            cameraLine: "face-on elevation view, sensor plane exactly parallel to the wall, no perspective distortion, no vanishing point, no lens tilt, straight architectural framing",
            
            negatives: [
                "people", "text", "watermarks",
                "artwork on the wall behind the sofa",
                "modern electronics or screens",
                "clutter",
                "extra columns beyond the four specified",
                "extra shelves beyond the four per bay specified",
                "additional windows",
                "curved or arched openings",
                "perspective distortion",
                "boho macramé or fringe",
                "American farmhouse styling",
                "beige-only palette without an accent color",
                "shiny lacquer",
                "chrome or polished steel"
            ],
            
            modelName: "gpt_image_2",
            aspectRatio: "16:9",
            
            createdAt: now,
            updatedAt: now,
            
            artDirection: "A morning salon in a Left Bank apartment. High-ceilinged, quiet, composed. One deep burgundy note in a room of creams and walnut. The kind of room where a novel is halfway finished on the sofa arm.",
            
            lensAndCamera: "shot on a 50mm equivalent, sensor plane exactly parallel to the wall, no tilt, no shift, aperture around f/5.6, gentle natural falloff on the coffee table",
            
            timeOfDayAndLight: "soft filtered morning light through gauzy sheer, color temperature around 4400K, no direct sun on the upholstery, warm bounce off the walnut floor lifting the underside of the sofa, aged brass catching a soft honey highlight",
            
            moodDescriptors: "elegant, unhurried, composed, quietly luxurious, French, literary",
            
            materialSpecificity: "cream bouclé with a coarse nubby loop and soft folds at the seams; walnut floor and shelves with matte hand-oiled finish and warm honey undertone, no varnish; aged brass with a matte patina and no lacquer, showing decades of soft handling; hand-troweled plaster with the faintest grey undertone and cloud-like variation; leather-bound books with soft spine wear and gilt lettering barely legible",
            
            stylingProps: "on the shelves: three leather-bound French novels stacked horizontally with gilt spines, two standing books with linen wraps, a small oil portrait or landscape propped against the shelf back, an aged brass candlestick unlit, one hand-thrown matte cream ceramic vessel. On the coffee table: a stack of two large art monographs with an aged brass tray on top holding a small stoneware bowl. On the sofa: one softly folded cream cashmere throw over the arm, two pillows with the deep burgundy accent pillow leaning slightly forward. A large sculptural fig or olive tree in an aged terracotta pot on the floor beside the side table.",
            
            finishNotes: "curtain panels pooling half an inch on the floor with an unhurried gather; bouclé cushions softly indented as if recently used; one book on the coffee table sitting a quarter inch off-parallel; the fig tree's largest leaf turned slightly toward the window; the rug corner nearest the sofa turned up by a hair; a soft dust of morning light in the air",
            
            designerSignatureLine: "Render as if photographed for AD France or The World of Interiors — restrained, composed, one confident color. Signed: a designer with a Left Bank apartment and a strong opinion about walnut."
        )
    }
    
    // MARK: v2 — Warm Minimal Studio (full monty)
    //
    // The Vincent Van Duysen / John Pawson / Rose Uniacke world (leaning
    // spare): warm off-whites, pale oak, one texture, one plant, nothing
    // else. For clients who want quiet, not empty.
    static var warmMinimalStudio: PhotorealPreset {
        let now = Date(timeIntervalSince1970: 1_785_000_000)
        return PhotorealPreset(
            id: UUID(uuidString: "B0F0B0F0-0006-0006-0006-000000000006")!,
            name: "Warm Minimal — Studio",
            version: 1,
            notes: "Full-monty preset. Vincent Van Duysen / John Pawson / Rose Uniacke sensibility leaning spare. Warm not cold, quiet not empty. Locked. Duplicate before editing.",
            styleFamily: .warmMinimal,
            
            aestheticLine: "warm minimal studio, pale oak and off-white plaster, one texture, one plant, quiet architectural presence",
            atmosphereLine: "even morning light, deeply quiet, uncluttered, no people, a room that reads as one continuous material gesture",
            
            wallPlasterHex: "#F0EAE0",
            wallReturnAccentHex: "#D4C9B4",      // very close to plaster, quieter accent
            casingWhiteHex: "#F3EDE3",
            beamWoodHex: "#B8987B",              // pale oak beam
            floorWoodHex: "#D6BE9E",             // pale oak floor
            upholsteryHex: "#E3DBCB",            // warm cream linen
            pillowAccentHex: "#B39F82",          // subtle warm taupe, same family
            metalHardwareHex: "#151412",         // matte black
            rattanHex: "#9C7F5F",
            
            upholsteryMaterial: "warm cream linen, clean weave, softly quiet drape",
            curtainMaterial: "warm cream linen floor-length panels, hanging clean and straight with minimal pooling, on a matte black iron rod",
            blindMaterial: "none — curtains only, or bare window",
            floorMaterial: "pale oak plank floor, wide boards, matte hand-oiled finish, minimal grain contrast",
            wallMaterial: "hand-troweled matte plaster, warm off-white, subtle cloud-like tonal variation",
            shelfMaterial: "pale oak boards, thin clean profile, exposed edges, no cabinet box",
            coffeeTableMaterial: "low pale oak coffee table on a single sculptural block base, softened edges",
            sideTableMaterial: "pale oak or hand-thrown ceramic pedestal side tables",
            lampShadeMaterial: "warm cream linen drum shade, softly warm interior glow",
            
            shelfStaging: "shelves styled with radical restraint — one hand-thrown matte cream ceramic vessel per shelf, one horizontal book per shelf, one shelf left completely empty, one small sculptural object of driftwood or bone. Every object is roughly the same warm neutral tone. Air between objects is the composition.",
            plantStaging: "one large architectural plant — an olive tree or a fiddle-leaf fig — in a matte stoneware planter on one side of the room only. The other side is empty.",
            artStaging: "no artwork anywhere, only the window.",
            
            qualityFlags: "photorealistic architectural rendering, 4k detail, natural depth of field, tonal minimalism with warmth, editorial magazine printing quality",
            cameraLine: "face-on elevation view, sensor plane exactly parallel to the wall, no perspective distortion, no vanishing point, no lens tilt, straight architectural framing",
            
            negatives: [
                "people", "text", "watermarks",
                "artwork on the wall behind the sofa",
                "modern electronics or screens",
                "clutter",
                "any object density that fills more than 15 percent of a shelf",
                "extra columns beyond the four specified",
                "extra shelves beyond the four per bay specified",
                "additional windows",
                "curved or arched openings",
                "perspective distortion",
                "any color outside the warm neutral family",
                "multiple accent colors",
                "pattern of any kind",
                "glossy finishes",
                "boho macramé or fringe"
            ],
            
            modelName: "gpt_image_2",
            aspectRatio: "16:9",
            
            createdAt: now,
            updatedAt: now,
            
            artDirection: "A studio room reduced to its warm essentials. One continuous tonal gesture in cream and pale oak. Not empty — quiet, with intent. The kind of room where you notice the light before you notice the objects.",
            
            lensAndCamera: "shot on a 50mm equivalent, sensor plane exactly parallel to the wall, no tilt, no shift, aperture around f/5.6, uniform sharpness, still quiet composition",
            
            timeOfDayAndLight: "even morning light, warm neutral around 4600K, diffuse fill, no direct sun, very soft shadows, pale oak floor and cream plaster reading as one continuous tonal field",
            
            moodDescriptors: "still, warm, restrained, architectural, patient, monastic-but-comfortable",
            
            materialSpecificity: "pale oak with a matte hand-oiled finish and quiet grain; matte black iron with a soft brushed hand-forged texture; hand-troweled plaster with the faintest cloud-like variation and no perfect uniformity; linen upholstery in a clean flat weave, minimal slub; stoneware ceramics with an unglazed matte cream body",
            
            stylingProps: "on the shelves: one matte cream stoneware vessel per shelf, one horizontal book on one shelf, a small piece of driftwood on another, one shelf entirely empty. On the coffee table: one matte cream stoneware bowl, nothing else. On the sofa: one folded warm cream linen throw over the arm, two pillows only, both in warm neutrals within one shade of each other. One large olive tree in a matte stoneware planter on the floor beside the side table on one side only.",
            
            finishNotes: "curtain panels hanging clean and vertical with minimal pooling; the olive tree's largest leaf turned three degrees toward the window; one shelf left deliberately empty; the throw folded once with a hand-flattened crease; the rug corner set precisely square; nothing on the coffee table but a single bowl",
            
            designerSignatureLine: "Render as if photographed for a monograph of a working architect's own home — nothing extra, everything considered, warm enough to live in. Signed: a designer who believes restraint is the ultimate luxury."
        )
    }
    
    // MARK: v2 — Gentleman's Library London Club (full monty)
    //
    // The Ralph Lauren Home / Robert Kime / Soane Britain world: deep
    // bookish, cordovan leather chesterfield, oxblood and bottle-green
    // returns, mahogany and antique brass, patinated library lamps with
    // emerald glass shades, walls stacked with leather-bound books. Reads
    // like a Mayfair club at dusk translated into the same wall structure.
    static var gentlemansLibraryLondonClub: PhotorealPreset {
        let now = Date(timeIntervalSince1970: 1_785_000_000)
        return PhotorealPreset(
            id: UUID(uuidString: "B0F0B0F0-0007-0007-0007-000000000007")!,
            name: "Gentleman's Library — London Club",
            version: 1,
            notes: "Full-monty preset. Ralph Lauren Home / Robert Kime / Soane Britain sensibility. Cordovan chesterfield, oxblood and green, mahogany and brass. Locked. Duplicate before editing.",
            styleFamily: .gentlemansLibrary,
            
            aestheticLine: "gentleman's library in the London club tradition, cordovan leather chesterfield, deep oxblood and bottle-green accents, mahogany, patinated brass",
            atmosphereLine: "late-afternoon light muted through heavy curtains, warm lamp glow, deeply quiet, uncluttered but bookish, no people, a room that smells faintly of leather and paper",
            
            wallPlasterHex: "#E7DFCB",           // warm parchment plaster, reads as aged cream against the dark accents
            wallReturnAccentHex: "#2F3B2A",      // deep bottle green return
            casingWhiteHex: "#EDE6D2",           // parchment casing
            beamWoodHex: "#3C2417",              // dark mahogany beam
            floorWoodHex: "#5A3820",             // aged mahogany plank floor
            upholsteryHex: "#5A2A20",            // cordovan leather
            pillowAccentHex: "#3F1F1A",          // deeper oxblood accent
            metalHardwareHex: "#7A5A2A",         // patinated antique brass
            rattanHex: "#3C2417",                // reused for dark wood accents
            
            upholsteryMaterial: "cordovan leather chesterfield sofa, deep oxblood with rich patina, hand-tufted diamond pattern on the back and arms, softly worn on the seat cushions, rolled arms, low profile, the leather visibly softened by decades of use",
            curtainMaterial: "heavy bottle-green velvet floor-length curtain panels, gathered on antique brass rings on a patinated brass rod with acorn finials, pooling deliberately on the floor",
            blindMaterial: "none — heavy velvet curtains only",
            floorMaterial: "aged mahogany or dark walnut plank floor, wide boards, hand-oiled matte finish, visible patina, softened board edges, walked-on for a century",
            wallMaterial: "warm parchment plaster with subtle tonal variation, matte finish, reads as an aged cream against the darker accents",
            shelfMaterial: "solid mahogany or dark walnut boards, deep honey-to-brown tone with visible grain and softened edges, packed with books to full working density",
            coffeeTableMaterial: "low mahogany coffee table with turned legs and a lightly distressed top, brass ferrule feet, matte hand-rubbed finish",
            sideTableMaterial: "antique-inspired mahogany drum tables or brass pedestal side tables with a rich patina",
            lampShadeMaterial: "patinated antique brass library lamps with emerald-green cased-glass shades, warm interior glow spilling over books and leather",
            
            shelfStaging: "shelves packed with restraint and character — leather-bound books in mixed cordovan, oxblood, forest-green, and warm tan spines, mostly standing upright with a few horizontal stacks used as risers for small objects. One or two small oil paintings of a landscape or a hound propped against the shelf back. A pair of antique brass candlesticks unlit. A small terrestrial globe on one shelf. A hand-thrown ceramic vessel or two in cream and matte glaze. A leather-bound reading portfolio lying flat on one shelf. Objects touch the books deliberately, not clutter, quiet composition, warm brown-and-green with parchment relief.",
            plantStaging: "one large sculptural fern or aspidistra in a matte brass planter on one side of the room; a single small trailing ivy softening one shelf corner. Muted forest green, natural not glossy.",
            artStaging: "no large artwork on the wall behind the sofa, only the window and its heavy velvet panels. Small propped landscapes and portraits live on the shelves.",
            
            qualityFlags: "photorealistic architectural rendering, 4k detail, natural depth of field, matte tonal richness with saturated warm depth, editorial magazine printing quality with warm English lamp-light, Ralph Lauren Home / Robert Kime / Soane Britain sensibility",
            cameraLine: "face-on elevation view, sensor plane exactly parallel to the wall, no perspective distortion, no vanishing point, no lens tilt, straight architectural framing with the wall filling the frame",
            
            negatives: [
                "people", "text", "watermarks",
                "artwork on the wall behind the sofa",
                "modern electronics or screens",
                "clutter",
                "extra columns beyond the four specified",
                "extra shelves beyond the four per bay specified",
                "additional windows",
                "curved or arched openings",
                "perspective distortion",
                "pale walls",
                "boho styling",
                "sage green",
                "cream linen sofa",
                "rattan",
                "woven baskets",
                "honey oak",
                "American farmhouse styling",
                "shiplap",
                "chrome or polished chrome hardware",
                "glossy plastic finishes",
                "neon or saturated primary colors"
            ],
            
            modelName: "gpt_image_2",
            aspectRatio: "16:9",
            
            createdAt: now,
            updatedAt: now,
            
            artDirection: "A private London club library at four o'clock in the afternoon. Cordovan leather, mahogany, brass with a proper patina, shelves stacked with books that have been read. Bottle-green velvet at the window, oxblood at the seat, warm lamp glow spilling over parchment plaster. The kind of room where a novel is halfway finished and a decanter is not far away.",
            
            lensAndCamera: "shot on a 50mm equivalent, sensor plane exactly parallel to the wall, no tilt, no shift, aperture around f/5.6, gentle natural falloff on the coffee table, rich warm tonal roll-off in the shadows",
            
            timeOfDayAndLight: "late-afternoon light muted through heavy velvet curtains, cool exterior daylight around 5200K softened and warmed to about 3200K by the emerald-shaded library lamps, no direct sun, warm pools of lamp light on the leather sofa and the coffee table books, deeper shadows in the return zones and under the beam header",
            
            moodDescriptors: "bookish, patinated, warm, aristocratic, unhurried, masculine but not heavy, English club, quietly literary",
            
            materialSpecificity: "cordovan leather with a visible break-in on the seat cushion, faint scratches on the arm rolls, deep tonal richness with subtle color variation across panels; mahogany with a hand-rubbed oil finish, dense straight grain with warm reddish undertones; antique brass with a warm patina, no polish, showing the fingerprints of time; bottle-green velvet with a soft nap that catches the light along the drape lines; leather-bound books with visible wear on the spines, gilt titling faded to a soft glow; parchment plaster with subtle cloud-like tonal variation, the palest warm cream against the darker accents",
            
            stylingProps: "on the shelves: books packed working-dense, mostly upright with a few horizontal stacks as risers, one small propped landscape oil, one propped small portrait, a pair of unlit brass candlesticks, one small terrestrial globe, a leather-bound reading portfolio lying flat, one hand-thrown cream matte ceramic vessel, a trailing ivy softening one corner. On the coffee table: a stack of three cloth-bound and leather-bound books with a small brass reading glass on top, a matte cream stoneware bowl, a small brass bell. On the sofa: one folded tartan wool throw draped over one arm, two pillows in deeper oxblood and warm parchment linen, both softly rumpled. A single sculptural fern or aspidistra in a matte brass planter on one side of the room beside the side table.",
            
            finishNotes: "heavy velvet curtain panels pooling on the floor with a deliberate gathered fall; the chesterfield's seat cushions softly indented as if just vacated; one book on the coffee table sitting a half inch off-parallel with the reading glass resting on its cover; the tartan throw folded once and slipping slightly off the arm; the emerald library lampshades casting warm pools of light onto the leather and the books; a faint softness of pipe-smoke light in the air suggesting an old room with a long memory",
            
            designerSignatureLine: "Render as if photographed for The World of Interiors or Architectural Digest UK — a private London library caught at four o'clock, warm lamps against a cool afternoon. Signed: a designer who believes a room without books cannot be trusted."
        )
    }
    
    // Bundled read-only presets that ship with the app. Users can
    // duplicate any of these to make an editable copy. Ordered so
    // Boho Signature (the tested baseline) is first, followed by the
    // other full-monty designer presets, and the pragmatic Boho v1
    // remains available as a dial-back fallback.
    static var bundled: [PhotorealPreset] {
        [
            bohoMorningEditorialSignature,
            belgianTransitionalCountryHouse,
            japandiQuietMorning,
            parisianClassicMorningSalon,
            warmMinimalStudio,
            gentlemansLibraryLondonClub,
            bohoMorningEditorial
        ]
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
