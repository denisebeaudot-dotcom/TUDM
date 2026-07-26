import Foundation

// MARK: - Style Catalog
//
// The Style Catalog is a dynamic, picker-driven library of style ingredients.
// A completed StyleDNA is composed from up to three picks plus optional
// free-text overrides (Option C):
//
//   1. Family      (required — sets palette + materials backbone)
//   2. Muse        (optional — tightens the family with a designer voice)
//   3. Mood Words  (optional — 1-3 atmosphere modifiers)
//   4. Free-text   (optional — overrides ANY field the picker set)
//
// The catalog is intentionally opinionated. Each Family, Muse, and Mood is
// hand-tuned to render well with the current image models — no dead
// entries, no filler.

// =====================================================================
// MARK: Style Family (18)
// =====================================================================

struct StyleFamily: Codable, Hashable, Identifiable {
    var id: String { name }
    var name: String
    var tagline: String
    var palette: StyleDNA.Palette
    var materials: StyleDNA.Materials
    var lighting: StyleDNA.Lighting
    var textiles: [String]
    var shelfStyling: [String]
    var windowDressing: String
    var avoid: [String]
}

enum StyleFamilyCatalog {

    static let all: [StyleFamily] = [
        boho, belgianTransitional, japandi, parisianClassic, warmMinimal,
        gentlemansLibrary, coastalNordic, moroccanRiad, californiaHacienda,
        englishCountryHouse, mediterraneanFarmhouse, mountainLodge,
        artDeco, italianRenaissanceRevival, industrialLoft,
        wabiSabi, shakerModern, tropicalModernist
    ]

    static func find(_ name: String) -> StyleFamily? {
        all.first { $0.name.caseInsensitiveCompare(name) == .orderedSame }
    }

    // ---- individual families ----------------------------------------

    static let boho = StyleFamily(
        name: "Boho Morning Editorial",
        tagline: "sun-drenched, layered, unhurried",
        palette: .init(primary: "off-white plaster", secondary: "sun-bleached terracotta",
                       accent: "sage green", neutral: "warm greige", woodTone: "warm oak", metalFinish: "aged brass"),
        materials: .init(walls: "hand-troweled plaster", floor: "wide oak planks",
                         upholstery: "natural linen and boucle", trim: "matte off-white", accents: ["rattan", "raw ceramic", "jute"]),
        lighting: .init(timeOfDay: "morning sun, warm and diffused", quality: "soft and diffused", fixtures: ["woven pendant", "brass candlestick lamps"]),
        textiles: ["natural linen throws", "berber-pattern rug", "raw cotton cushions"],
        shelfStyling: ["clay vessels", "trailing pothos", "worn hardcover books", "brass small objects"],
        windowDressing: "unlined natural linen panels, tied back with cotton rope",
        avoid: ["synthetic sheen", "matched sets", "cold gray tones"]
    )

    static let belgianTransitional = StyleFamily(
        name: "Belgian Transitional Country House",
        tagline: "muted, honest, elegantly restrained",
        palette: .init(primary: "warm putty white", secondary: "faded ink",
                       accent: "aged stone", neutral: "warm greige", woodTone: "dark walnut", metalFinish: "rubbed bronze"),
        materials: .init(walls: "limewash", floor: "reclaimed oak, matte",
                         upholstery: "washed Belgian linen", trim: "matte off-white", accents: ["patinated leather", "handmade ceramic", "bluestone"]),
        lighting: .init(timeOfDay: "north-facing overcast, silvery and even", quality: "soft and diffused", fixtures: ["black iron pendant", "linen shaded table lamps"]),
        textiles: ["stonewashed linen", "antique kilim", "rough wool throw"],
        shelfStyling: ["dark leather books", "unglazed pottery", "old brass instruments", "small oil paintings"],
        windowDressing: "heavy Belgian linen drapes, floor-puddled",
        avoid: ["shine", "trend colors", "anything catalog-fresh"]
    )

    static let japandi = StyleFamily(
        name: "Japandi Quiet Morning",
        tagline: "restrained, natural, deliberate",
        palette: .init(primary: "warm off-white", secondary: "ash",
                       accent: "moss green", neutral: "warm greige", woodTone: "pale oak", metalFinish: "blackened steel"),
        materials: .init(walls: "smooth clay plaster", floor: "pale oak, oiled",
                         upholstery: "natural cotton, undyed wool", trim: "matte off-white", accents: ["paper", "washi", "stoneware"]),
        lighting: .init(timeOfDay: "diffuse eastern morning light", quality: "soft and diffused", fixtures: ["paper lantern", "black slim floor lamp"]),
        textiles: ["undyed linen", "hand-loomed wool", "cotton noren"],
        shelfStyling: ["stoneware bowls", "single ikebana branch", "handmade paperback books", "cast iron teapot"],
        windowDressing: "shoji-style paper panel or unlined cotton scrim",
        avoid: ["glossy finishes", "warm-yellow lighting", "clutter"]
    )

    static let parisianClassic = StyleFamily(
        name: "Parisian Classic Morning Salon",
        tagline: "haussmann grandeur, weekday morning",
        palette: .init(primary: "ivory limewash", secondary: "faded rose",
                       accent: "gilt", neutral: "warm greige", woodTone: "walnut parquet", metalFinish: "polished brass"),
        materials: .init(walls: "limewash with cornice", floor: "herringbone walnut parquet",
                         upholstery: "silk-linen blend, worn velvet", trim: "matte off-white", accents: ["gilt", "marble", "toile"]),
        lighting: .init(timeOfDay: "tall-window Parisian morning", quality: "soft and diffused", fixtures: ["crystal wall sconces", "small crystal chandelier"]),
        textiles: ["silk cushions", "aubusson-style rug", "toile de jouy"],
        shelfStyling: ["leather-bound classics", "porcelain figurines", "small oil portraits", "gilt candlesticks"],
        windowDressing: "silk-lined drapes, tied with silk cord, sheer inner panel",
        avoid: ["farmhouse anything", "rustic wood", "black metal"]
    )

    static let warmMinimal = StyleFamily(
        name: "Warm Minimal",
        tagline: "quiet, warm, essential",
        palette: .init(primary: "warm white", secondary: "sand",
                       accent: "terracotta", neutral: "warm greige", woodTone: "honey oak", metalFinish: "matte brass"),
        materials: .init(walls: "smooth painted plaster", floor: "wide oak plank",
                         upholstery: "boucle, natural cotton", trim: "matte off-white", accents: ["travertine", "unglazed ceramic"]),
        lighting: .init(timeOfDay: "soft midday, warm-cast", quality: "soft and diffused", fixtures: ["single alabaster pendant", "paper shade floor lamp"]),
        textiles: ["thick woven throw", "flatweave rug in oatmeal"],
        shelfStyling: ["one large vessel per shelf", "editorial books flat-stacked", "small brass details"],
        windowDressing: "single sheer linen panel",
        avoid: ["knick-knacks", "cool tones", "high contrast"]
    )

    static let gentlemansLibrary = StyleFamily(
        name: "Gentleman's Library London Club",
        tagline: "leather, ink, decanters, weight",
        palette: .init(primary: "deep ink walls", secondary: "cognac leather",
                       accent: "burgundy", neutral: "warm greige", woodTone: "aged mahogany", metalFinish: "polished brass"),
        materials: .init(walls: "painted deep ink or bookcase-lined", floor: "dark parquet or Persian carpet",
                         upholstery: "aged leather, wool tweed", trim: "matte off-white", accents: ["mahogany", "brass", "green banker's glass"]),
        lighting: .init(timeOfDay: "shuttered afternoon, low and warm", quality: "soft and diffused", fixtures: ["green glass banker's lamp", "brass sconces", "reading lamp"]),
        textiles: ["Persian rug", "wool tartan throw", "leather chesterfield"],
        shelfStyling: ["leather-bound legal folios", "rolled maps", "brass astrolabe", "aged globe", "decanters"],
        windowDressing: "wooden shutters, half-closed, with heavy velvet drapes",
        avoid: ["anything bright", "modern electronics visible", "matched leather sets"]
    )

    static let coastalNordic = StyleFamily(
        name: "Coastal Nordic",
        tagline: "salt light, pale wood, quiet water",
        palette: .init(primary: "chalk white", secondary: "pale gray-blue",
                       accent: "driftwood", neutral: "warm greige", woodTone: "bleached pine", metalFinish: "pewter"),
        materials: .init(walls: "matte white paint", floor: "bleached pine, wide plank",
                         upholstery: "washed cotton, natural wool", trim: "matte off-white", accents: ["driftwood", "stoneware", "linen"]),
        lighting: .init(timeOfDay: "cool northern morning, bright and even", quality: "soft and diffused", fixtures: ["simple paper pendant", "iron candle sconces"]),
        textiles: ["chunky wool throws", "flatweave cotton rug", "linen slipcovers"],
        shelfStyling: ["white ceramic vessels", "driftwood pieces", "worn paperbacks", "sea glass"],
        windowDressing: "unlined white linen, cafe height",
        avoid: ["heavy colors", "gilt", "gloss"]
    )

    static let moroccanRiad = StyleFamily(
        name: "Moroccan Riad",
        tagline: "tadelakt, brass, tea light, deep shade",
        palette: .init(primary: "sand tadelakt", secondary: "saffron",
                       accent: "indigo tile", neutral: "warm greige", woodTone: "carved cedar", metalFinish: "hammered brass"),
        materials: .init(walls: "polished tadelakt plaster", floor: "hand-glazed zellige tile",
                         upholstery: "raw wool, camel leather", trim: "matte off-white", accents: ["hammered brass", "carved cedar", "zellige mosaic"]),
        lighting: .init(timeOfDay: "filtered through mashrabiya, dappled and warm", quality: "soft and diffused", fixtures: ["pierced brass lantern", "small brass tea lights"]),
        textiles: ["beni ourain rug", "kilim floor cushions", "vintage embroidered throw"],
        shelfStyling: ["carved wooden bowls", "hammered brass vessels", "hand-lettered korans", "tea glasses"],
        windowDressing: "hand-carved wooden mashrabiya screen or heavy raw-linen curtain",
        avoid: ["cold whites", "modern industrial finishes", "european antiques"]
    )

    static let californiaHacienda = StyleFamily(
        name: "California Hacienda",
        tagline: "adobe, terracotta, golden hour",
        palette: .init(primary: "adobe cream", secondary: "burnt sienna",
                       accent: "eucalyptus green", neutral: "warm greige", woodTone: "distressed mesquite", metalFinish: "wrought iron"),
        materials: .init(walls: "hand-troweled lime plaster", floor: "saltillo terracotta tile",
                         upholstery: "washed leather, cotton canvas", trim: "matte off-white", accents: ["mesquite", "wrought iron", "raw ceramic"]),
        lighting: .init(timeOfDay: "late golden hour, warm and directional", quality: "soft and diffused", fixtures: ["wrought iron chandelier", "carved wooden sconces"]),
        textiles: ["mexican serape throw", "flatweave wool rug", "canvas cushions"],
        shelfStyling: ["hand-thrown pottery", "cactus in terracotta", "leather-bound journals", "wrought iron crosses"],
        windowDressing: "heavy natural canvas drapes or wooden shutters",
        avoid: ["gilt", "pastels", "shine"]
    )

    static let englishCountryHouse = StyleFamily(
        name: "English Country House",
        tagline: "chintz, dog beds, generations of books",
        palette: .init(primary: "warm chalk", secondary: "moss and burgundy chintz",
                       accent: "brass and hunting green", neutral: "warm greige", woodTone: "aged oak", metalFinish: "brass"),
        materials: .init(walls: "matte painted or chintz-papered", floor: "wide oak with Persian runners",
                         upholstery: "chintz, tweed, worn leather", trim: "matte off-white", accents: ["oak", "brass", "porcelain"]),
        lighting: .init(timeOfDay: "overcast british morning, silvery", quality: "soft and diffused", fixtures: ["porcelain lamp bases", "brass picture lights", "candle sconces"]),
        textiles: ["chintz cushions", "tartan throws", "faded Persian carpets"],
        shelfStyling: ["shooting trophies", "porcelain shepherdesses", "leather-bound country books", "framed dog portraits"],
        windowDressing: "chintz drapes with pelmet, floor length",
        avoid: ["anything modern", "minimalism", "cool grays"]
    )

    static let mediterraneanFarmhouse = StyleFamily(
        name: "Mediterranean Farmhouse",
        tagline: "olive groves, whitewash, cured light",
        palette: .init(primary: "chalk white plaster", secondary: "olive green",
                       accent: "sun-baked ochre", neutral: "warm greige", woodTone: "cypress and olive wood", metalFinish: "hammered iron"),
        materials: .init(walls: "rough plaster, whitewashed", floor: "terracotta tile or worn stone",
                         upholstery: "washed linen, raw wool", trim: "matte off-white", accents: ["olive wood", "hand-thrown ceramic", "iron"]),
        lighting: .init(timeOfDay: "provencal midday, warm and dry", quality: "soft and diffused", fixtures: ["forged iron chandelier", "olive wood candlesticks"]),
        textiles: ["hand-embroidered linen", "wool blanket", "coarse cotton rug"],
        shelfStyling: ["olive oil bottles", "clay water jugs", "wooden mortars", "sun-faded photographs"],
        windowDressing: "raw linen with iron rings, or wooden shutters",
        avoid: ["gilt", "shine", "matched sets"]
    )

    static let mountainLodge = StyleFamily(
        name: "Mountain Lodge",
        tagline: "hewn timber, wool, hearth glow",
        palette: .init(primary: "smoked cedar walls", secondary: "cream shearling",
                       accent: "hunter green", neutral: "warm greige", woodTone: "hand-hewn timber", metalFinish: "blackened iron"),
        materials: .init(walls: "vertical timber planking", floor: "wide plank pine or slate",
                         upholstery: "shearling, wool tartan, thick leather", trim: "matte off-white", accents: ["antler", "iron", "stone"]),
        lighting: .init(timeOfDay: "alpine morning through frosted window", quality: "soft and diffused", fixtures: ["iron antler chandelier", "candle lanterns"]),
        textiles: ["hudson bay blanket", "sheepskin throws", "wool tartan"],
        shelfStyling: ["hunting field books", "antler mounts", "brass compass", "leather journal"],
        windowDressing: "heavy wool plaid drapes",
        avoid: ["polish", "gilt", "coastal whites"]
    )

    static let artDeco = StyleFamily(
        name: "Art Deco Salon",
        tagline: "geometry, lacquer, glamour",
        palette: .init(primary: "champagne", secondary: "ink black",
                       accent: "peacock teal", neutral: "warm greige", woodTone: "black lacquer", metalFinish: "polished chrome and brass"),
        materials: .init(walls: "lacquered or veneered", floor: "geometric marble or dark parquet",
                         upholstery: "velvet, satin", trim: "matte off-white", accents: ["mirror", "polished chrome", "black lacquer"]),
        lighting: .init(timeOfDay: "filtered through etched glass, dramatic", quality: "soft and diffused", fixtures: ["fan-shaped sconces", "geometric chandelier"]),
        textiles: ["silk velvet cushions", "geometric rug", "satin throws"],
        shelfStyling: ["chrome bar accessories", "lacquered boxes", "geometric sculptures", "black-and-white photography"],
        windowDressing: "silk velvet drapes with satin lining, geometric pelmet",
        avoid: ["farmhouse", "rustic", "distressed anything"]
    )

    static let italianRenaissanceRevival = StyleFamily(
        name: "Italian Renaissance Revival",
        tagline: "frescoed calm, aged gilt, garden light",
        palette: .init(primary: "buttermilk fresco", secondary: "faded verdigris",
                       accent: "aged gilt", neutral: "warm greige", woodTone: "aged walnut", metalFinish: "verdigris bronze"),
        materials: .init(walls: "hand-painted fresco or venetian plaster", floor: "cotto terracotta or veined marble",
                         upholstery: "faded silk damask", trim: "matte off-white", accents: ["carved walnut", "gilt frame", "aged bronze"]),
        lighting: .init(timeOfDay: "tuscan afternoon through tall windows", quality: "soft and diffused", fixtures: ["bronze candelabra", "small chandelier with hand-blown glass"]),
        textiles: ["damask cushions", "silk table runner", "faded oriental rug"],
        shelfStyling: ["leather-bound italian books", "small marble busts", "aged bronze figurines", "botanical prints"],
        windowDressing: "silk damask panels, floor length, with tassel tiebacks",
        avoid: ["anything modern", "cool tones", "minimalism"]
    )

    static let industrialLoft = StyleFamily(
        name: "Industrial Loft",
        tagline: "brick, steel, honest volumes",
        palette: .init(primary: "warm brick", secondary: "raw concrete",
                       accent: "oxblood leather", neutral: "warm greige", woodTone: "reclaimed timber", metalFinish: "blackened steel"),
        materials: .init(walls: "exposed brick or raw concrete", floor: "polished concrete or reclaimed plank",
                         upholstery: "aged leather, canvas", trim: "matte off-white", accents: ["blackened steel", "reclaimed timber", "riveted iron"]),
        lighting: .init(timeOfDay: "bright through tall industrial windows", quality: "soft and diffused", fixtures: ["factory pendant", "exposed edison bulbs on iron cage"]),
        textiles: ["aged leather", "canvas cushions", "flatweave rug in charcoal"],
        shelfStyling: ["blueprint tubes", "vintage cameras", "cast iron machine parts", "engineering books"],
        windowDressing: "unlined black cotton or bare industrial window",
        avoid: ["ornament", "pastels", "gilt"]
    )

    static let wabiSabi = StyleFamily(
        name: "Wabi-Sabi",
        tagline: "imperfect, weathered, revered",
        palette: .init(primary: "unbleached earth", secondary: "moss and stone",
                       accent: "clay red", neutral: "warm greige", woodTone: "reclaimed cedar", metalFinish: "hand-forged iron"),
        materials: .init(walls: "clay or rammed earth", floor: "worn stone or cedar plank",
                         upholstery: "undyed hemp, raw silk", trim: "matte off-white", accents: ["kintsugi ceramic", "raw wood", "hand-forged iron"]),
        lighting: .init(timeOfDay: "single directional shaft, meditative", quality: "soft and diffused", fixtures: ["paper lantern", "single beeswax candle"]),
        textiles: ["hand-loomed hemp", "boro-stitched cushions", "raw wool floor cushion"],
        shelfStyling: ["kintsugi-repaired bowl", "single found stone", "hand-brushed sumi-e scroll", "aged cedar box"],
        windowDressing: "paper screen or hemp scrim",
        avoid: ["ornament", "shine", "matched sets"]
    )

    static let shakerModern = StyleFamily(
        name: "Shaker Modern",
        tagline: "honest joinery, restraint, discipline",
        palette: .init(primary: "chalk white", secondary: "milk paint blue",
                       accent: "cherry wood", neutral: "warm greige", woodTone: "cherry and pine", metalFinish: "matte iron"),
        materials: .init(walls: "matte painted", floor: "wide pine plank",
                         upholstery: "natural cotton and wool", trim: "matte off-white", accents: ["cherry wood", "iron", "natural cotton"]),
        lighting: .init(timeOfDay: "clean north-facing morning", quality: "soft and diffused", fixtures: ["simple iron pendant", "candle sconce"]),
        textiles: ["woven cotton throw", "flatweave rug", "milk-paint stool cushion"],
        shelfStyling: ["hand-thrown pottery", "wooden oval boxes", "worn hymnals", "iron candleholders"],
        windowDressing: "shaker peg with unlined cotton panel",
        avoid: ["ornament", "shine", "excess"]
    )

    static let tropicalModernist = StyleFamily(
        name: "Tropical Modernist",
        tagline: "teak, breeze, filtered green light",
        palette: .init(primary: "coconut white", secondary: "deep teak",
                       accent: "botanical green", neutral: "warm greige", woodTone: "solid teak", metalFinish: "aged brass"),
        materials: .init(walls: "smooth white plaster", floor: "solid teak plank",
                         upholstery: "natural cotton, rattan weave", trim: "matte off-white", accents: ["teak", "rattan", "raw ceramic"]),
        lighting: .init(timeOfDay: "filtered through banana leaves, dappled green-gold", quality: "soft and diffused", fixtures: ["woven rattan pendant", "teak floor lamp"]),
        textiles: ["natural cotton cushions", "sisal rug", "batik throw"],
        shelfStyling: ["clay water vessels", "trailing monstera", "worn travel books", "carved wooden figures"],
        windowDressing: "wooden louvered shutters or unlined cotton drapes",
        avoid: ["heavy fabric", "cool tones", "gilt"]
    )
}

// =====================================================================
// MARK: Designer Muse (15)
// =====================================================================
//
// A Muse tightens a Style Family with a designer's voice. Muses do NOT
// override the Family's palette wholesale — they refine it, add signature
// gestures, and modify shelf styling and hero pieces.

struct DesignerMuse: Codable, Hashable, Identifiable {
    var id: String { name }
    var name: String
    var era: String
    var signature: String                // one-line voice
    var paletteRefinement: String        // how the muse tunes the palette
    var addHeroPieces: [String]
    var addShelfStyling: [String]
    var addAvoid: [String]
    var compatibleFamilies: [String]     // family names that pair well
}

enum DesignerMuseCatalog {

    static let all: [DesignerMuse] = [
        axelVervoordt, joannaWood, ilseCrawford, jacquesGrange, studioPeregalli,
        billyBaldwin, sohoHouse, kellyWearstler, natheStyle, robertKime,
        rosePedaru, veereGrenney, benjaminMoulder, muriTaniyama, henriSalembier
    ]

    static let axelVervoordt = DesignerMuse(
        name: "Axel Vervoordt",
        era: "1980-present, Antwerp",
        signature: "monastic quiet, patina worship, one perfect object per surface",
        paletteRefinement: "push toward earth and ash, remove all bright color",
        addHeroPieces: ["16th-century stripped-back oak chest", "single hand-thrown vessel on a plinth"],
        addShelfStyling: ["one aged object per shelf", "generous empty space", "no matched pairs"],
        addAvoid: ["ornament", "color", "shine"],
        compatibleFamilies: ["Belgian Transitional Country House", "Wabi-Sabi", "Warm Minimal", "Japandi Quiet Morning"]
    )

    static let joannaWood = DesignerMuse(
        name: "Joanna Wood",
        era: "1990-present, London",
        signature: "grand-house English comfort, layered textiles, deep chintz",
        paletteRefinement: "add moss, burgundy, and buttermilk chintz notes",
        addHeroPieces: ["deep-buttoned chesterfield in aged leather", "chintz-covered ottoman"],
        addShelfStyling: ["porcelain shepherdesses", "framed dog portraits", "cut-crystal decanters"],
        addAvoid: ["minimalism", "cool tones"],
        compatibleFamilies: ["English Country House", "Gentleman's Library London Club", "Parisian Classic Morning Salon"]
    )

    static let ilseCrawford = DesignerMuse(
        name: "Ilse Crawford",
        era: "2000-present, London/Amsterdam",
        signature: "humanism, tactile warmth, spaces that hold the body",
        paletteRefinement: "warm the neutrals, add one earthy accent (rust or moss)",
        addHeroPieces: ["low, generous linen sofa", "solid oak coffee table with rounded edges"],
        addShelfStyling: ["hand-thrown pottery", "well-worn cookbooks", "unpolished wooden bowls"],
        addAvoid: ["hard edges", "cool minimalism"],
        compatibleFamilies: ["Warm Minimal", "Japandi Quiet Morning", "Boho Morning Editorial", "Wabi-Sabi"]
    )

    static let jacquesGrange = DesignerMuse(
        name: "Jacques Grange",
        era: "1970-present, Paris",
        signature: "eclectic Parisian layering, mid-century meets 18th-century",
        paletteRefinement: "add faded rose and gilt without becoming precious",
        addHeroPieces: ["1940s French leather club chair", "gilt Directoire side table"],
        addShelfStyling: ["small oil portraits", "sevres porcelain", "letters tied with ribbon"],
        addAvoid: ["farmhouse anything", "modern minimalism"],
        compatibleFamilies: ["Parisian Classic Morning Salon", "Art Deco Salon", "Italian Renaissance Revival"]
    )

    static let studioPeregalli = DesignerMuse(
        name: "Studio Peregalli",
        era: "1990-present, Milan",
        signature: "hand-painted patina, invented history, romantic decay",
        paletteRefinement: "add hand-painted fresco elements and aged gilt",
        addHeroPieces: ["silk-upholstered settee with fringed trim", "walnut bureau with faded marquetry"],
        addShelfStyling: ["silk-bound italian volumes", "small marble intaglios", "aged silvered candlesticks"],
        addAvoid: ["anything crisp", "modern electronics"],
        compatibleFamilies: ["Italian Renaissance Revival", "Parisian Classic Morning Salon"]
    )

    static let billyBaldwin = DesignerMuse(
        name: "Billy Baldwin",
        era: "1950-1980, New York",
        signature: "dark lacquered walls, brass accents, deep-buttoned upholstery",
        paletteRefinement: "push toward ink, chocolate, and lacquered brown",
        addHeroPieces: ["brass slipper chair", "lacquered coffee table with brass inlay"],
        addShelfStyling: ["stacked art books", "brass matchboxes", "framed watercolors"],
        addAvoid: ["farmhouse", "pastels"],
        compatibleFamilies: ["Gentleman's Library London Club", "Art Deco Salon", "Parisian Classic Morning Salon"]
    )

    static let sohoHouse = DesignerMuse(
        name: "Soho House Interiors",
        era: "2000-present, global",
        signature: "layered vintage, unfussy luxury, members-club patina",
        paletteRefinement: "keep warm neutrals, add oxblood and forest green touches",
        addHeroPieces: ["deep vintage leather chesterfield", "large mid-century floor lamp"],
        addShelfStyling: ["vintage travel guides", "framed film stills", "worn record sleeves", "bar decanters"],
        addAvoid: ["catalog-fresh anything", "matched sets"],
        compatibleFamilies: ["Industrial Loft", "Gentleman's Library London Club", "English Country House"]
    )

    static let kellyWearstler = DesignerMuse(
        name: "Kelly Wearstler",
        era: "2000-present, Los Angeles",
        signature: "sculptural drama, unexpected color, artisanal glamour",
        paletteRefinement: "add one bold sculptural color and metallic accents",
        addHeroPieces: ["sculptural bronze coffee table", "boucle armchair with brass legs"],
        addShelfStyling: ["hand-blown glass vessels", "brutalist bronze objects", "art books flat-stacked"],
        addAvoid: ["timidity", "matched sets"],
        compatibleFamilies: ["Art Deco Salon", "California Hacienda", "Warm Minimal"]
    )

    static let natheStyle = DesignerMuse(
        name: "Nate Berkus / Jeremiah Brent",
        era: "2010-present, Los Angeles/New York",
        signature: "layered global, warm eclecticism, story-driven objects",
        paletteRefinement: "warm neutrals with one earth accent per zone",
        addHeroPieces: ["low profile linen sofa", "vintage moroccan rug", "carved wooden coffee table"],
        addShelfStyling: ["moroccan pottery", "berber talismans", "travel journals", "hand-carved wooden objects"],
        addAvoid: ["mass-produced", "cool grays"],
        compatibleFamilies: ["Boho Morning Editorial", "California Hacienda", "Moroccan Riad", "Warm Minimal"]
    )

    static let robertKime = DesignerMuse(
        name: "Robert Kime",
        era: "1980-2022, London",
        signature: "antique layered, faded textiles, English country intelligence",
        paletteRefinement: "add faded reds, pale gilt, and layered pattern-on-pattern",
        addHeroPieces: ["kelim-covered chesterfield", "antique walnut side table with lamp"],
        addShelfStyling: ["antique textile samples", "small oil landscapes", "porcelain small dishes"],
        addAvoid: ["shine", "matched sets", "trend colors"],
        compatibleFamilies: ["English Country House", "Belgian Transitional Country House", "Parisian Classic Morning Salon"]
    )

    static let rosePedaru = DesignerMuse(
        name: "Rose Uniacke",
        era: "2000-present, London",
        signature: "hushed reverence, ivory limewash, sculptural furniture",
        paletteRefinement: "push everything toward pale, tonal, and matte",
        addHeroPieces: ["sculptural cream boucle armchair", "raw wood plinth with single object"],
        addShelfStyling: ["one large ivory vessel", "single art book flat", "generous empty space"],
        addAvoid: ["color", "pattern", "shine"],
        compatibleFamilies: ["Warm Minimal", "Belgian Transitional Country House", "Wabi-Sabi"]
    )

    static let veereGrenney = DesignerMuse(
        name: "Veere Grenney",
        era: "1990-present, London",
        signature: "elegant British restraint, silk and cotton, poised comfort",
        paletteRefinement: "add subtle pattern in silk cushions and lampshades",
        addHeroPieces: ["skirted silk-covered ottoman", "painted english cabinet"],
        addShelfStyling: ["small silver frames", "leather-bound biographies", "porcelain small vessels"],
        addAvoid: ["heavy pattern", "farmhouse"],
        compatibleFamilies: ["English Country House", "Parisian Classic Morning Salon", "Belgian Transitional Country House"]
    )

    static let benjaminMoulder = DesignerMuse(
        name: "Ben Pentreath",
        era: "2000-present, England/Scotland",
        signature: "cheerful country-house classicism, chintz and stripe with confidence",
        paletteRefinement: "add cheerful chintz florals and one strong ground color",
        addHeroPieces: ["skirted chintz sofa", "painted regency chest"],
        addShelfStyling: ["ceramic staffordshire dogs", "framed botanical prints", "silver photo frames", "cut glass"],
        addAvoid: ["minimalism", "cool tones"],
        compatibleFamilies: ["English Country House", "Gentleman's Library London Club"]
    )

    static let muriTaniyama = DesignerMuse(
        name: "Shoji Hamada (spirit)",
        era: "20th century, Mashiko",
        signature: "quiet mingei folk ceramic aesthetic, deep tonal integrity",
        paletteRefinement: "restrict to earth, ash, iron, and one clay red",
        addHeroPieces: ["low cypress-wood table", "black stoneware vessel on woven mat"],
        addShelfStyling: ["single hamada-style bowl per shelf", "hand-brushed calligraphy scroll"],
        addAvoid: ["european ornament", "shine", "matched sets"],
        compatibleFamilies: ["Japandi Quiet Morning", "Wabi-Sabi"]
    )

    static let henriSalembier = DesignerMuse(
        name: "Madeline Stuart",
        era: "1990-present, Los Angeles",
        signature: "old-world european with californian light",
        paletteRefinement: "add sun-bleached european palette accents",
        addHeroPieces: ["antique painted french armoire", "faded aubusson-style rug"],
        addShelfStyling: ["18th-century pewter", "silvered candlesticks", "hand-marbled papers"],
        addAvoid: ["cold minimalism", "farmhouse"],
        compatibleFamilies: ["California Hacienda", "Parisian Classic Morning Salon", "Italian Renaissance Revival"]
    )
}

// =====================================================================
// MARK: Mood Words (30)
// =====================================================================
//
// Moods tune the atmosphere — the softest layer. Pick 1-3.

struct MoodWord: Codable, Hashable, Identifiable {
    var id: String { name }
    var name: String
    /// Short atmosphere phrase merged into the mood statement.
    var atmosphere: String
    /// Optional lighting tweak.
    var lightingTweak: String?
}

enum MoodWordCatalog {

    static let all: [MoodWord] = [
        .init(name: "Hushed",       atmosphere: "voices lowered, air held still", lightingTweak: "dimmed daylight, no direct sun"),
        .init(name: "Lived-in",     atmosphere: "someone was here twenty minutes ago", lightingTweak: nil),
        .init(name: "Convalescent", atmosphere: "recovering, softly bathed in slow morning", lightingTweak: "late-morning east light"),
        .init(name: "Ceremonial",   atmosphere: "prepared, formal, expectant", lightingTweak: nil),
        .init(name: "Weathered",    atmosphere: "everything has taken its beating and stayed", lightingTweak: nil),
        .init(name: "Golden",       atmosphere: "sun-drenched, honey-cast, warm", lightingTweak: "afternoon golden hour"),
        .init(name: "Overcast",     atmosphere: "silvery, diffuse, cool-cast", lightingTweak: "north-facing overcast"),
        .init(name: "Candlelit",    atmosphere: "flickering pools of warmth, deep shadow", lightingTweak: "candlelight primary, minimal daylight"),
        .init(name: "Morning",      atmosphere: "eastern light, teacups, unfinished conversations", lightingTweak: "east-facing morning"),
        .init(name: "Evening",      atmosphere: "decanted, sunset-facing, ready for a long conversation", lightingTweak: "late golden hour"),
        .init(name: "Autumnal",     atmosphere: "brass and rust, layered wool, apples ripening", lightingTweak: "low-angled amber light"),
        .init(name: "Wintered",     atmosphere: "hearth-warm, snow-lit, deep blanket weight", lightingTweak: "white winter light through window"),
        .init(name: "Verdant",      atmosphere: "botanical, living, breath of trailing green", lightingTweak: nil),
        .init(name: "Bookish",      atmosphere: "the smell of paper, half-open volumes on every surface", lightingTweak: nil),
        .init(name: "Rumpled",      atmosphere: "throws crumpled, cushions dented, no styling", lightingTweak: nil),
        .init(name: "Formal",       atmosphere: "arranged for company, edges crisp", lightingTweak: nil),
        .init(name: "Intimate",     atmosphere: "small, low-lit, made for two chairs and one lamp", lightingTweak: "single warm lamp"),
        .init(name: "Grand",        atmosphere: "high-ceilinged, statement furniture, hushed power", lightingTweak: nil),
        .init(name: "Melancholic",  atmosphere: "quiet sadness, one candle, one glass, one book", lightingTweak: "dim candlelight"),
        .init(name: "Optimistic",   atmosphere: "fresh flowers, open windows, morning breeze", lightingTweak: nil),
        .init(name: "Nostalgic",    atmosphere: "objects that belonged to someone else first", lightingTweak: nil),
        .init(name: "Scholarly",    atmosphere: "papers spread, glasses off, marginalia everywhere", lightingTweak: nil),
        .init(name: "Bohemian",     atmosphere: "layered rugs, trailing plants, everything collected on trips", lightingTweak: nil),
        .init(name: "Monastic",     atmosphere: "one object per surface, empty space treated as sacred", lightingTweak: nil),
        .init(name: "Salted",       atmosphere: "sea-air, weathered wood, opened windows", lightingTweak: nil),
        .init(name: "Rain-Struck",  atmosphere: "grey light, warm interior, book weather", lightingTweak: "overcast, no direct sun"),
        .init(name: "Feast-Ready",  atmosphere: "table laid, candles lit, guests fifteen minutes away", lightingTweak: "candlelight primary"),
        .init(name: "Just-Vacated", atmosphere: "half-drunk cup, folded newspaper, throw slipping off the chair", lightingTweak: nil),
        .init(name: "Museum-Quiet", atmosphere: "curated, spare, reverent", lightingTweak: nil),
        .init(name: "Convivial",    atmosphere: "multiple glasses out, decanter half-empty, laughter recently left the room", lightingTweak: nil)
    ]
}

// =====================================================================
// MARK: Style Selection & Merge
// =====================================================================
//
// StyleSelection captures the user's picks + optional free-text overrides
// and produces a completed StyleDNA via .composeDNA().

struct StyleSelection: Codable, Hashable {
    /// Required. The base grammar.
    var family: StyleFamily
    /// Optional muse layer.
    var muse: DesignerMuse? = nil
    /// Optional 1-3 mood words.
    var moods: [MoodWord] = []
    /// Optional free-text overrides. Any non-empty field REPLACES the
    /// picker's version. Empty fields leave the picker choice intact.
    var overrides: StyleOverrides = .init()

    /// Compose a full StyleDNA from the selection.
    func composeDNA() -> StyleDNA {
        // Base palette + materials from Family. Muse refines, Moods layer atmosphere.
        let f = family
        let m = muse

        // Palette — muse note appended to palette description as an accent nudge.
        var palette = f.palette
        // Materials — from family (muse doesn't override, only augments hero/shelf).
        let materials = f.materials
        // Lighting — family base, mood may tweak daylight.
        var lighting = f.lighting
        if let mood = moods.first(where: { $0.lightingTweak != nil }),
           let tweak = mood.lightingTweak {
            lighting.timeOfDay = tweak
        }

        // Hero pieces — muse adds hero pieces if compatible.
        var heroPieces: [String] = m?.addHeroPieces ?? []

        // Textiles — from family.
        var textiles = f.textiles

        // Shelf styling — family + muse additions.
        var shelfStyling = f.shelfStyling
        if let addShelf = m?.addShelfStyling { shelfStyling.append(contentsOf: addShelf) }

        // Window dressing — family default.
        var windowDressing = f.windowDressing

        // Avoid — combined family + muse.
        var avoid = f.avoid
        if let addAvoid = m?.addAvoid { avoid.append(contentsOf: addAvoid) }

        // Mood statement — first line from family tagline, then muse signature, then mood atmospheres.
        var moodLines: [String] = [f.tagline]
        if let mu = m { moodLines.append(mu.signature) }
        for md in moods { moodLines.append(md.atmosphere) }
        var moodStatement = moodLines.joined(separator: ". ").capitalized(withFirstOnly: true) + "."

        // ---- Apply free-text overrides (Option C) ----
        if let v = overrides.paletteAccent { palette.accent = v }
        if let v = overrides.woodTone { palette.woodTone = v }
        if let v = overrides.metal { palette.metalFinish = v }
        if let v = overrides.daylight { lighting.timeOfDay = v }
        if let v = overrides.windowDressing { windowDressing = v }
        if let extraHero = overrides.additionalHeroPieces, !extraHero.isEmpty {
            heroPieces.append(contentsOf: extraHero)
        }
        if let extraTextiles = overrides.additionalTextiles, !extraTextiles.isEmpty {
            textiles.append(contentsOf: extraTextiles)
        }
        if let extraShelf = overrides.additionalShelfStyling, !extraShelf.isEmpty {
            shelfStyling.append(contentsOf: extraShelf)
        }
        if let extraAvoid = overrides.additionalAvoid, !extraAvoid.isEmpty {
            avoid.append(contentsOf: extraAvoid)
        }
        if let v = overrides.moodStatementOverride {
            moodStatement = v
        }

        // Compose the DNA name for the reuse header.
        var dnaName = f.name
        if let mu = m { dnaName += " x \(mu.name)" }
        if !moods.isEmpty {
            dnaName += " (" + moods.map { $0.name }.joined(separator: ", ") + ")"
        }

        return StyleDNA(
            name: dnaName,
            tagline: f.tagline,
            family: f.name,
            moodStatement: moodStatement,
            palette: palette,
            materials: materials,
            lighting: lighting,
            heroPieces: heroPieces.isEmpty ? ["one statement hero piece per family default"] : heroPieces,
            windowDressing: windowDressing,
            textiles: textiles,
            shelfStyling: shelfStyling,
            avoid: avoid,
            cameraNote: "face-on orthographic elevation, seated eye level, no vanishing points",
            version: "v1"
        )
    }
}

/// Optional free-text overrides on top of a picker selection (Option C).
/// Any non-nil, non-empty field wins over the picker's choice.
struct StyleOverrides: Codable, Hashable {
    var paletteAccent: String? = nil
    var woodTone: String? = nil
    var metal: String? = nil
    var daylight: String? = nil
    var windowDressing: String? = nil
    var additionalHeroPieces: [String]? = nil
    var additionalTextiles: [String]? = nil
    var additionalShelfStyling: [String]? = nil
    var additionalAvoid: [String]? = nil
    var moodStatementOverride: String? = nil
}

// Small helper — capitalize just the first character of a sentence.
private extension String {
    func capitalized(withFirstOnly: Bool) -> String {
        guard withFirstOnly, let first = self.first else { return self }
        return first.uppercased() + dropFirst()
    }
}
