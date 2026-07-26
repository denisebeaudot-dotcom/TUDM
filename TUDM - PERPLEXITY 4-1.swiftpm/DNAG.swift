import Foundation

// MARK: - DNAG v2
//
// DNAG (Denise's Numeric Assessment Grid) is a twelve-category rubric
// for auditing photoreal renders. Every render gets scored on the same
// twelve axes, weighted, summed to a /100. Below-threshold categories
// generate prioritized remedies that feed straight back into the next
// prompt.
//
// The critical DNAG insight: a great render belongs to a person, not
// a style family. A rubric that only measures "is this room Boho?"
// misses the gap between "Gentleman's Library" and "Alistair
// Pembroke's library." DNAG measures persona, biography, surprise,
// and tension alongside structure and palette, so the audit catches
// the difference.
//
// This file defines:
//   - DNAGCategory: the twelve axes
//   - DNAGScore: a single category rating with weight and remedy text
//   - DNAGAudit: a full render evaluation (12 scores + overall + verdict)
//   - Persona: the character the room supposedly belongs to (name,
//     profession, era, biography anchors, must-see objects)
//   - DNAGPatchGenerator: turns a completed audit into a prioritized
//     patch that gets appended to the next render prompt

// MARK: - Categories

enum DNAGCategory: String, Codable, CaseIterable, Identifiable {
    case structure          = "Structure Authority"
    case persona            = "Persona"
    case shelfBiography     = "Shelf Biography"
    case furnitureLanguage  = "Furniture Language"
    case coffeeTable        = "Coffee Table"
    case materialStory      = "Material Story"
    case lighting           = "Lighting"
    case palette            = "Palette"
    case composition        = "Composition"
    case emotionalRead      = "Emotional Read"
    case surprise           = "Surprise"
    case tension            = "Tension"
    
    var id: String { rawValue }
    
    /// Weight in the /100 overall score. Weights reflect DNAG's opinion
    /// that structure is non-negotiable but persona and surprise are
    /// what separate a great render from a magazine cliche.
    var weight: Double {
        switch self {
        case .structure:         return 12
        case .persona:           return 12
        case .shelfBiography:    return 10
        case .furnitureLanguage: return 8
        case .coffeeTable:       return 6
        case .materialStory:     return 8
        case .lighting:          return 8
        case .palette:           return 8
        case .composition:       return 8
        case .emotionalRead:     return 8
        case .surprise:          return 6
        case .tension:           return 6
        }
        // Weights sum to 100.
    }
    
    /// What a passing score in this category looks like. Used as the
    /// rubric text in the audit prompt.
    var rubric: String {
        switch self {
        case .structure:
            return "Four columns read correctly and are equal width. Beam continuous. Shelves per bay = 5. Window 22/52/22. Sill 20in AFF, head 80in AFF. Camera orthographic."
        case .persona:
            return "The room belongs unmistakably to the named persona, not a style family. Their profession, era, and biography are visible."
        case .shelfBiography:
            return "Shelves feel collected, not styled. Uneven book depths, horizontal stacks, breathing gaps, heirloom objects, working papers, one or two awkward pieces."
        case .furnitureLanguage:
            return "Furniture is asymmetric in silhouette and pedigree. At least one heirloom-quality piece with real provenance."
        case .coffeeTable:
            return "Coffee table styling tells a story: current reading, working papers, decanter or drink, an off-center rotation, breathing room."
        case .materialStory:
            return "At least six distinct material families in play (wood, metal, textile, stone, ceramic, paper, wax, horn, leather, glass). Contrast, not harmony."
        case .lighting:
            return "Bright enough to read every detail. Daylight dominates. Interior fixtures complement, not compete. Nothing disappears into shadow."
        case .palette:
            return "Palette holds. No color drift. Every non-hero color earns its place."
        case .composition:
            return "Invisible asymmetry. The eye does not read left=right. Weight is deliberately unbalanced."
        case .emotionalRead:
            return "The viewer thinks 'I know who lives here,' not just 'I'd like to sit here.'"
        case .surprise:
            return "One unforgettable object that makes the viewer stop. Campaign chest, sextant, telescope, dispatch case, carved walking stick, etc."
        case .tension:
            return "At least one intentional friction: fine beside rough, polished beside scarred, formal beside working. Depth through contradiction."
        }
    }
    
    /// A short prompt hint used when the category scores below its
    /// remedy threshold.
    var remedyHint: String {
        switch self {
        case .structure:
            return "Regenerate against the mask exactly. Do not accept structural drift."
        case .persona:
            return "Add explicit persona anchors: profession, era, one biographical detail visible in the room."
        case .shelfBiography:
            return "Introduce uneven book depths, horizontal stacks, breathing gaps, working papers, and one awkward heirloom."
        case .furnitureLanguage:
            return "Replace one piece with a specific antique or heirloom that has real provenance."
        case .coffeeTable:
            return "Rotate the tray off-axis and push the whole grouping toward one side. Add working evidence (reading in progress, drink, papers)."
        case .materialStory:
            return "Add two material families currently missing (candidates: stone, horn, silver, paper, wax, unglazed ceramic)."
        case .lighting:
            return "Increase daylight contribution. Ensure every corner reads. Keep lamps warm but subordinate."
        case .palette:
            return "Tighten palette. Remove any color not in the DNA's palette block."
        case .composition:
            return "Break left=right symmetry by 20 percent. Move furnishings off the vertical centerline."
        case .emotionalRead:
            return "Add one detail that only the persona would own — inscribed book, framed photograph, a working tool of the trade."
        case .surprise:
            return "Introduce exactly ONE unforgettable heirloom object. Not two. One."
        case .tension:
            return "Place one polished piece directly beside one scarred or rough piece. Fine + weathered creates the friction."
        }
    }
}

// MARK: - Per-category score

struct DNAGScore: Codable, Hashable, Identifiable {
    var id: UUID = UUID()
    var category: DNAGCategory
    /// Raw score on the DNAG 0-10 scale (halves allowed, e.g. 9.5).
    var score: Double
    /// The auditor's short prose commentary — what passed, what missed.
    var notes: String
    
    /// True if this category is under the remedy threshold and should
    /// generate a patch line.
    var needsRemedy: Bool { score < 7.5 }
    
    /// This category's contribution to the /100 overall.
    var weightedContribution: Double {
        return (score / 10.0) * category.weight
    }
}

// MARK: - Persona

/// A Persona is the character the render supposedly belongs to. Every
/// DNAG-audited render should target a named persona so the audit can
/// measure biography and emotional read against a real reference.
struct Persona: Codable, Hashable, Identifiable {
    var id: UUID = UUID()
    var name: String                  // "Alistair Pembroke"
    var profession: String            // "Retired King's Counsel"
    var era: String                   // "1970s-2020s, London and country"
    var biographyAnchors: [String]    // "map collector", "historian", "traveller"
    var mustSeeObjects: [String]      // "campaign chest", "worn leather dispatch case"
    var forbiddenObjects: [String]    // "modern electronics", "IKEA-adjacent items"
    var voiceNotes: String            // one paragraph on the person's inner life
    
    var promptBlock: String {
        var lines: [String] = []
        lines.append("PERSONA: \(name)")
        lines.append("Profession: \(profession)")
        lines.append("Era: \(era)")
        if !biographyAnchors.isEmpty {
            lines.append("Biography anchors (must be visible in the room):")
            for a in biographyAnchors { lines.append("  - \(a)") }
        }
        if !mustSeeObjects.isEmpty {
            lines.append("Must-see objects (at least one prominently placed):")
            for o in mustSeeObjects { lines.append("  - \(o)") }
        }
        if !forbiddenObjects.isEmpty {
            lines.append("Forbidden objects (never appear):")
            for o in forbiddenObjects { lines.append("  - \(o)") }
        }
        if !voiceNotes.isEmpty {
            lines.append("Voice: \(voiceNotes)")
        }
        return lines.joined(separator: "\n")
    }
}

// MARK: - Persona library

enum PersonaLibrary {
    static let alistairPembroke = Persona(
        name: "Alistair Pembroke",
        profession: "Retired King's Counsel, historian, map collector",
        era: "1960s-2020s, London and country",
        biographyAnchors: [
            "half-century legal career",
            "map collector",
            "amateur historian",
            "quiet traveller (India, Egypt, the Levant)",
            "keeps a working desk, not a decorative one"
        ],
        mustSeeObjects: [
            "at least two rolled maps (map tube or leaning against a bay)",
            "leather legal folios or dispatch box",
            "aged globe on a stand",
            "framed hound portrait or landscape",
            "worn Persian or Turkish rug"
        ],
        forbiddenObjects: [
            "any modern electronics",
            "anything catalog-fresh or unblemished",
            "matched sets",
            "shiny brass with no patina"
        ],
        voiceNotes: "Alistair reads late, drinks single-malt, and considers a room finished only when the books stop lining up straight."
    )
    
    static let all: [Persona] = [alistairPembroke]
}

// MARK: - Full audit

struct DNAGAudit: Codable, Hashable, Identifiable {
    var id: UUID = UUID()
    var renderName: String              // "Wall 1 - Gentleman's Library v5"
    var personaName: String             // "Alistair Pembroke"
    var dateISO8601: String             // audit timestamp
    var scores: [DNAGScore]             // twelve entries in category order
    var biggestWeakness: String         // one-paragraph summary
    var verdict: String                 // final take
    
    var overallScore: Double {
        let total = scores.reduce(0.0) { $0 + $1.weightedContribution }
        return (total * 10).rounded() / 10  // one decimal
    }
    
    var overallLabel: String {
        return "\(Int(overallScore.rounded()))/100"
    }
    
    /// Categories under the remedy threshold, ordered by biggest deficit
    /// first (weighted, so a low structure score outranks a low surprise).
    var remedyCategories: [DNAGScore] {
        return scores
            .filter { $0.needsRemedy }
            .sorted { a, b in
                let gapA = ((7.5 - a.score) * a.category.weight)
                let gapB = ((7.5 - b.score) * b.category.weight)
                return gapA > gapB
            }
    }
    
    /// Print-ready audit report matching the DNAG v2 format.
    var report: String {
        var lines: [String] = []
        lines.append("DNAG v2 — Brutal Audit")
        lines.append("")
        lines.append("Render:  \(renderName)")
        lines.append("Persona: \(personaName)")
        lines.append("Date:    \(dateISO8601)")
        lines.append("")
        lines.append("Overall DNAG: \(overallLabel)")
        lines.append("")
        for (i, s) in scores.enumerated() {
            lines.append("\(i + 1). \(s.category.rawValue)")
            lines.append("   \(formatScore(s.score))/10  (weight \(Int(s.category.weight)))")
            lines.append("   \(s.notes)")
            lines.append("")
        }
        lines.append("Biggest Remaining Weakness")
        lines.append(biggestWeakness)
        lines.append("")
        lines.append("Verdict")
        lines.append(verdict)
        lines.append("")
        lines.append("Category                       Score")
        for s in scores {
            let name = s.category.rawValue.padding(toLength: 30, withPad: " ", startingAt: 0)
            lines.append("\(name) \(formatScore(s.score))")
        }
        lines.append("")
        lines.append("Overall: \(overallLabel)")
        return lines.joined(separator: "\n")
    }
    
    private func formatScore(_ v: Double) -> String {
        if v == v.rounded() {
            return String(format: "%.0f", v)
        }
        return String(format: "%.1f", v)
    }
}

// MARK: - Patch generator

/// Turns a completed DNAGAudit into a prioritized patch block that gets
/// appended to the next render prompt. The patch is ordered by
/// weighted deficit, so structural fixes come first and surprise/
/// tension come last.
enum DNAGPatchGenerator {
    
    /// Priority label based on how far below the threshold the score is.
    private static func priority(for score: DNAGScore) -> String {
        let gap = 7.5 - score.score
        let weighted = gap * score.category.weight
        if weighted >= 30 { return "Priority 1 — CRITICAL" }
        if weighted >= 15 { return "Priority 2" }
        if weighted >= 8  { return "Priority 3" }
        return "Priority 4"
    }
    
    static func patchBlock(for audit: DNAGAudit) -> String {
        var lines: [String] = []
        lines.append("SURGICAL REMEDY PATCH — derived from DNAG \(audit.overallLabel)")
        lines.append("")
        lines.append("Hard rules:")
        lines.append("  - Keep the approved Style DNA unchanged.")
        lines.append("  - Keep the Persona unchanged.")
        lines.append("  - Keep every category that scored 7.5 or higher unchanged.")
        lines.append("  - Correct only the failing categories, in priority order.")
        lines.append("  - Re-audit automatically after the new render.")
        lines.append("")
        
        let remedies = audit.remedyCategories
        if remedies.isEmpty {
            lines.append("No remedies. Render passed all DNAG thresholds.")
            return lines.joined(separator: "\n")
        }
        
        for (i, s) in remedies.enumerated() {
            lines.append("\(priority(for: s))")
            lines.append("Category: \(s.category.rawValue)  (scored \(s.score)/10, weight \(Int(s.category.weight)))")
            lines.append("Frozen: keep every element in this category that already worked; only the failure below moves.")
            lines.append("Auditor notes: \(s.notes)")
            lines.append("Change: \(s.category.remedyHint)")
            lines.append("Success criterion: \(s.category.rawValue) reaches 8+ on the next audit.")
            if i < remedies.count - 1 {
                lines.append("")
            }
        }
        
        // Frozen list — every category that passed. The other half of
        // the surgical patch: telling the renderer what NOT to touch.
        let frozen = audit.scores.filter { !$0.needsRemedy }
        if !frozen.isEmpty {
            lines.append("")
            lines.append("FROZEN CATEGORIES (do not touch on next render):")
            for s in frozen {
                lines.append("  - \(s.category.rawValue) — scored \(s.score)/10")
            }
        }
        
        lines.append("")
        lines.append("Awaiting approval. Send 'Patch and regenerate' to apply this patch.")
        return lines.joined(separator: "\n")
    }
}

// MARK: - Audit prompt (for auto-audit via image model)

/// The prompt the app sends to the image-comprehension model to
/// generate a DNAG audit automatically. The model gets the rendered
/// image, the mask, the Style DNA, and the Persona, and returns a
/// structured audit that can be parsed into a DNAGAudit.
enum DNAGAuditPromptBuilder {
    
    static func buildAuditPrompt(
        renderName: String,
        persona: Persona,
        styleDNAName: String
    ) -> String {
        var lines: [String] = []
        lines.append("You are a brutal, opinionated interior design director")
        lines.append("performing a DNAG v2 audit on the attached render.")
        lines.append("")
        lines.append("Render name: \(renderName)")
        lines.append("Persona:     \(persona.name) — \(persona.profession)")
        lines.append("Style DNA:   \(styleDNAName)")
        lines.append("")
        lines.append("Score every category below on a 0-10 scale (halves allowed).")
        lines.append("A 10 means the category could not be better. A 7 means")
        lines.append("acceptable but not remarkable. Below 7 needs remedy.")
        lines.append("")
        lines.append("Be brutal. Do not inflate scores to be kind. If the")
        lines.append("render is beautiful but generic, persona and surprise")
        lines.append("should score low even if palette and lighting are 9s.")
        lines.append("")
        lines.append("For each category, give:")
        lines.append("  - the numeric score")
        lines.append("  - 2-4 sentences of specific evidence from the render")
        lines.append("")
        lines.append("Categories (with rubric):")
        lines.append("")
        for (i, cat) in DNAGCategory.allCases.enumerated() {
            lines.append("\(i + 1). \(cat.rawValue) (weight \(Int(cat.weight)))")
            lines.append("   \(cat.rubric)")
            lines.append("")
        }
        lines.append("After the twelve category scores, write:")
        lines.append("  - Biggest Remaining Weakness (one paragraph)")
        lines.append("  - Verdict (2-3 sentences)")
        lines.append("")
        lines.append("Format:")
        lines.append("")
        lines.append("DNAG v2 — Brutal Audit")
        lines.append("Render:  <name>")
        lines.append("Persona: \(persona.name)")
        lines.append("Overall DNAG: <computed>/100")
        lines.append("")
        lines.append("1. Structure Authority")
        lines.append("   <score>/10")
        lines.append("   <notes>")
        lines.append("")
        lines.append("... etc for all twelve ...")
        lines.append("")
        lines.append("Biggest Remaining Weakness")
        lines.append("<paragraph>")
        lines.append("")
        lines.append("Verdict")
        lines.append("<paragraph>")
        return lines.joined(separator: "\n")
    }
}
