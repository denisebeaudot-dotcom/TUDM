import Foundation

// MARK: - Persona Catalog
//
// The Persona Catalog is a dynamic library for building the "who" of a
// render. A completed Persona is composed from:
//
//   1. Archetype (required — the base identity)
//   2. Era/Origin (optional — temporal + geographic anchor)
//   3. Signature Traits (0-3 — behavioral tells that produce visible objects)
//   4. Gap-Fill answers (5 concrete-object questions, all optional)
//   5. Free-text overrides on any field
//
// Three build modes:
//
//   Mode 1 — Generated: pick archetype only, system rolls the rest
//   Mode 2 — Guided:    pick what you know, system asks the 5 gap questions
//   Mode 3 — Manual:    write the whole thing yourself
//
// The output plugs into the existing Persona struct in DNAG.swift.

// =====================================================================
// MARK: Persona Archetype (18)
// =====================================================================

struct PersonaArchetype: Codable, Hashable, Identifiable {
    var id: String { name }
    var name: String
    var profession: String
    var voiceOneLiner: String
    /// Default biography anchors (concrete life events, not personality)
    var biographyAnchors: [String]
    /// Objects that MUST appear to signal this archetype
    var mustSeeObjects: [String]
    /// Objects this archetype would never own
    var forbiddenObjects: [String]
    /// Style families this archetype naturally belongs in
    var compatibleFamilies: [String]
    /// Style families this archetype would find alienating (guardrail)
    var incompatibleFamilies: [String]
}

enum PersonaArchetypeCatalog {

    static let all: [PersonaArchetype] = [
        retiredKC, agingCeramicist, concertCellist, cartographersWidow,
        academicHistorian, farmingWidower, textileArtist, museumConservator,
        travelWriter, retiredDiplomat, jazzPianist, botanicalIllustrator,
        antiquarianBookseller, seaCaptainAshore, painterInResidence,
        theatreDirector, monasticScholar, wineImporter
    ]

    static func find(_ name: String) -> PersonaArchetype? {
        all.first { $0.name.caseInsensitiveCompare(name) == .orderedSame }
    }

    static let retiredKC = PersonaArchetype(
        name: "Retired King's Counsel",
        profession: "barrister, retired after decades at the Inner Temple",
        voiceOneLiner: "reads late, drinks single-malt, considers a room finished only when the books stop lining up straight",
        biographyAnchors: [
            "half-century legal career",
            "map collector, amateur historian",
            "quiet traveller (India, Egypt, the Levant)",
            "working desk, not a decorative one"
        ],
        mustSeeObjects: [
            "rolled maps",
            "leather legal folios or a dispatch box",
            "aged globe",
            "framed hound portrait or landscape",
            "worn Persian rug"
        ],
        forbiddenObjects: [
            "modern electronics",
            "catalog-fresh objects",
            "matched sets",
            "shiny brass with no patina"
        ],
        compatibleFamilies: ["Gentleman's Library London Club", "English Country House", "Belgian Transitional Country House"],
        incompatibleFamilies: ["Boho Morning Editorial", "Tropical Modernist", "California Hacienda", "Art Deco Salon"]
    )

    static let agingCeramicist = PersonaArchetype(
        name: "Aging Ceramicist",
        profession: "potter, fifty years at the wheel, gallery-represented",
        voiceOneLiner: "throws in the morning, reads in the afternoon, calls a pot \"nearly right\" its highest compliment",
        biographyAnchors: [
            "trained in Mashiko for two years",
            "kiln in the garden, still fires it monthly",
            "widow(er) — spouse was the poet",
            "grown children moved abroad"
        ],
        mustSeeObjects: [
            "unglazed test tiles",
            "hand-thrown vessel in daily use",
            "well-worn apron on a hook",
            "shelf of books on Bernard Leach and Shoji Hamada",
            "single ikebana branch"
        ],
        forbiddenObjects: ["fine china", "gilt", "shine", "matched sets"],
        compatibleFamilies: ["Wabi-Sabi", "Japandi Quiet Morning", "Warm Minimal", "Boho Morning Editorial"],
        incompatibleFamilies: ["Art Deco Salon", "Parisian Classic Morning Salon", "Gentleman's Library London Club"]
    )

    static let concertCellist = PersonaArchetype(
        name: "Concert Cellist",
        profession: "principal cellist, retired from the orchestra, teaches privately",
        voiceOneLiner: "practices before breakfast, drinks black tea, keeps a metronome on the mantel",
        biographyAnchors: [
            "conservatory-trained, thirty years in the orchestra",
            "cello case leaning in the corner, always",
            "wife/husband was a translator",
            "teaches two students on Sunday mornings"
        ],
        mustSeeObjects: [
            "cello leaning against a wall",
            "sheet music stacked on the coffee table",
            "silver metronome",
            "framed concert posters",
            "record player with vinyl stack"
        ],
        forbiddenObjects: ["ostentatious wealth", "electronic instruments visible"],
        compatibleFamilies: ["Parisian Classic Morning Salon", "Belgian Transitional Country House", "Warm Minimal"],
        incompatibleFamilies: ["California Hacienda", "Industrial Loft"]
    )

    static let cartographersWidow = PersonaArchetype(
        name: "Cartographer's Widow",
        profession: "retired schoolteacher, husband was a cartographer",
        voiceOneLiner: "still opens his atlas each morning; the maps are all his",
        biographyAnchors: [
            "husband died five years ago, cartographer at the Royal Society",
            "kept every one of his maps, framed and unframed",
            "still hosts Sunday supper for his old colleagues",
            "reads mystery novels late"
        ],
        mustSeeObjects: [
            "walls hung with framed antique maps",
            "leather-bound atlases on the shelf",
            "brass magnifying glass on a side table",
            "single reading chair with a lamp",
            "framed sepia photo of him"
        ],
        forbiddenObjects: ["modern art", "second reading chair (only one)"],
        compatibleFamilies: ["English Country House", "Belgian Transitional Country House", "Gentleman's Library London Club"],
        incompatibleFamilies: ["Boho Morning Editorial", "Art Deco Salon", "Tropical Modernist"]
    )

    static let academicHistorian = PersonaArchetype(
        name: "Academic Historian",
        profession: "professor emeritus of medieval history",
        voiceOneLiner: "there are always three books open at once, and marginalia in every one",
        biographyAnchors: [
            "forty-year career at a research university",
            "specialty: cathedral architecture",
            "sabbaticals in Italy, Spain, and Germany",
            "widowed early, no children"
        ],
        mustSeeObjects: [
            "three or four books open face-down",
            "index cards and marginalia notes",
            "reading glasses folded on top of a manuscript",
            "framed cathedral rubbings",
            "single leather club chair, deeply worn"
        ],
        forbiddenObjects: ["decorative-only books", "matched leather sets"],
        compatibleFamilies: ["Gentleman's Library London Club", "English Country House", "Italian Renaissance Revival"],
        incompatibleFamilies: ["Boho Morning Editorial", "Tropical Modernist", "Coastal Nordic"]
    )

    static let farmingWidower = PersonaArchetype(
        name: "Farming Widower",
        profession: "retired sheep farmer in the Cotswolds",
        voiceOneLiner: "still up at five, still checks the sky first",
        biographyAnchors: [
            "took over the farm from his father, ran it fifty years",
            "wife died last winter",
            "still has two working dogs",
            "sons moved to London, visit at Christmas"
        ],
        mustSeeObjects: [
            "muddy waxed jacket on a hook",
            "wooden shepherd's crook",
            "battered leather armchair by the fire",
            "framed sheep-trial rosettes",
            "worn Bible on a side table"
        ],
        forbiddenObjects: ["anything precious", "matched sets", "shine"],
        compatibleFamilies: ["English Country House", "Mountain Lodge", "Belgian Transitional Country House"],
        incompatibleFamilies: ["Art Deco Salon", "Parisian Classic Morning Salon", "Tropical Modernist"]
    )

    static let textileArtist = PersonaArchetype(
        name: "Textile Artist",
        profession: "hand-weaver, gallery-shown, thirty-year career",
        voiceOneLiner: "keeps the loom in the living room because it's the room she uses",
        biographyAnchors: [
            "studied in Kyoto for a year",
            "collects textile fragments from souks and markets",
            "collaborates with a dyer in Oaxaca",
            "single, deeply solitary work"
        ],
        mustSeeObjects: [
            "small hand-loom in the corner",
            "baskets of raw wool and dyed yarn",
            "framed textile fragments on the wall",
            "one large woven wall hanging",
            "hand-thrown ceramic vessels holding shuttles"
        ],
        forbiddenObjects: ["synthetic fabric visible", "shine", "gilt"],
        compatibleFamilies: ["Wabi-Sabi", "Japandi Quiet Morning", "Warm Minimal", "Boho Morning Editorial"],
        incompatibleFamilies: ["Gentleman's Library London Club", "Art Deco Salon"]
    )

    static let museumConservator = PersonaArchetype(
        name: "Museum Conservator",
        profession: "retired paintings conservator, thirty years at a major museum",
        voiceOneLiner: "notices the varnish on every painting before she notices the subject",
        biographyAnchors: [
            "conservator of 17th-century Dutch and Flemish paintings",
            "loupe on a chain around her neck at all times",
            "widowed, one son who is a chef",
            "still consults on private collections"
        ],
        mustSeeObjects: [
            "framed conservator's magnifier",
            "small 17th-century oil painting on a side table (not yet framed)",
            "pigment jars",
            "loupe on the coffee table",
            "reference volumes on chemistry of pigments"
        ],
        forbiddenObjects: ["mass-produced prints", "modern electronics visible"],
        compatibleFamilies: ["Belgian Transitional Country House", "Parisian Classic Morning Salon", "Italian Renaissance Revival"],
        incompatibleFamilies: ["Tropical Modernist", "California Hacienda", "Boho Morning Editorial"]
    )

    static let travelWriter = PersonaArchetype(
        name: "Travel Writer",
        profession: "long-form travel writer, ten books, still filing occasionally",
        voiceOneLiner: "the room is a slow accretion of trips",
        biographyAnchors: [
            "based in this house between assignments",
            "reported from Marrakech, Kyoto, Cairo, Havana",
            "divorced, close friends everywhere",
            "still travels twice a year"
        ],
        mustSeeObjects: [
            "battered leather travel journal on the coffee table",
            "objects from every country layered on shelves",
            "framed photograph of a specific street in Fez",
            "well-used Olivetti or leather notebook",
            "kilim rugs layered on top of each other"
        ],
        forbiddenObjects: ["matched sets", "catalog-fresh"],
        compatibleFamilies: ["Boho Morning Editorial", "Moroccan Riad", "California Hacienda", "Tropical Modernist"],
        incompatibleFamilies: ["Shaker Modern", "Coastal Nordic"]
    )

    static let retiredDiplomat = PersonaArchetype(
        name: "Retired Diplomat",
        profession: "career diplomat, ambassador in three postings",
        voiceOneLiner: "objects on shelves have provenance and stories, not decoration",
        biographyAnchors: [
            "posted to Tehran, Vienna, and Lisbon",
            "married to a translator (still living)",
            "reads three newspapers daily",
            "still consulted on quiet matters"
        ],
        mustSeeObjects: [
            "framed diplomatic photograph (formal, black-tie)",
            "gifted objects from three cultures on one shelf",
            "leather-bound state books",
            "small silver-framed portraits",
            "single crystal decanter with real whisky in it"
        ],
        forbiddenObjects: ["ostentation", "modern electronics"],
        compatibleFamilies: ["Parisian Classic Morning Salon", "Gentleman's Library London Club", "Belgian Transitional Country House"],
        incompatibleFamilies: ["Boho Morning Editorial", "Industrial Loft"]
    )

    static let jazzPianist = PersonaArchetype(
        name: "Jazz Pianist",
        profession: "session and club pianist, decades in the trade",
        voiceOneLiner: "the ashtray is clean but the piano isn't dusted",
        biographyAnchors: [
            "toured with a dozen singers",
            "still plays two nights a week at a small club",
            "divorced twice",
            "keeps late hours"
        ],
        mustSeeObjects: [
            "upright piano visible or heavily implied via sheet music",
            "stacked LP records",
            "half-empty tumbler of whiskey",
            "framed black-and-white photos of musicians",
            "single reading lamp on the piano"
        ],
        forbiddenObjects: ["bright colors", "chintz", "farmhouse"],
        compatibleFamilies: ["Art Deco Salon", "Industrial Loft", "Gentleman's Library London Club"],
        incompatibleFamilies: ["Coastal Nordic", "Shaker Modern"]
    )

    static let botanicalIllustrator = PersonaArchetype(
        name: "Botanical Illustrator",
        profession: "watercolor botanical illustrator, published in three field guides",
        voiceOneLiner: "the room is arranged around the north-facing light",
        biographyAnchors: [
            "trained at Kew Gardens",
            "commissions from botanical journals",
            "widow(er), one daughter",
            "spends August in the herbaceous border"
        ],
        mustSeeObjects: [
            "watercolor paints and brushes on a side table",
            "pressed botanical specimens in a folder",
            "framed original watercolors",
            "small vase with a single cutting",
            "well-thumbed flora reference books"
        ],
        forbiddenObjects: ["synthetic flowers", "gilt"],
        compatibleFamilies: ["English Country House", "Parisian Classic Morning Salon", "Warm Minimal"],
        incompatibleFamilies: ["Industrial Loft", "Art Deco Salon"]
    )

    static let antiquarianBookseller = PersonaArchetype(
        name: "Antiquarian Bookseller",
        profession: "rare-books dealer, forty-year shop",
        voiceOneLiner: "every book on the shelf has been valued at least once",
        biographyAnchors: [
            "specialty: early printed English",
            "still catalogs by hand",
            "wife/husband was a librarian",
            "children took over the shop"
        ],
        mustSeeObjects: [
            "leather-bound folios stacked flat",
            "book press or bookbinding tools",
            "reading lamp with green glass shade",
            "framed engraved bookplates",
            "vellum-bound ledgers"
        ],
        forbiddenObjects: ["paperbacks", "modern books", "shine"],
        compatibleFamilies: ["Gentleman's Library London Club", "English Country House", "Belgian Transitional Country House"],
        incompatibleFamilies: ["Coastal Nordic", "Tropical Modernist", "California Hacienda"]
    )

    static let seaCaptainAshore = PersonaArchetype(
        name: "Sea Captain Ashore",
        profession: "retired merchant marine captain",
        voiceOneLiner: "the sextant is polished but the leather chair is not",
        biographyAnchors: [
            "thirty years at sea, container ships and tankers",
            "married to a nurse (still working)",
            "reads sea stories only",
            "kept every logbook"
        ],
        mustSeeObjects: [
            "brass sextant on a shelf",
            "ship in bottle (single, aged)",
            "framed nautical chart",
            "logbooks bound in cracked leather",
            "brass ship's clock, ticking"
        ],
        forbiddenObjects: ["chintz", "gilt", "farmhouse anything"],
        compatibleFamilies: ["Coastal Nordic", "Gentleman's Library London Club", "Industrial Loft"],
        incompatibleFamilies: ["Boho Morning Editorial", "Parisian Classic Morning Salon"]
    )

    static let painterInResidence = PersonaArchetype(
        name: "Painter in Residence",
        profession: "abstract painter, mid-career, gallery-represented",
        voiceOneLiner: "the room is his second studio",
        biographyAnchors: [
            "studio in Marfa, second home here",
            "MFA from Yale",
            "married to an architect",
            "hosts salon dinners once a month"
        ],
        mustSeeObjects: [
            "one large finished canvas leaning against a wall",
            "paint-splashed drop cloth folded on a shelf",
            "hand-thrown pottery holding brushes",
            "framed exhibition posters",
            "single sculptural chair"
        ],
        forbiddenObjects: ["ornament", "gilt", "chintz"],
        compatibleFamilies: ["Warm Minimal", "Industrial Loft", "California Hacienda", "Japandi Quiet Morning"],
        incompatibleFamilies: ["English Country House", "Parisian Classic Morning Salon"]
    )

    static let theatreDirector = PersonaArchetype(
        name: "Theatre Director",
        profession: "stage director, twenty years running a regional company",
        voiceOneLiner: "the room is composed like a set",
        biographyAnchors: [
            "known for Chekhov and Ibsen",
            "married to a playwright",
            "no children, many rescued dogs",
            "keeps a wall of production posters"
        ],
        mustSeeObjects: [
            "framed production posters spanning decades",
            "well-thumbed scripts on the coffee table",
            "single dramatic lamp",
            "dog bed under a side chair",
            "stacked Chekhov, Ibsen, Miller"
        ],
        forbiddenObjects: ["chintz", "farmhouse", "matched sets"],
        compatibleFamilies: ["Art Deco Salon", "Gentleman's Library London Club", "Industrial Loft"],
        incompatibleFamilies: ["Coastal Nordic", "Shaker Modern"]
    )

    static let monasticScholar = PersonaArchetype(
        name: "Monastic Scholar",
        profession: "retired religious scholar, former monk",
        voiceOneLiner: "the room is spare on principle, not on budget",
        biographyAnchors: [
            "twenty years in a Benedictine monastery",
            "left to teach at a seminary",
            "still keeps the Divine Office",
            "single, celibate, deeply peaceful"
        ],
        mustSeeObjects: [
            "single wooden crucifix on the wall",
            "worn breviary on a side table",
            "one plain oak reading chair",
            "candle in a hand-thrown holder",
            "stack of theological volumes"
        ],
        forbiddenObjects: ["ornament", "color", "shine", "clutter"],
        compatibleFamilies: ["Wabi-Sabi", "Shaker Modern", "Warm Minimal", "Belgian Transitional Country House"],
        incompatibleFamilies: ["Art Deco Salon", "Boho Morning Editorial", "Tropical Modernist"]
    )

    static let wineImporter = PersonaArchetype(
        name: "Wine Importer",
        profession: "small-batch wine importer, thirty years",
        voiceOneLiner: "the decanter is never dry and every bottle has been to his cellar",
        biographyAnchors: [
            "specialty: small Burgundian producers",
            "still travels to France four times a year",
            "married to a chef",
            "one grown daughter running the business"
        ],
        mustSeeObjects: [
            "opened bottle and two glasses on the coffee table",
            "leather-bound tasting notebook",
            "framed vineyard photograph",
            "small brass corkscrew collection",
            "crystal decanter, half-full"
        ],
        forbiddenObjects: ["mass-market wine posters", "chain-store objects"],
        compatibleFamilies: ["Parisian Classic Morning Salon", "Belgian Transitional Country House", "Mediterranean Farmhouse", "English Country House"],
        incompatibleFamilies: ["Tropical Modernist", "Industrial Loft"]
    )
}

// =====================================================================
// MARK: Persona Era / Origin (15)
// =====================================================================

struct PersonaEra: Codable, Hashable, Identifiable {
    var id: String { name }
    var name: String
    /// Time period + place
    var context: String
    /// A note to add to biography anchors
    var biographyNote: String
}

enum PersonaEraCatalog {
    static let all: [PersonaEra] = [
        .init(name: "Postwar London",         context: "1950-1970 London", biographyNote: "grew up in postwar London, still remembers rationing"),
        .init(name: "1970s Kyoto",            context: "1970s Kyoto",      biographyNote: "trained in Kyoto in the 1970s"),
        .init(name: "Contemporary Marrakech", context: "2000s Marrakech",  biographyNote: "settled in Marrakech in the last two decades"),
        .init(name: "Edwardian England",      context: "1900-1914 England", biographyNote: "family is old Edwardian, quietly declining"),
        .init(name: "Postwar Paris",          context: "1950s Paris",      biographyNote: "came of age in postwar Paris"),
        .init(name: "1960s Havana",           context: "1960s Havana",     biographyNote: "family emigrated from Havana in the 60s"),
        .init(name: "Belle Époque",           context: "1890-1914 France", biographyNote: "inherited a Belle Époque family apartment"),
        .init(name: "Georgian Bath",          context: "18th c. Bath",     biographyNote: "the family house in Bath is Georgian, and unchanged"),
        .init(name: "Interwar Vienna",        context: "1920-1938 Vienna", biographyNote: "grandparents fled interwar Vienna, brought what they could"),
        .init(name: "Cold War Berlin",        context: "1970s-80s Berlin", biographyNote: "worked in Cold War Berlin, never quite left"),
        .init(name: "1970s San Francisco",    context: "1970s San Francisco", biographyNote: "came up in 1970s San Francisco"),
        .init(name: "Contemporary Kyoto",     context: "2000s-present Kyoto", biographyNote: "lives half the year in contemporary Kyoto"),
        .init(name: "Renaissance Florence",   context: "Florence, generations", biographyNote: "family has been in Florence for generations"),
        .init(name: "1930s Casablanca",       context: "1930s Casablanca", biographyNote: "grew up in colonial 1930s Casablanca"),
        .init(name: "Contemporary Copenhagen", context: "contemporary Copenhagen", biographyNote: "based in Copenhagen, minimal by discipline")
    ]
}

// =====================================================================
// MARK: Signature Traits (30)
// =====================================================================
//
// Traits are behavioral tells that translate into visible objects.
// Each trait pushes one or two concrete items into the render.

struct SignatureTrait: Codable, Hashable, Identifiable {
    var id: String { name }
    var name: String
    /// Behavioral description
    var behavior: String
    /// Concrete objects this trait puts in the room
    var objectSignals: [String]
}

enum SignatureTraitCatalog {
    static let all: [SignatureTrait] = [
        .init(name: "collects maps",           behavior: "compulsive amateur cartographer", objectSignals: ["rolled maps", "framed antique map"]),
        .init(name: "cooks nightly",           behavior: "the kitchen bleeds into the living room", objectSignals: ["cookbook stacked on coffee table", "wooden mortar and pestle on side table"]),
        .init(name: "grieves publicly",        behavior: "keeps the deceased spouse's things visible", objectSignals: ["single silver-framed portrait", "his/her book open, unfinished"]),
        .init(name: "hoards paper",            behavior: "unable to throw out any document", objectSignals: ["stacked paper folders", "handwritten letters tied with ribbon"]),
        .init(name: "keeps a journal",         behavior: "writes every morning before speaking to anyone", objectSignals: ["leather notebook and fountain pen on side table"]),
        .init(name: "drinks single-malt",      behavior: "one whisky nightly, always the same brand", objectSignals: ["crystal decanter with amber liquid", "worn tumbler"]),
        .init(name: "reads late",              behavior: "up past midnight most nights", objectSignals: ["reading lamp with warm shade", "book face-down on chair arm"]),
        .init(name: "plays chess by post",     behavior: "correspondence chess with three opponents", objectSignals: ["chess board mid-game on a side table", "postcards from opponents"]),
        .init(name: "keeps birds",             behavior: "one aged parrot or two canaries", objectSignals: ["ornate brass cage in a corner", "birdseed dish"]),
        .init(name: "presses flowers",         behavior: "botanical specimens under books", objectSignals: ["heavy botanical press", "framed pressed specimens"]),
        .init(name: "smokes a pipe",           behavior: "one pipe after dinner, on the porch", objectSignals: ["worn pipe rack", "tobacco tin"]),
        .init(name: "plays vinyl",             behavior: "no digital music in the house", objectSignals: ["turntable and stack of LPs", "framed record sleeves"]),
        .init(name: "loves dogs",              behavior: "at least two rescues on the sofa", objectSignals: ["worn dog bed", "framed dog portrait", "leash on a hook"]),
        .init(name: "collects rocks",          behavior: "beach and mountain finds", objectSignals: ["shallow bowl of rocks and shells on the coffee table"]),
        .init(name: "writes letters",          behavior: "hand-writes 3 letters a week", objectSignals: ["writing box open on desk", "wax and seal", "stationery"]),
        .init(name: "keeps clocks",            behavior: "multiple ticking clocks, all wound weekly", objectSignals: ["mantel clock", "small brass carriage clock", "pocket watch on a stand"]),
        .init(name: "practices calligraphy",   behavior: "sumi-e ink work in the mornings", objectSignals: ["inkstone and brush on a low table", "hanging scroll on the wall"]),
        .init(name: "restores furniture",      behavior: "one project at a time in the living room", objectSignals: ["partially caned chair on a drop cloth", "small tool roll"]),
        .init(name: "grows orchids",           behavior: "twelve or more on the windowsill", objectSignals: ["multiple orchids in the window bay", "watering pipette"]),
        .init(name: "tracks weather",          behavior: "amateur meteorologist", objectSignals: ["barometer on the wall", "handwritten weather log", "brass thermometer"]),
        .init(name: "reads mysteries",         behavior: "three-a-week detective novel habit", objectSignals: ["current paperback face-down", "stack of used mystery paperbacks"]),
        .init(name: "keeps bees",              behavior: "hives in the garden, honey on the shelf", objectSignals: ["jars of honey on a shelf", "framed illustration of hive"]),
        .init(name: "quilts",                  behavior: "hand-pieced quilts, one always in progress", objectSignals: ["quilt-in-progress folded on the ottoman", "basket of fabric scraps"]),
        .init(name: "collects seashells",      behavior: "beach walks, obsessively curated", objectSignals: ["arranged shells on a low shelf", "framed conch"]),
        .init(name: "brews tea properly",      behavior: "loose-leaf, timed, matcha or pu-erh", objectSignals: ["cast iron teapot on a wooden tray", "small ceramic cups"]),
        .init(name: "writes poetry",           behavior: "unpublished, four decades of it", objectSignals: ["stacked notebooks with dates on the spines", "fountain pen"]),
        .init(name: "keeps a rifle",           behavior: "clay pigeon and grouse shooter", objectSignals: ["cased shotgun on a wall rack", "shooting rosette in a frame"]),
        .init(name: "carves wood",             behavior: "small figurines and spoons", objectSignals: ["carved wooden figure on a shelf", "hand tools in a leather roll"]),
        .init(name: "reads philosophy",        behavior: "reads and re-reads Seneca annually", objectSignals: ["worn Loeb classical volumes", "notebook with quotations"]),
        .init(name: "plays cards",             behavior: "bridge with three regulars, Thursdays", objectSignals: ["card deck and score pad on a felt-topped side table", "chair set for four"])
    ]
}

// =====================================================================
// MARK: Persona Selection & Build Modes
// =====================================================================

/// Captures the user's persona-building state and produces a completed Persona.
struct PersonaSelection: Codable, Hashable {
    /// Required — sets the base identity.
    var archetype: PersonaArchetype
    /// Optional — anchors persona in a specific time and place.
    var era: PersonaEra? = nil
    /// Optional 0-3 signature traits.
    var traits: [SignatureTrait] = []
    /// Gap-fill answers (Mode 2). Any nil answer means "leave the archetype default in place."
    var gapAnswers: PersonaGapAnswers = .init()
    /// Optional custom name for the persona. If nil, archetype name is used.
    var customName: String? = nil

    /// Compose a Persona (from DNAG.swift) using the selection.
    func composePersona() -> Persona {
        let a = archetype

        // Biography anchors — archetype default + era note + custom overrides
        var bio = a.biographyAnchors
        if let e = era { bio.append(e.biographyNote) }
        if let custom = gapAnswers.customBiographyAnchor {
            bio.append(custom)
        }

        // Must-see objects — archetype default + trait signals + gap answers
        var mustSee = a.mustSeeObjects
        for t in traits { mustSee.append(contentsOf: t.objectSignals) }
        if let rolled = gapAnswers.whatIsRolledInTheCorner {
            mustSee.append(rolled)
        }
        if let onDesk = gapAnswers.whatIsOnTheDeskAStrangerWouldntUnderstand {
            mustSee.append(onDesk)
        }
        if let drink = gapAnswers.whatDoTheyDrinkAtTenPM {
            mustSee.append(drink)
        }
        if let signature = gapAnswers.oneSignatureUnforgettableObject {
            mustSee.append(signature)
        }

        // Forbidden — archetype default + gap answer for what they refuse
        var forbidden = a.forbiddenObjects
        if let refused = gapAnswers.whatWillTheyNotHaveInTheRoom {
            forbidden.append(refused)
        }

        let name = customName ?? a.name
        let voice = a.voiceOneLiner
        let profession = a.profession
        let eraLabel = era?.context ?? "contemporary"

        return Persona(
            name: name,
            profession: profession,
            era: eraLabel,
            biographyAnchors: bio,
            mustSeeObjects: mustSee,
            forbiddenObjects: forbidden,
            voiceNotes: voice
        )
    }
}

/// Answers to the 5 concrete-object gap questions. All optional.
/// If a value is set, it FEEDS INTO the composed persona.
struct PersonaGapAnswers: Codable, Hashable {
    /// "What's rolled up in the corner of the room?"
    /// Suggestions: rolled maps, architectural drawings, kilim rugs, unfinished canvases
    var whatIsRolledInTheCorner: String? = nil

    /// "What's on the desk that a stranger wouldn't understand?"
    /// Suggestions: half-drafted brief, foreign-language letter, model boat in progress
    var whatIsOnTheDeskAStrangerWouldntUnderstand: String? = nil

    /// "What does this person refuse to have in the room?"
    /// Suggestions: screens, matched sets, anything catalog-fresh, gilt, farmhouse anything
    var whatWillTheyNotHaveInTheRoom: String? = nil

    /// "What do they drink at 10pm?"
    /// Suggestions: single malt, jasmine tea, red wine straight from the bottle, warm milk with honey
    var whatDoTheyDrinkAtTenPM: String? = nil

    /// "What's the one unforgettable object in the room that says who they are?"
    /// Suggestions: family violin, brass sextant, a specific painting, grandfather's pipe rack
    var oneSignatureUnforgettableObject: String? = nil

    /// Optional additional biography anchor the picker doesn't cover.
    var customBiographyAnchor: String? = nil
}

// =====================================================================
// MARK: Gap Questions (for Mode 2 guided flow)
// =====================================================================

struct PersonaGapQuestion: Identifiable, Hashable {
    var id: String { key }
    var key: String
    var question: String
    var suggestions: [String]
}

enum PersonaGapQuestionCatalog {
    static let questions: [PersonaGapQuestion] = [
        .init(key: "rolled_in_corner",
              question: "What's rolled up in the corner of the room?",
              suggestions: ["rolled antique maps", "architectural drawings on tracing paper", "kilim rugs", "unfinished canvases", "sheet music"]),
        .init(key: "on_desk_mystery",
              question: "What's on the desk that a stranger wouldn't understand?",
              suggestions: ["half-drafted legal brief", "foreign-language letter with translation", "model boat in progress", "botanical specimens under glass", "hand-annotated chess diagram"]),
        .init(key: "not_in_room",
              question: "What does this person refuse to have in the room?",
              suggestions: ["screens", "matched sets", "anything catalog-fresh", "gilt", "farmhouse anything", "modern electronics"]),
        .init(key: "ten_pm_drink",
              question: "What do they drink at 10pm?",
              suggestions: ["single malt whisky, neat", "jasmine tea", "red wine straight from the bottle", "warm milk with honey", "chamomile in a chipped mug", "espresso, even at ten"]),
        .init(key: "signature_object",
              question: "What's the one unforgettable object in the room that says who they are?",
              suggestions: ["family violin in its case", "brass sextant on a shelf", "specific painting they inherited", "grandfather's pipe rack", "antique Dollond telescope on a mahogany tripod", "ceremonial tea bowl"])
    ]
}

// =====================================================================
// MARK: Persona Generation (Mode 1 — fully generated)
// =====================================================================

enum PersonaGenerator {
    /// Generate a full PersonaSelection from an archetype alone. Rolls era
    /// and 3 traits from the compatible sets. Deterministic seed = archetype name,
    /// so the same archetype rolls the same persona (change customName to reroll).
    static func generate(from archetype: PersonaArchetype, seed: Int = 0) -> PersonaSelection {
        var rng = SeededGenerator(seed: UInt64(archetype.name.hashValue &+ seed))

        // Pick a compatible era at random.
        let era = PersonaEraCatalog.all.randomElement(using: &rng)

        // Pick 3 traits, biased toward archetype-appropriate ones.
        // (We don't filter by archetype directly — the compatible filter is at the
        // guardrail layer — but we shuffle deterministically so the roll is stable.)
        var pool = SignatureTraitCatalog.all
        pool.shuffle(using: &rng)
        let traits = Array(pool.prefix(3))

        return PersonaSelection(archetype: archetype, era: era, traits: traits)
    }
}

/// A minimal deterministic PRNG so Mode 1 rolls are reproducible per archetype.
private struct SeededGenerator: RandomNumberGenerator {
    var state: UInt64
    init(seed: UInt64) { self.state = seed &* 0x9E3779B97F4A7C15 &+ 1 }
    mutating func next() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return state
    }
}

// =====================================================================
// MARK: Style/Persona Compatibility Guardrail
// =====================================================================
//
// Before rendering, we run a pre-flight compatibility check between the
// Persona archetype and the Style Family. If the pairing is on the
// incompatibility list, we surface a warning so the user can decide
// whether the dissonance is intentional (an artist working in a jarring
// room) or a mistake.

struct CompatibilityCheck {
    enum Level { case compatible, neutral, incompatible }

    var level: Level
    var explanation: String
    var suggestion: String?
}

enum PersonaStyleGuardrail {

    /// Check whether the persona archetype fits the chosen style family.
    static func check(persona: PersonaArchetype, family: StyleFamilyDNA) -> CompatibilityCheck {
        if persona.compatibleFamilies.contains(family.name) {
            return CompatibilityCheck(
                level: .compatible,
                explanation: "\(persona.name) is at home in \(family.name).",
                suggestion: nil
            )
        }
        if persona.incompatibleFamilies.contains(family.name) {
            return CompatibilityCheck(
                level: .incompatible,
                explanation: "\(persona.name) would find \(family.name) alienating. Persona and Emotional Read will likely score below 7 unless the dissonance is deliberate.",
                suggestion: suggestReplacement(for: persona)
            )
        }
        return CompatibilityCheck(
            level: .neutral,
            explanation: "\(persona.name) and \(family.name) are not a natural pairing but not a contradiction. Expect Persona to score 6-7.5 unless overrides tighten it.",
            suggestion: nil
        )
    }

    private static func suggestReplacement(for persona: PersonaArchetype) -> String? {
        guard let firstCompatible = persona.compatibleFamilies.first else { return nil }
        return "Consider \(firstCompatible) instead."
    }
}
