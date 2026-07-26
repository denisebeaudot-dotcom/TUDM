import SwiftUI

// MARK: - RenderComposerView
//
// Top-level composer. Holds the Style + Persona selections, runs the
// compatibility guardrail, and emits the merged PART B block ready to
// paste into the ChatGPT recipe.
//
// Persists selections in-memory only for this session; saving to a
// reusable library lives in a later pass.

struct RenderComposerView: View {

    // ---- Style state ----
    @State private var styleSelection: StyleSelection = .init(
        family: StyleFamilyCatalog.gentlemansLibrary
    )

    // ---- Persona state ----
    @State private var personaMode: PersonaBuildMode = .guided
    @State private var personaSelection: PersonaSelection = .init(
        archetype: PersonaArchetypeCatalog.retiredKC
    )
    @State private var manualPersonaBlock: String = ""

    // ---- Output ----
    @State private var showingPromptSheet = false
    @State private var confirmedIncompatible = false

    private var compatibility: CompatibilityCheck {
        PersonaStyleGuardrail.check(
            persona: personaSelection.archetype,
            family: styleSelection.family
        )
    }

    private var canRender: Bool {
        switch compatibility.level {
        case .compatible, .neutral: return true
        case .incompatible:         return confirmedIncompatible
        }
    }

    var body: some View {
        NavigationStack {
            List {
                pickersSection
                guardrailSection
                outputSection
            }
            .navigationTitle("Render Composer")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingPromptSheet) {
                PromptSheet(promptText: composedPrompt())
            }
        }
    }

    // ---- Pickers ----

    @ViewBuilder
    private var pickersSection: some View {
        Section {
            NavigationLink {
                StylePickerView(selection: $styleSelection)
            } label: {
                HStack {
                    Text("Style")
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Text(styleShortLabel)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.trailing)
                }
                .padding(.vertical, 4)
            }
            NavigationLink {
                PersonaPickerView(
                    selection: $personaSelection,
                    mode: $personaMode,
                    manualBlock: $manualPersonaBlock
                )
            } label: {
                HStack {
                    Text("Persona")
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Text(personaShortLabel)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.trailing)
                }
                .padding(.vertical, 4)
            }
        } header: {
            Text("Selections")
        }
    }

    private var styleShortLabel: String {
        var parts: [String] = [styleSelection.family.name]
        if let m = styleSelection.muse { parts.append("x \(m.name)") }
        if !styleSelection.moods.isEmpty {
            parts.append("(" + styleSelection.moods.map { $0.name }.joined(separator: ", ") + ")")
        }
        return parts.joined(separator: " ")
    }

    private var personaShortLabel: String {
        if personaMode == .manual, !manualPersonaBlock.isEmpty {
            return "Manual block set"
        }
        let name = personaSelection.customName ?? personaSelection.archetype.name
        var parts: [String] = [name]
        if let e = personaSelection.era { parts.append("(\(e.name))") }
        return parts.joined(separator: " ")
    }

    // ---- Guardrail ----

    @ViewBuilder
    private var guardrailSection: some View {
        Section {
            HStack(alignment: .top, spacing: 10) {
                guardrailIcon
                VStack(alignment: .leading, spacing: 4) {
                    Text(guardrailTitle)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(guardrailColor)
                    Text(compatibility.explanation)
                        .font(.footnote)
                        .foregroundStyle(.primary)
                    if let s = compatibility.suggestion {
                        Text(s)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
            }
            if compatibility.level == .incompatible {
                Toggle(isOn: $confirmedIncompatible) {
                    Text("Dissonance is deliberate — proceed anyway")
                        .font(.footnote)
                }
            }
        } header: {
            Text("Compatibility Guardrail")
        }
    }

    private var guardrailTitle: String {
        switch compatibility.level {
        case .compatible:   return "Compatible"
        case .neutral:      return "Neutral pairing"
        case .incompatible: return "Incompatible"
        }
    }

    private var guardrailColor: Color {
        switch compatibility.level {
        case .compatible:   return .green
        case .neutral:      return .orange
        case .incompatible: return .red
        }
    }

    @ViewBuilder
    private var guardrailIcon: some View {
        switch compatibility.level {
        case .compatible:
            Image(systemName: "checkmark.seal.fill")
                .foregroundStyle(.green)
                .imageScale(.large)
        case .neutral:
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
                .imageScale(.large)
        case .incompatible:
            Image(systemName: "xmark.octagon.fill")
                .foregroundStyle(.red)
                .imageScale(.large)
        }
    }

    // ---- Output ----

    @ViewBuilder
    private var outputSection: some View {
        Section {
            Button {
                showingPromptSheet = true
            } label: {
                Label("Compose PART B Prompt", systemImage: "doc.on.doc")
            }
            .disabled(!canRender)
            if !canRender {
                Text("Confirm the dissonance is deliberate to enable output.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("Output")
        } footer: {
            Text("Composes the merged Style + Persona block, ready to paste into PART B of the ChatGPT recipe.")
                .font(.caption)
        }
    }

    // ---- Prompt composition ----

    private func composedPrompt() -> String {
        let dna = styleSelection.composeDNA()

        // Persona: if manual mode with content, use verbatim; else compose.
        let personaBlock: String
        if personaMode == .manual, !manualPersonaBlock.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            personaBlock = manualPersonaBlock
        } else {
            personaBlock = personaSelection.composePersona().promptBlock
        }

        var lines: [String] = []
        lines.append(">>> BEGIN PART B >>>")
        lines.append("")
        lines.append("USER PERSONA:")
        lines.append(personaBlock)
        lines.append("")
        lines.append("STYLE DNA:")
        lines.append("Name: \(dna.name)")
        lines.append("Family: \(dna.family)")
        lines.append("Tagline: \(dna.tagline)")
        lines.append("")
        lines.append("Mood: \(dna.moodStatement)")
        lines.append("")
        lines.append("Palette:")
        lines.append("  Primary:   \(dna.palette.primary)")
        lines.append("  Secondary: \(dna.palette.secondary)")
        lines.append("  Accent:    \(dna.palette.accent)")
        lines.append("  Wood:      \(dna.palette.woodTone)")
        lines.append("  Metal:     \(dna.palette.metal)")
        lines.append("")
        lines.append("Materials:")
        lines.append("  Walls:      \(dna.materials.walls)")
        lines.append("  Floor:      \(dna.materials.floor)")
        lines.append("  Upholstery: \(dna.materials.upholstery)")
        if !dna.materials.accentMaterials.isEmpty {
            lines.append("  Accents:    " + dna.materials.accentMaterials.joined(separator: ", "))
        }
        lines.append("")
        lines.append("Lighting:")
        lines.append("  Daylight:  \(dna.lighting.daylight)")
        if !dna.lighting.interiorFixtures.isEmpty {
            lines.append("  Fixtures:  " + dna.lighting.interiorFixtures.joined(separator: ", "))
        }
        lines.append("")
        lines.append("Hero pieces: " + dna.heroPieces.joined(separator: "; "))
        lines.append("Window dressing: \(dna.windowDressing)")
        lines.append("Textiles: " + dna.textiles.joined(separator: "; "))
        lines.append("Shelf styling: " + dna.shelfStyling.joined(separator: "; "))
        lines.append("Avoid: " + dna.avoid.joined(separator: "; "))
        lines.append("Camera: \(dna.cameraNote)")
        lines.append("")
        lines.append("COMPATIBILITY: \(guardrailTitle) — \(compatibility.explanation)")
        lines.append("")
        lines.append("<<< END PART B <<<")
        return lines.joined(separator: "\n")
    }
}

// MARK: - Prompt sheet

private struct PromptSheet: View {
    let promptText: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                Text(promptText)
                    .font(.footnote.monospaced())
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
            .navigationTitle("PART B Prompt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    ShareLink(item: promptText) {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                }
            }
        }
    }
}
