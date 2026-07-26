import Foundation

// MARK: - Style DNA
//
// A StyleDNA is a compact, structured description of an interior style.
// The structural blueprint (locked wall + window + shelves + beam) is
// merged with a StyleDNA to produce the final render prompt.
//
// Structure is never in the DNA. DNA only holds the aesthetic layer:
// palette, materials, lighting, hero pieces, textiles, atmosphere,
// negative constraints.
//
// DNA can be authored three ways:
//   1. Pick a curated preset from StyleDNALibrary.
//   2. Type free text ("cozy scandi cabin at dusk") and call
//      StyleDNA.fromFreeText(...) — a rules-based normalizer expands
//      shorthand into a fully-populated DNA object.
//   3. Copy any preset and dial individual fields in a form.
//
// The final render prompt is always assembled by:
//     StyleDNAPromptComposer.buildFullPrompt(
//         structural: <locked structural brief>,
//         styleDNA: <chosen DNA>
//     )

struct StyleDNA: Codable, Hashable, Identifiable {
    var id: UUID = UUID()
    
    /// Short, human-readable label. Used in the picker and file names.
    var name: String
    
    /// One-line elevator pitch. Optional flavor, not rendered into the
    /// prompt directly, but shown in the UI.
    var tagline: String
    
    /// The overarching style family this DNA belongs to.
    var family: String
    
    /// 3-6 sentences that capture the mood. Rendered near the top of
    /// the style block in the composed prompt.
    var moodStatement: String
    
    /// Palette: 3-6 named colors, plus wood tone and metal finish.
    var palette: Palette
    
    /// Materials — the surfaces and textiles.
    var materials: Materials
    
    /// Lighting recipe — daylight quality and any interior fixtures.
    var lighting: Lighting
    
    /// Hero pieces — the 2-4 statement furnishings that anchor the room.
    /// These populate the negative space in front of the wall.
    var heroPieces: [String]
    
    /// Window dressing — what covers or frames the 22/52/22 window.
    /// This is the ONE style choice that touches the locked structure,
    /// so it's called out separately.
    var windowDressing: String
    
    /// Textiles — throws, rugs, cushions, drapes.
    var textiles: [String]
    
    /// Small objects — books, ceramics, brass, flora — that go on shelves.
    var shelfStyling: [String]
    
    /// Negative constraints — what to explicitly avoid. These become
    /// "do not" bullets in the composed prompt.
    var avoid: [String]
    
    /// Camera and framing note. Usually the same for every DNA (face-on
    /// elevation, seated eye level), but overridable.
    var cameraNote: String
    
    /// Version tag, bumped by hand when the DNA meaningfully changes.
    var version: String
    
    struct Palette: Codable, Hashable {
        var primary: String       // dominant wall / background color
        var secondary: String     // main upholstery / textile color
        var accent: String        // hero color moment
        var neutral: String       // grounding neutral
        var woodTone: String      // "warm oak", "walnut", "pale ash"
        var metalFinish: String   // "aged brass", "matte black", "polished nickel"
    }
    
    struct Materials: Codable, Hashable {
        var walls: String         // "cream limewash", "warm plaster"
        var floor: String         // "wide-plank white oak", "sisal rug over stone"
        var upholstery: String    // "linen", "boucle", "velvet"
        var trim: String          // "matte white", "muted mushroom"
        var accents: [String]     // "hand-thrown ceramics", "vintage brass"
    }
    
    struct Lighting: Codable, Hashable {
        var timeOfDay: String     // "late morning", "golden hour", "overcast noon"
        var quality: String       // "bright and diffused", "warm and low"
        var fixtures: [String]    // "matte-brass floor lamp", "paper pendant"
    }
}

// MARK: - Curated library

enum StyleDNALibrary {
    
    static let bohoMorningEditorial = StyleDNA(
        name: "Boho Morning Editorial",
        tagline: "Warm, layered, plant-forward, sunlit",
        family: "Boho",
        moodStatement: "A relaxed, sun-warmed sitting room styled for a slow morning. Layered textures, natural fibers, and easy asymmetry. Editorial but lived-in — a Kinfolk shoot on a Tuesday.",
        palette: .init(
            primary: "warm ivory",
            secondary: "terracotta",
            accent: "moss green",
            neutral: "sand",
            woodTone: "honey oak",
            metalFinish: "aged brass"
        ),
        materials: .init(
            walls: "cream limewash",
            floor: "wide-plank oak with a large flatweave kilim",
            upholstery: "cream linen and natural boucle",
            trim: "matte cream",
            accents: ["hand-thrown terracotta pots", "aged brass hardware", "rattan"]
        ),
        lighting: .init(
            timeOfDay: "late morning",
            quality: "bright, diffused, warm",
            fixtures: ["aged-brass floor lamp with linen shade"]
        ),
        heroPieces: [
            "low-slung cream linen sofa",
            "round travertine coffee table",
            "large fiddle-leaf fig in a terracotta planter"
        ],
        windowDressing: "unlined natural linen curtains on an aged-brass rod, puddled slightly on the floor, drawn to the sides",
        textiles: [
            "moroccan wool throw in natural cream",
            "cushions in mudcloth and vintage kilim",
            "flatweave rug in oatmeal and rust"
        ],
        shelfStyling: [
            "stacked linen-bound books",
            "hand-thrown ceramics in cream and terracotta",
            "trailing pothos and small potted olive",
            "vintage brass candlesticks"
        ],
        avoid: [
            "glossy or reflective surfaces",
            "modern black hardware",
            "cool blue tones",
            "matched sets"
        ],
        cameraNote: "face-on elevation, camera perpendicular to the wall, seated eye level, no perspective distortion",
        version: "boho-morning-1.1.0"
    )
    
    static let belgianTransitional = StyleDNA(
        name: "Belgian Transitional Country House",
        tagline: "Muted, tactile, weathered elegance",
        family: "Belgian Transitional",
        moodStatement: "A restrained country house drawing room in the Vincent Van Duysen or Axel Vervoordt tradition. Muted, weathered, honest materials. Quiet luxury with visible age.",
        palette: .init(
            primary: "warm chalk",
            secondary: "mushroom",
            accent: "faded ochre",
            neutral: "stone grey",
            woodTone: "reclaimed oak",
            metalFinish: "blackened iron"
        ),
        materials: .init(
            walls: "warm chalk-white plaster with visible trowel texture",
            floor: "wide reclaimed oak with a large jute rug",
            upholstery: "heavy natural linen and vintage grain-sack fabric",
            trim: "muted chalk",
            accents: ["blackened iron", "unglazed ceramics", "weathered leather"]
        ),
        lighting: .init(
            timeOfDay: "late morning",
            quality: "cool, soft, north-facing daylight",
            fixtures: ["blackened-iron floor lamp with linen shade"]
        ),
        heroPieces: [
            "deep linen slipcovered sofa in warm chalk",
            "reclaimed oak coffee table with visible grain",
            "large earthenware jar on a low plinth"
        ],
        windowDressing: "heavy natural linen curtains on a blackened-iron rod, hanging straight to just above the floor",
        textiles: [
            "grain-sack cushions with faded stripes",
            "chunky wool throw in oatmeal",
            "jute rug"
        ],
        shelfStyling: [
            "leather-bound books in muted tones",
            "unglazed stoneware and earthenware vessels",
            "dried grasses and single olive branch",
            "small blackened-iron sculpture"
        ],
        avoid: [
            "polished or high-gloss finishes",
            "bright saturated colors",
            "matched furniture sets",
            "new-looking or plastic-feeling objects"
        ],
        cameraNote: "face-on elevation, camera perpendicular to the wall, seated eye level, no perspective distortion",
        version: "belgian-1.1.0"
    )
    
    static let japandiQuietMorning = StyleDNA(
        name: "Japandi Quiet Morning",
        tagline: "Pale, restrained, precise, calm",
        family: "Japandi",
        moodStatement: "A quiet morning in a light-filled Tokyo apartment. Japanese restraint married to Scandinavian warmth. Minimal, precise, warm. Nothing extra.",
        palette: .init(
            primary: "paper white",
            secondary: "pale oat",
            accent: "warm charcoal",
            neutral: "soft grey",
            woodTone: "pale ash and white oak",
            metalFinish: "matte black"
        ),
        materials: .init(
            walls: "smooth pale plaster",
            floor: "pale white oak with a fine wool rug",
            upholstery: "natural linen and pale wool boucle",
            trim: "warm white",
            accents: ["matte black iron", "hand-thrown pale ceramics", "paper"]
        ),
        lighting: .init(
            timeOfDay: "early morning",
            quality: "soft, cool, even",
            fixtures: ["paper pendant lantern", "slim matte-black floor lamp"]
        ),
        heroPieces: [
            "low natural linen sofa with squared arms",
            "pale oak plinth-style coffee table",
            "single tall branch in a hand-thrown vessel"
        ],
        windowDressing: "sheer white linen roman shades pulled fully up, no curtains",
        textiles: [
            "wool throw in undyed cream",
            "one square cushion in charcoal linen",
            "flatweave wool rug in soft oat"
        ],
        shelfStyling: [
            "three or four hand-thrown ceramic vessels in cream and charcoal",
            "one stack of pale linen-bound books",
            "single small dried branch",
            "negative space is intentional and generous"
        ],
        avoid: [
            "clutter or heavy accessorizing",
            "warm oranges or reds",
            "shiny brass",
            "ornate patterns"
        ],
        cameraNote: "face-on elevation, camera perpendicular to the wall, seated eye level, no perspective distortion",
        version: "japandi-1.1.0"
    )
    
    static let parisianClassic = StyleDNA(
        name: "Parisian Classic Morning Salon",
        tagline: "Cream boiserie, brass, quiet luxury",
        family: "Parisian Classic",
        moodStatement: "A hushed morning in a Haussmann-era salon. Cream tones, restrained boiserie, brass and marble touchpoints. Not ornate — quietly luxurious. A Vogue Living feature at 10am.",
        palette: .init(
            primary: "cream",
            secondary: "dove grey",
            accent: "aged brass",
            neutral: "warm white",
            woodTone: "pale bleached oak",
            metalFinish: "aged brass"
        ),
        materials: .init(
            walls: "cream limewash",
            floor: "pale bleached herringbone oak",
            upholstery: "cream velvet and pale dove linen",
            trim: "warm cream",
            accents: ["aged brass", "cream marble", "silk"]
        ),
        lighting: .init(
            timeOfDay: "late morning",
            quality: "bright, warm, north-facing",
            fixtures: ["aged-brass floor lamp with cream silk shade", "brass sconces"]
        ),
        heroPieces: [
            "curved cream velvet sofa",
            "small round cream-marble coffee table on a brass base",
            "single tall vase of pale garden roses"
        ],
        windowDressing: "floor-length cream silk curtains on an aged-brass rod, hanging in soft columns",
        textiles: [
            "silk throw in oyster",
            "cushions in cream velvet and dove linen",
            "small silk rug in cream and pale grey"
        ],
        shelfStyling: [
            "cream leather-bound books",
            "small brass candlesticks",
            "cream ceramics and one small brass framed drawing",
            "single stem of white garden roses"
        ],
        avoid: [
            "modern black metals",
            "rustic or weathered finishes",
            "bright saturated colors",
            "boho or bohemian layering"
        ],
        cameraNote: "face-on elevation, camera perpendicular to the wall, seated eye level, no perspective distortion",
        version: "parisian-1.1.0"
    )
    
    static let warmMinimal = StyleDNA(
        name: "Warm Minimal Studio",
        tagline: "Editorial, quiet, warm, essential",
        family: "Warm Minimal",
        moodStatement: "A minimalist Los Angeles studio in the tradition of Vincent Van Duysen and Rose Uniacke. Warm, quiet, essential. Every object earns its place. Nothing decorative for its own sake.",
        palette: .init(
            primary: "warm off-white",
            secondary: "mushroom",
            accent: "soft terracotta",
            neutral: "warm sand",
            woodTone: "smoked white oak",
            metalFinish: "brushed brass"
        ),
        materials: .init(
            walls: "warm plaster",
            floor: "smoked white oak with a large flatweave rug",
            upholstery: "heavy natural linen",
            trim: "matte off-white",
            accents: ["brushed brass", "warm travertine", "hand-thrown ceramics"]
        ),
        lighting: .init(
            timeOfDay: "late morning",
            quality: "warm, diffused",
            fixtures: ["brushed-brass floor lamp with linen drum shade"]
        ),
        heroPieces: [
            "low linen sofa in warm off-white",
            "large travertine coffee table",
            "single earthenware vessel on a low plinth"
        ],
        windowDressing: "unlined linen curtains on a brushed-brass rod, hanging straight to the floor",
        textiles: [
            "chunky wool throw in oat",
            "two linen cushions in oat and mushroom",
            "large flatweave rug in warm sand"
        ],
        shelfStyling: [
            "small stack of art books",
            "two or three hand-thrown ceramic vessels",
            "single branch in a tall vase",
            "generous negative space"
        ],
        avoid: [
            "clutter",
            "cool grey tones",
            "bright saturated colors",
            "matched sets or catalog-perfect styling"
        ],
        cameraNote: "face-on elevation, camera perpendicular to the wall, seated eye level, no perspective distortion",
        version: "warm-minimal-1.1.0"
    )
    
    static let gentlemansLibrary = StyleDNA(
        name: "Gentleman's Library London Club",
        tagline: "Ink blue velvet, brass, ferns, chesterfield",
        family: "Gentleman's Library",
        moodStatement: "A well-used gentleman's library in a Bloomsbury townhouse. Deep ink-blue velvet, tartan, aged leather, ferns, and brass. Bright morning light so every detail reads — not a dim club murk.",
        palette: .init(
            primary: "warm ivory walls",
            secondary: "ink navy blue",
            accent: "aged brass",
            neutral: "walnut",
            woodTone: "walnut",
            metalFinish: "aged brass"
        ),
        materials: .init(
            walls: "warm ivory limewash",
            floor: "walnut with a large worn oriental rug",
            upholstery: "deep ink-blue velvet and aged cognac leather",
            trim: "warm cream",
            accents: ["aged brass", "walnut", "cognac leather"]
        ),
        lighting: .init(
            timeOfDay: "bright late morning",
            quality: "bright, warm, diffused — room legible in detail, not dim",
            fixtures: ["aged-brass floor lamp with pleated linen shade", "small brass desk lamp"]
        ),
        heroPieces: [
            "deep ink-blue velvet chesterfield sofa with tufted back",
            "round walnut pedestal coffee table",
            "large Boston fern in an aged-brass planter",
            "cognac leather club chair"
        ],
        windowDressing: "cream linen roman shade partially lowered from the top, with ink-blue velvet drapes on an aged-brass rod hanging in soft columns to the floor",
        textiles: [
            "tartan wool throw in navy and cream draped over the chesterfield",
            "cushions in cognac leather and ink velvet",
            "worn oriental rug in muted red and navy"
        ],
        shelfStyling: [
            "leather-bound books in cognac, oxblood, and forest green",
            "small brass candlesticks and a brass magnifier",
            "two or three ferns and trailing ivy",
            "small oil painting on a brass easel"
        ],
        avoid: [
            "modern minimalist styling",
            "bright saturated colors outside the palette",
            "boho or rustic layering",
            "dim or murky lighting"
        ],
        cameraNote: "face-on elevation, camera perpendicular to the wall, seated eye level, no perspective distortion",
        version: "gentlemans-library-1.1.0"
    )
    
    /// All curated presets, in display order.
    static let all: [StyleDNA] = [
        bohoMorningEditorial,
        belgianTransitional,
        japandiQuietMorning,
        parisianClassic,
        warmMinimal,
        gentlemansLibrary
    ]
    
    static func byName(_ name: String) -> StyleDNA? {
        return all.first { $0.name.lowercased() == name.lowercased() }
    }
}

// MARK: - Free-text style expansion
//
// Users can type any style ("cozy scandi cabin at dusk",
// "hollywood regency", "coastal cottage") and get a fully-populated
// StyleDNA back. The expansion is rules-based, deterministic, and
// intentionally opinionated so the output prompt is always complete.
//
// Strategy:
//   1. Match the free text against known family keywords to seed a base DNA.
//   2. Extract palette hints ("blue", "warm", "dusk"), material hints
//      ("velvet", "linen", "rattan"), and lighting hints ("dusk",
//      "morning", "golden hour") from the free text.
//   3. Overlay those hints on the base DNA.
//   4. Rewrite the mood statement to include the user's phrasing.

extension StyleDNA {
    
    /// Convert a free-text style description into a fully-populated
    /// StyleDNA. Never returns nil — worst case, returns a generic
    /// warm-minimal base with the user's text as the mood statement.
    static func fromFreeText(_ text: String) -> StyleDNA {
        let lower = text.lowercased()
        var dna = pickBase(for: lower)
        
        // Override name and mood so the user's phrasing shows up
        dna.id = UUID()
        dna.name = titleCase(text)
        dna.tagline = "Custom style from free text"
        dna.moodStatement = "A styled interior described as: \"\(text)\". " + dna.moodStatement
        dna.version = "custom-freetext-1.0.0"
        
        // Palette hints
        applyPaletteHints(from: lower, to: &dna)
        // Material hints
        applyMaterialHints(from: lower, to: &dna)
        // Lighting hints
        applyLightingHints(from: lower, to: &dna)
        
        return dna
    }
    
    private static func pickBase(for lower: String) -> StyleDNA {
        // Ordered from most specific to most generic.
        if lower.contains("gentleman") || lower.contains("library") || lower.contains("club") || lower.contains("chesterfield") {
            return StyleDNALibrary.gentlemansLibrary
        }
        if lower.contains("japandi") || lower.contains("japanese") || lower.contains("wabi") {
            return StyleDNALibrary.japandiQuietMorning
        }
        if lower.contains("boho") || lower.contains("bohemian") || lower.contains("moroccan") || lower.contains("kilim") {
            return StyleDNALibrary.bohoMorningEditorial
        }
        if lower.contains("belgian") || lower.contains("van duysen") || lower.contains("vervoordt") || lower.contains("country house") {
            return StyleDNALibrary.belgianTransitional
        }
        if lower.contains("parisian") || lower.contains("paris") || lower.contains("haussmann") || lower.contains("salon") {
            return StyleDNALibrary.parisianClassic
        }
        if lower.contains("minimal") || lower.contains("uniacke") || lower.contains("editorial") {
            return StyleDNALibrary.warmMinimal
        }
        if lower.contains("scandi") || lower.contains("scandinavian") || lower.contains("nordic") {
            return StyleDNALibrary.japandiQuietMorning // closest starting point
        }
        if lower.contains("coastal") || lower.contains("hamptons") || lower.contains("cape cod") {
            var d = StyleDNALibrary.warmMinimal
            d.palette.primary = "chalk white"
            d.palette.secondary = "soft sky blue"
            d.palette.accent = "weathered rope"
            return d
        }
        if lower.contains("mid-century") || lower.contains("midcentury") || lower.contains("eames") {
            var d = StyleDNALibrary.warmMinimal
            d.palette.primary = "warm cream"
            d.palette.secondary = "walnut"
            d.palette.accent = "burnt orange"
            d.materials.upholstery = "walnut wood frames with tweed and leather upholstery"
            return d
        }
        // Fallback
        return StyleDNALibrary.warmMinimal
    }
    
    private static func applyPaletteHints(from lower: String, to dna: inout StyleDNA) {
        // Warm / cool bias
        if lower.contains("warm") || lower.contains("sunlit") || lower.contains("golden") {
            dna.lighting.quality = "warm, diffused, golden"
        }
        if lower.contains("cool") || lower.contains("overcast") || lower.contains("north") {
            dna.lighting.quality = "cool, soft, north-facing"
        }
        
        // Named color pulls — leave the rest of the palette alone but
        // move the accent toward the mentioned color.
        let colorMap: [(String, String)] = [
            ("navy", "ink navy blue"),
            ("blue", "soft blue"),
            ("green", "moss green"),
            ("olive", "olive green"),
            ("sage", "sage"),
            ("terracotta", "terracotta"),
            ("rust", "burnt rust"),
            ("ochre", "faded ochre"),
            ("mustard", "warm mustard"),
            ("blush", "muted blush"),
            ("pink", "muted rose"),
            ("black", "warm charcoal"),
            ("cream", "warm cream"),
            ("bone", "bone white"),
            ("chocolate", "warm chocolate brown"),
            ("cognac", "cognac leather")
        ]
        for (needle, replacement) in colorMap {
            if lower.contains(needle) {
                dna.palette.accent = replacement
                break
            }
        }
    }
    
    private static func applyMaterialHints(from lower: String, to dna: inout StyleDNA) {
        let materialMap: [(String, String)] = [
            ("velvet", "velvet"),
            ("linen", "heavy natural linen"),
            ("boucle", "natural boucle"),
            ("leather", "aged leather"),
            ("rattan", "rattan and cane"),
            ("wicker", "wicker"),
            ("tweed", "wool tweed")
        ]
        var found: [String] = []
        for (needle, m) in materialMap where lower.contains(needle) {
            found.append(m)
        }
        if !found.isEmpty {
            dna.materials.upholstery = found.joined(separator: " and ")
        }
        
        let woodMap: [(String, String)] = [
            ("walnut", "walnut"),
            ("oak", "warm white oak"),
            ("ash", "pale ash"),
            ("pine", "knotty pine"),
            ("teak", "teak"),
            ("cherry", "cherry")
        ]
        for (needle, w) in woodMap where lower.contains(needle) {
            dna.palette.woodTone = w
            break
        }
        
        let metalMap: [(String, String)] = [
            ("brass", "aged brass"),
            ("gold", "brushed gold"),
            ("nickel", "polished nickel"),
            ("chrome", "polished chrome"),
            ("black metal", "matte black iron"),
            ("blackened", "blackened iron"),
            ("copper", "aged copper")
        ]
        for (needle, m) in metalMap where lower.contains(needle) {
            dna.palette.metalFinish = m
            break
        }
    }
    
    private static func applyLightingHints(from lower: String, to dna: inout StyleDNA) {
        if lower.contains("dusk") || lower.contains("evening") || lower.contains("candle") {
            dna.lighting.timeOfDay = "late afternoon into dusk"
            dna.lighting.quality = "warm, low, glowing"
        } else if lower.contains("golden hour") || lower.contains("sunset") {
            dna.lighting.timeOfDay = "golden hour"
            dna.lighting.quality = "warm, low, directional"
        } else if lower.contains("morning") || lower.contains("dawn") {
            dna.lighting.timeOfDay = "late morning"
            dna.lighting.quality = "bright, diffused, warm"
        } else if lower.contains("overcast") || lower.contains("rainy") {
            dna.lighting.timeOfDay = "overcast midday"
            dna.lighting.quality = "cool, soft, even"
        } else if lower.contains("night") {
            dna.lighting.timeOfDay = "evening"
            dna.lighting.quality = "warm, low, from lamps only"
        }
    }
    
    private static func titleCase(_ s: String) -> String {
        // Simple title-case for the DNA name.
        return s.split(separator: " ")
            .map { $0.prefix(1).uppercased() + $0.dropFirst().lowercased() }
            .joined(separator: " ")
    }
}

// MARK: - Prompt composition
//
// The composer merges the structural brief (from LockedWall +
// WindowLockLibrary) with a StyleDNA and emits a single prompt string
// ready to send to any image model — the app's internal renderer OR
// pasted into ChatGPT / Claude / Midjourney.

enum StyleDNAPromptComposer {
    
    /// Structural brief for Wall 1 built from the code-locked geometry.
    /// This is the only place in the prompt that mentions dimensions
    /// or panel splits. StyleDNA cannot override any of this.
    static func wall1StructuralBrief() -> String {
        let lock = WindowLockLibrary.wall1Z3B
        let panels = lock.panelSplit.map { String(Int($0)) }.joined(separator: " / ")
        return """
Use the attached image as a strict structural reference. Columns, shelf bays, window opening, window frame, panel split, and casing must match the reference exactly. Do not add or remove any structural element. Do not rearrange or resize columns. Do not change the window's \(panels) panel split. Do not add curtains or shelves that were not in the reference unless the style block below explicitly asks for them.

Wall 1 is a family-room accent wall, 246 inches wide by 96 inches tall, photographed face-on in natural light. The wall carries, left to right:

- An 8in structural column (C1)
- A 43in open shelf bay with exactly five horizontal shelf boards, each 9.25in deep, attached directly between the flanking columns. No bookcase box. No side panels. No inset built-in.
- An 8in structural column (C2)
- A 12.75in flat plaster return zone
- A 5in white casing leg
- A \(Int(lock.width))in wide by \(Int(lock.height))in tall picture window with three panels split \(panels)in. Sill at 20in above floor, head at 80in above floor. Side lights carry a 2-column by 3-row muntin grid. Center panel is clear glass, no grid. Frame, mullions, and \(Int(lock.casingWidth))in casing all around are white.
- A 5in white casing leg
- A 12.75in flat plaster return zone
- An 8in structural column (C3)
- A 39.5in open shelf bay with exactly five horizontal shelf boards, same construction as the left bay
- An 8in structural column (C4)

A structural beam zone runs the full width of the wall across the top 8in. It is a flat continuous band, not broken by anything.
"""
    }
    
    /// Compose the style block from a StyleDNA. This is the "aesthetic"
    /// half of the prompt and never touches structure.
    static func styleBlock(from dna: StyleDNA) -> String {
        var parts: [String] = []
        parts.append("STYLE: \(dna.name) — \(dna.family)")
        parts.append("")
        parts.append(dna.moodStatement)
        parts.append("")
        parts.append("Palette:")
        parts.append("- primary: \(dna.palette.primary)")
        parts.append("- secondary: \(dna.palette.secondary)")
        parts.append("- accent: \(dna.palette.accent)")
        parts.append("- neutral: \(dna.palette.neutral)")
        parts.append("- wood tone: \(dna.palette.woodTone)")
        parts.append("- metal finish: \(dna.palette.metalFinish)")
        parts.append("")
        parts.append("Materials:")
        parts.append("- walls: \(dna.materials.walls)")
        parts.append("- floor: \(dna.materials.floor)")
        parts.append("- upholstery: \(dna.materials.upholstery)")
        parts.append("- trim: \(dna.materials.trim)")
        if !dna.materials.accents.isEmpty {
            parts.append("- accent materials: \(dna.materials.accents.joined(separator: \", \"))")
        }
        parts.append("")
        parts.append("Lighting:")
        parts.append("- time of day: \(dna.lighting.timeOfDay)")
        parts.append("- quality: \(dna.lighting.quality)")
        if !dna.lighting.fixtures.isEmpty {
            parts.append("- fixtures: \(dna.lighting.fixtures.joined(separator: \", \"))")
        }
        parts.append("")
        parts.append("Hero pieces (place in front of the wall, do not overlap the columns or shelves):")
        for hero in dna.heroPieces {
            parts.append("- \(hero)")
        }
        parts.append("")
        parts.append("Window dressing (must respect the locked 22 / 52 / 22 opening):")
        parts.append("- \(dna.windowDressing)")
        parts.append("")
        if !dna.textiles.isEmpty {
            parts.append("Textiles:")
            for t in dna.textiles { parts.append("- \(t)") }
            parts.append("")
        }
        parts.append("Shelf styling (on the five shelves in each bay):")
        for s in dna.shelfStyling { parts.append("- \(s)") }
        parts.append("")
        parts.append("Avoid:")
        for a in dna.avoid { parts.append("- \(a)") }
        parts.append("")
        parts.append("Camera: \(dna.cameraNote).")
        return parts.joined(separator: "\n")
    }
    
    /// Full prompt: structural brief + style block + output constraints.
    /// This is what gets sent to the image model.
    static func buildFullPrompt(structural: String? = nil, styleDNA: StyleDNA) -> String {
        let structuralPart = structural ?? wall1StructuralBrief()
        let stylePart = styleBlock(from: styleDNA)
        let footer = """
Output: 16:9 landscape, high detail, photorealistic, no text, no watermarks.
"""
        return [structuralPart, "", stylePart, "", footer].joined(separator: "\n")
    }
}
