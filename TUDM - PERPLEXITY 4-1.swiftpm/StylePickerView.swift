import SwiftUI

// MARK: - StylePickerView
//
// The Style side of the composer. User picks:
//   - Family (required)
//   - Muse (optional)
//   - 0-3 Mood Words
//   - free-text overrides (Option C)
//
// The resulting StyleSelection is emitted upward via @Binding.

struct StylePickerView: View {
    @Binding var selection: StyleSelection

    var body: some View {
        List {
            familySection
            museSection
            moodsSection
            overridesSection
            previewSection
        }
        .navigationTitle("Style")
        .navigationBarTitleDisplayMode(.inline)
    }

    // ---- Family ----

    @ViewBuilder
    private var familySection: some View {
        Section {
            NavigationLink {
                StyleFamilyList(selectedFamily: $selection.family)
            } label: {
                HStack {
                    Text("Family")
                        .foregroundStyle(.primary)
                    Spacer()
                    Text(selection.family.name)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }
            Text(selection.family.tagline)
                .font(.footnote)
                .foregroundStyle(.secondary)
        } header: {
            Text("Style Family (required)")
        }
    }

    // ---- Muse ----

    @ViewBuilder
    private var museSection: some View {
        Section {
            NavigationLink {
                DesignerMuseList(selectedMuse: $selection.muse,
                                 familyName: selection.family.name)
            } label: {
                HStack {
                    Text("Muse")
                    Spacer()
                    Text(selection.muse?.name ?? "None")
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            if let m = selection.muse {
                Text(m.signature)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Button(role: .destructive) {
                    selection.muse = nil
                } label: {
                    Label("Clear Muse", systemImage: "xmark.circle")
                }
            }
        } header: {
            Text("Designer Muse (optional)")
        } footer: {
            Text("Muses compatible with the chosen family are shown first.")
                .font(.caption)
        }
    }

    // ---- Moods ----

    @ViewBuilder
    private var moodsSection: some View {
        Section {
            NavigationLink {
                MoodWordList(selectedMoods: $selection.moods)
            } label: {
                HStack {
                    Text("Moods")
                    Spacer()
                    Text(selection.moods.isEmpty
                         ? "None"
                         : selection.moods.map { $0.name }.joined(separator: ", "))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.trailing)
                }
            }
            if !selection.moods.isEmpty {
                Button(role: .destructive) {
                    selection.moods = []
                } label: {
                    Label("Clear Moods", systemImage: "xmark.circle")
                }
            }
        } header: {
            Text("Mood Words (0-3)")
        }
    }

    // ---- Overrides (free-text — Option C) ----

    @ViewBuilder
    private var overridesSection: some View {
        Section {
            OverrideField(label: "Palette accent",
                          value: bindingOverride(\.paletteAccent),
                          placeholder: "e.g. burgundy")
            OverrideField(label: "Wood tone",
                          value: bindingOverride(\.woodTone),
                          placeholder: "e.g. aged walnut")
            OverrideField(label: "Metal",
                          value: bindingOverride(\.metal),
                          placeholder: "e.g. polished brass")
            OverrideField(label: "Daylight",
                          value: bindingOverride(\.daylight),
                          placeholder: "e.g. late golden hour")
            OverrideField(label: "Window dressing",
                          value: bindingOverride(\.windowDressing),
                          placeholder: "e.g. heavy velvet drapes")
            OverrideListField(label: "Add hero pieces",
                              values: bindingOverrideList(\.additionalHeroPieces),
                              placeholder: "one per line")
            OverrideListField(label: "Add textiles",
                              values: bindingOverrideList(\.additionalTextiles),
                              placeholder: "one per line")
            OverrideListField(label: "Add shelf styling",
                              values: bindingOverrideList(\.additionalShelfStyling),
                              placeholder: "one per line")
            OverrideListField(label: "Add avoid list",
                              values: bindingOverrideList(\.additionalAvoid),
                              placeholder: "one per line")
        } header: {
            Text("Style Overrides (free-text)")
        } footer: {
            Text("Any filled field replaces the picker's default for that slot. Empty fields keep the picker choice.")
                .font(.caption)
        }
    }

    // ---- Preview ----

    @ViewBuilder
    private var previewSection: some View {
        Section {
            let dna = selection.composeDNA()
            VStack(alignment: .leading, spacing: 6) {
                Text(dna.name)
                    .font(.headline)
                Text(dna.moodStatement)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            LabeledLine(label: "Palette",
                        value: "\(dna.palette.primary), \(dna.palette.secondary), \(dna.palette.accent)")
            LabeledLine(label: "Wood", value: dna.palette.woodTone)
            LabeledLine(label: "Metal", value: dna.palette.metalFinish)
            LabeledLine(label: "Lighting", value: dna.lighting.timeOfDay)
            LabeledLine(label: "Window", value: dna.windowDressing)
        } header: {
            Text("Composed Style DNA")
        }
    }

    // ---- Override binding helpers ----

    private func bindingOverride(_ keyPath: WritableKeyPath<StyleOverrides, String?>) -> Binding<String> {
        Binding<String>(
            get: { selection.overrides[keyPath: keyPath] ?? "" },
            set: { new in
                let trimmed = new.trimmingCharacters(in: .whitespacesAndNewlines)
                selection.overrides[keyPath: keyPath] = trimmed.isEmpty ? nil : new
            }
        )
    }

    private func bindingOverrideList(_ keyPath: WritableKeyPath<StyleOverrides, [String]?>) -> Binding<String> {
        Binding<String>(
            get: {
                (selection.overrides[keyPath: keyPath] ?? []).joined(separator: "\n")
            },
            set: { new in
                let items = new
                    .split(separator: "\n", omittingEmptySubsequences: true)
                    .map { $0.trimmingCharacters(in: .whitespaces) }
                    .filter { !$0.isEmpty }
                selection.overrides[keyPath: keyPath] = items.isEmpty ? nil : items
            }
        )
    }
}

// MARK: - Family list

private struct StyleFamilyList: View {
    @Binding var selectedFamily: StyleFamily
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            ForEach(StyleFamilyCatalog.all) { family in
                Button {
                    selectedFamily = family
                    dismiss()
                } label: {
                    HStack(alignment: .top, spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(family.name)
                                .foregroundStyle(.primary)
                                .font(.subheadline.weight(.semibold))
                            Text(family.tagline)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if family.name == selectedFamily.name {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.tint)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .navigationTitle("Style Family")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Muse list

private struct DesignerMuseList: View {
    @Binding var selectedMuse: DesignerMuse?
    let familyName: String
    @Environment(\.dismiss) private var dismiss

    private var sorted: [DesignerMuse] {
        let all = DesignerMuseCatalog.all
        let compat = all.filter { $0.compatibleFamilies.contains(familyName) }
        let rest = all.filter { !$0.compatibleFamilies.contains(familyName) }
        return compat + rest
    }

    var body: some View {
        List {
            Section {
                Button {
                    selectedMuse = nil
                    dismiss()
                } label: {
                    HStack {
                        Text("None")
                        Spacer()
                        if selectedMuse == nil {
                            Image(systemName: "checkmark").foregroundStyle(.tint)
                        }
                    }
                }
            }
            Section {
                ForEach(sorted) { muse in
                    Button {
                        selectedMuse = muse
                        dismiss()
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(muse.name)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.primary)
                                if muse.compatibleFamilies.contains(familyName) {
                                    Text("compatible")
                                        .font(.caption2)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(.green.opacity(0.15), in: Capsule())
                                        .foregroundStyle(.green)
                                }
                                Spacer()
                                if selectedMuse?.name == muse.name {
                                    Image(systemName: "checkmark").foregroundStyle(.tint)
                                }
                            }
                            Text(muse.era)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(muse.signature)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 2)
                    }
                }
            } header: {
                Text("All Muses")
            }
        }
        .navigationTitle("Designer Muse")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Mood list

private struct MoodWordList: View {
    @Binding var selectedMoods: [MoodWord]

    var body: some View {
        List {
            Section {
                ForEach(MoodWordCatalog.all) { mood in
                    let isSelected = selectedMoods.contains { $0.name == mood.name }
                    Button {
                        if isSelected {
                            selectedMoods.removeAll { $0.name == mood.name }
                        } else if selectedMoods.count < 3 {
                            selectedMoods.append(mood)
                        }
                    } label: {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(mood.name)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.primary)
                                Text(mood.atmosphere)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if isSelected {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.tint)
                            } else if selectedMoods.count >= 3 {
                                Image(systemName: "lock.circle")
                                    .foregroundStyle(.tertiary)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                    .disabled(!isSelected && selectedMoods.count >= 3)
                }
            } header: {
                Text("Pick up to 3 (currently \(selectedMoods.count)/3)")
            }
        }
        .navigationTitle("Mood Words")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Shared override field helpers

private struct OverrideField: View {
    let label: String
    @Binding var value: String
    let placeholder: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            TextField(placeholder, text: $value, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(1...3)
        }
    }
}

private struct OverrideListField: View {
    let label: String
    @Binding var values: String
    let placeholder: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            TextField(placeholder, text: $values, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(2...6)
        }
    }
}

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
