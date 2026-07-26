import SwiftUI

// MARK: - PersonaPickerView
//
// Three build modes:
//   Mode 1 — Generated:  pick archetype only, roll era + 3 traits
//   Mode 2 — Guided:     pick archetype + answer 5 gap questions
//   Mode 3 — Manual:     write the full persona free-text
//
// Output is a PersonaSelection bound upward, which .composePersona()
// turns into a DNAG Persona.

enum PersonaBuildMode: String, CaseIterable, Identifiable {
    case generated = "Generated"
    case guided = "Guided"
    case manual = "Manual"
    var id: String { rawValue }
}

struct PersonaPickerView: View {
    @Binding var selection: PersonaSelection
    @Binding var mode: PersonaBuildMode
    @Binding var manualBlock: String

    /// Seed we bump when the user taps "reroll" in Generated mode.
    @State private var rerollSeed: Int = 0

    var body: some View {
        List {
            modeSection
            switch mode {
            case .generated:
                archetypeSection(showControls: true)
                generatedResultSection
            case .guided:
                archetypeSection(showControls: true)
                eraSection
                traitsSection
                gapQuestionsSection
                customNameSection
                previewSection
            case .manual:
                manualSection
            }
        }
        .navigationTitle("Persona")
        .navigationBarTitleDisplayMode(.inline)
    }

    // ---- Mode picker ----

    @ViewBuilder
    private var modeSection: some View {
        Section {
            Picker("Build Mode", selection: $mode) {
                ForEach(PersonaBuildMode.allCases) { m in
                    Text(m.rawValue).tag(m)
                }
            }
            .pickerStyle(.segmented)
            modeExplanation
        } header: {
            Text("Persona Build Mode")
        }
    }

    @ViewBuilder
    private var modeExplanation: some View {
        switch mode {
        case .generated:
            Text("Pick an archetype and the system rolls era and traits deterministically. Tap reroll to change the roll.")
                .font(.caption)
                .foregroundStyle(.secondary)
        case .guided:
            Text("Pick an archetype, optionally an era, up to 3 traits, and answer the 5 concrete-object gap questions.")
                .font(.caption)
                .foregroundStyle(.secondary)
        case .manual:
            Text("Write the full Persona block yourself. The archetype above is used only as a name if you leave the manual block empty.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // ---- Archetype ----

    @ViewBuilder
    private func archetypeSection(showControls: Bool) -> some View {
        Section {
            NavigationLink {
                PersonaArchetypeList(selectedArchetype: $selection.archetype)
            } label: {
                HStack {
                    Text("Archetype")
                    Spacer()
                    Text(selection.archetype.name)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            Text(selection.archetype.profession)
                .font(.footnote)
                .foregroundStyle(.secondary)
            Text(selection.archetype.voiceOneLiner)
                .font(.footnote)
                .foregroundStyle(.secondary)
        } header: {
            Text("Archetype (required)")
        }
    }

    // ---- Generated mode preview + reroll ----

    @ViewBuilder
    private var generatedResultSection: some View {
        Section {
            let generated = PersonaGenerator.generate(
                from: selection.archetype,
                seed: rerollSeed
            )
            VStack(alignment: .leading, spacing: 8) {
                if let era = generated.era {
                    LabeledLine(label: "Era", value: era.name + " — " + era.context)
                }
                LabeledLine(label: "Traits",
                            value: generated.traits.map { $0.name }.joined(separator: ", "))
                Divider()
                Text("Voice")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(selection.archetype.voiceOneLiner)
                    .font(.footnote)
            }
            Button {
                rerollSeed &+= 1
                // Apply the rolled result to the selection so downstream views see it.
                selection = generated
            } label: {
                Label("Reroll era + traits", systemImage: "die.face.5")
            }
            Button {
                // Freeze the current roll into the selection.
                selection = generated
            } label: {
                Label("Accept this roll", systemImage: "checkmark.seal")
            }
        } header: {
            Text("Generated Persona")
        } footer: {
            Text("Rolls are deterministic per archetype + seed. Tap reroll to bump the seed.")
                .font(.caption)
        }
    }

    // ---- Era ----

    @ViewBuilder
    private var eraSection: some View {
        Section {
            NavigationLink {
                PersonaEraList(selectedEra: $selection.era)
            } label: {
                HStack {
                    Text("Era / Origin")
                    Spacer()
                    Text(selection.era?.name ?? "None")
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            if let e = selection.era {
                Text(e.biographyNote)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Button(role: .destructive) {
                    selection.era = nil
                } label: {
                    Label("Clear Era", systemImage: "xmark.circle")
                }
            }
        } header: {
            Text("Era / Origin (optional)")
        }
    }

    // ---- Traits ----

    @ViewBuilder
    private var traitsSection: some View {
        Section {
            NavigationLink {
                SignatureTraitList(selectedTraits: $selection.traits)
            } label: {
                HStack {
                    Text("Traits")
                    Spacer()
                    Text(selection.traits.isEmpty
                         ? "None"
                         : selection.traits.map { $0.name }.joined(separator: ", "))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.trailing)
                }
            }
            if !selection.traits.isEmpty {
                Button(role: .destructive) {
                    selection.traits = []
                } label: {
                    Label("Clear Traits", systemImage: "xmark.circle")
                }
            }
        } header: {
            Text("Signature Traits (0-3)")
        }
    }

    // ---- Gap Questions ----

    @ViewBuilder
    private var gapQuestionsSection: some View {
        Section {
            ForEach(PersonaGapQuestionCatalog.questions) { q in
                GapQuestionRow(
                    question: q,
                    value: bindingForGap(q.key)
                )
            }
        } header: {
            Text("Gap Questions")
        } footer: {
            Text("Answer any that apply. Answers feed into the Persona's must-see or forbidden objects.")
                .font(.caption)
        }
    }

    // ---- Custom name ----

    @ViewBuilder
    private var customNameSection: some View {
        Section {
            TextField("Custom name (e.g. Alistair Pembroke)",
                      text: Binding(
                        get: { selection.customName ?? "" },
                        set: {
                            let trimmed = $0.trimmingCharacters(in: .whitespaces)
                            selection.customName = trimmed.isEmpty ? nil : $0
                        }
                      ))
                .textFieldStyle(.roundedBorder)
        } header: {
            Text("Custom Name (optional)")
        }
    }

    // ---- Preview ----

    @ViewBuilder
    private var previewSection: some View {
        Section {
            let persona = selection.composePersona()
            VStack(alignment: .leading, spacing: 6) {
                Text(persona.name)
                    .font(.headline)
                Text(persona.profession)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            LabeledLine(label: "Era", value: persona.era)
            if !persona.biographyAnchors.isEmpty {
                LabeledLine(label: "Bio",
                            value: persona.biographyAnchors.joined(separator: "; "))
            }
            if !persona.mustSeeObjects.isEmpty {
                LabeledLine(label: "Must-see",
                            value: persona.mustSeeObjects.joined(separator: "; "))
            }
            if !persona.forbiddenObjects.isEmpty {
                LabeledLine(label: "Forbidden",
                            value: persona.forbiddenObjects.joined(separator: "; "))
            }
            LabeledLine(label: "Voice", value: persona.voiceNotes)
        } header: {
            Text("Composed Persona")
        }
    }

    // ---- Manual mode ----

    @ViewBuilder
    private var manualSection: some View {
        Section {
            TextEditor(text: $manualBlock)
                .frame(minHeight: 260)
                .font(.footnote.monospaced())
                .overlay(alignment: .topLeading) {
                    if manualBlock.isEmpty {
                        Text(Self.manualPlaceholder)
                            .foregroundStyle(.secondary)
                            .font(.footnote.monospaced())
                            .padding(.top, 8)
                            .padding(.leading, 4)
                            .allowsHitTesting(false)
                    }
                }
            Button {
                manualBlock = Self.manualPlaceholder
            } label: {
                Label("Insert Template", systemImage: "doc.text")
            }
        } header: {
            Text("Manual Persona Block")
        } footer: {
            Text("Type the full block. This is what will be pasted verbatim into the recipe.")
                .font(.caption)
        }
    }

    private static let manualPlaceholder: String = """
    Name:               Alistair Pembroke
    Profession:         Retired King's Counsel, historian, map collector
    Era:                1960s-2020s, London and country
    Biography anchors:  half-century legal career; map collector;
                        amateur historian; quiet traveller
    Must-see objects:   rolled maps; leather dispatch box; aged globe;
                        framed hound portrait; worn Persian rug
    Forbidden objects:  modern electronics; catalog-fresh objects;
                        matched sets; shiny brass with no patina
    Voice:              Alistair reads late, drinks single-malt, and
                        considers a room finished only when the books
                        stop lining up straight.
    """

    // ---- Gap binding helper ----

    private func bindingForGap(_ key: String) -> Binding<String> {
        Binding<String>(
            get: {
                switch key {
                case "rolled_in_corner": return selection.gapAnswers.whatIsRolledInTheCorner ?? ""
                case "on_desk_mystery": return selection.gapAnswers.whatIsOnTheDeskAStrangerWouldntUnderstand ?? ""
                case "not_in_room": return selection.gapAnswers.whatWillTheyNotHaveInTheRoom ?? ""
                case "ten_pm_drink": return selection.gapAnswers.whatDoTheyDrinkAtTenPM ?? ""
                case "signature_object": return selection.gapAnswers.oneSignatureUnforgettableObject ?? ""
                default: return ""
                }
            },
            set: { new in
                let trimmed = new.trimmingCharacters(in: .whitespaces)
                let stored: String? = trimmed.isEmpty ? nil : new
                switch key {
                case "rolled_in_corner": selection.gapAnswers.whatIsRolledInTheCorner = stored
                case "on_desk_mystery": selection.gapAnswers.whatIsOnTheDeskAStrangerWouldntUnderstand = stored
                case "not_in_room": selection.gapAnswers.whatWillTheyNotHaveInTheRoom = stored
                case "ten_pm_drink": selection.gapAnswers.whatDoTheyDrinkAtTenPM = stored
                case "signature_object": selection.gapAnswers.oneSignatureUnforgettableObject = stored
                default: break
                }
            }
        )
    }
}

// MARK: - Archetype list

private struct PersonaArchetypeList: View {
    @Binding var selectedArchetype: PersonaArchetype
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            ForEach(PersonaArchetypeCatalog.all) { a in
                Button {
                    selectedArchetype = a
                    dismiss()
                } label: {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(a.name)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.primary)
                            Text(a.profession)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(a.voiceOneLiner)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                        Spacer()
                        if a.name == selectedArchetype.name {
                            Image(systemName: "checkmark").foregroundStyle(.tint)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .navigationTitle("Archetype")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Era list

private struct PersonaEraList: View {
    @Binding var selectedEra: PersonaEra?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            Section {
                Button {
                    selectedEra = nil
                    dismiss()
                } label: {
                    HStack {
                        Text("None")
                        Spacer()
                        if selectedEra == nil {
                            Image(systemName: "checkmark").foregroundStyle(.tint)
                        }
                    }
                }
            }
            Section {
                ForEach(PersonaEraCatalog.all) { e in
                    Button {
                        selectedEra = e
                        dismiss()
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(e.name).font(.subheadline.weight(.semibold))
                                Spacer()
                                if selectedEra?.name == e.name {
                                    Image(systemName: "checkmark").foregroundStyle(.tint)
                                }
                            }
                            Text(e.context)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(e.biographyNote)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        }
        .navigationTitle("Era / Origin")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Trait list

private struct SignatureTraitList: View {
    @Binding var selectedTraits: [SignatureTrait]

    var body: some View {
        List {
            Section {
                ForEach(SignatureTraitCatalog.all) { t in
                    let isSelected = selectedTraits.contains { $0.name == t.name }
                    Button {
                        if isSelected {
                            selectedTraits.removeAll { $0.name == t.name }
                        } else if selectedTraits.count < 3 {
                            selectedTraits.append(t)
                        }
                    } label: {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(t.name)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.primary)
                                Text(t.behavior)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text("adds: " + t.objectSignals.joined(separator: ", "))
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                            Spacer()
                            if isSelected {
                                Image(systemName: "checkmark.circle.fill").foregroundStyle(.tint)
                            } else if selectedTraits.count >= 3 {
                                Image(systemName: "lock.circle").foregroundStyle(.tertiary)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                    .disabled(!isSelected && selectedTraits.count >= 3)
                }
            } header: {
                Text("Pick up to 3 (currently \(selectedTraits.count)/3)")
            }
        }
        .navigationTitle("Signature Traits")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Gap question row

private struct GapQuestionRow: View {
    let question: PersonaGapQuestion
    @Binding var value: String
    @State private var showingSuggestions = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(question.question)
                .font(.footnote.weight(.semibold))
            TextField("Type your answer, or tap for suggestions", text: $value, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(1...4)
            Button {
                showingSuggestions.toggle()
            } label: {
                Label(showingSuggestions ? "Hide suggestions" : "Suggestions",
                      systemImage: showingSuggestions ? "chevron.up" : "chevron.down")
                    .font(.caption)
            }
            if showingSuggestions {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(question.suggestions, id: \.self) { s in
                        Button {
                            value = s
                            showingSuggestions = false
                        } label: {
                            Text("• \(s)")
                                .font(.caption)
                                .foregroundStyle(.tint)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                .padding(.leading, 6)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Shared LabeledLine

private struct LabeledLine: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 84, alignment: .leading)
            Text(value)
                .font(.caption)
                .foregroundStyle(.primary)
            Spacer()
        }
    }
}
