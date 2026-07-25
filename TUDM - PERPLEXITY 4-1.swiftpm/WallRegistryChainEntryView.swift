import SwiftUI

/// Enter or edit a wall chain directly in the app, validate it, preview the payload, and push it
/// through the existing wall registry proxy flow — no code editing required.
///
/// Two input methods:
/// * paste a chain string (`C1=8in | Z1=43in | ...`) and parse it
/// * edit the segment rows directly (global ID, kind, label, width, height, panel split)
struct WallRegistryChainEntryView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var draft: WallRegistryChainDraft
    @State private var settings = WallRegistryPushSettings()
    @State private var issues: [String] = []
    @State private var didValidate = false
    @State private var parseMessage: ParseMessage?
    @State private var pushError: String?
    @State private var response: WallRegistryPushResponse?
    @State private var isPushing = false
    @State private var showingJSON = false

    init(draft: WallRegistryChainDraft = .wall1Template()) {
        _draft = State(initialValue: draft)
    }

    var body: some View {
        NavigationStack {
            Form {
                identitySection
                chainStringSection
                segmentsSection
                rulesSection
                WallRegistryBackendSection(settings: settings)
                actionsSection

                if let response {
                    WallRegistryResultSection(response: response)
                }
            }
            .navigationTitle("Chain Entry")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    EditButton()
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showingJSON) {
                WallRegistryPayloadPreview(envelope: draft.envelope()) { showingJSON = false }
            }
        }
    }

    // MARK: - Sections

    private var identitySection: some View {
        Section {
            TextField("Room ID (family_room)", text: $draft.roomId)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

            TextField("Wall ID (W1)", text: $draft.wallId)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()

            NumericFieldRow(title: "Expected Total (\(draft.units))", value: $draft.expectedTotalWidth)

            LabeledContent("Segment Total", value: WallRegistryEnvelope.trimmedNumber(draft.calculatedTotalWidth))
                .foregroundStyle(draft.totalMatchesExpected ? Color.primary : Color.red)

            if !draft.totalMatchesExpected {
                Button("Set Expected Total to \(WallRegistryEnvelope.trimmedNumber(draft.calculatedTotalWidth))") {
                    draft.matchExpectedTotalToSegments()
                    invalidateValidation()
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Chain")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                Text(draft.rows.isEmpty ? "No segments" : draft.chainDescription)
                    .font(.system(.caption, design: .monospaced))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.vertical, 2)
        } header: {
            Text("Wall Identity")
        } footer: {
            Text("Measurements are in \(draft.units). The expected total must match the segment total before the proxy accepts the wall.")
        }
    }

    private var chainStringSection: some View {
        Section {
            TextEditor(text: $draft.chainInput)
                .font(.system(.footnote, design: .monospaced))
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .frame(minHeight: 90)

            Button {
                parseChainString()
            } label: {
                Label("Parse Chain String", systemImage: "text.badge.checkmark")
            }

            Button {
                draft.chainInput = draft.chainDescription
                parseMessage = nil
            } label: {
                Label("Copy Current Chain Into Field", systemImage: "arrow.down.doc")
            }
            .disabled(draft.rows.isEmpty)
        } header: {
            Text("Paste / Import Chain")
        } footer: {
            VStack(alignment: .leading, spacing: 4) {
                Text("Paste a chain such as C1=8in | Z1=43in | C2=8in | Z2=12.75in. Separate entries with | ; , or new lines.")
                Text("Optional per entry: height as Z3B=96in x 60in, panel split as Z3B=96in(22/52/22). Widths accept fractions like 12 3/4.")
                Text("Parsing replaces all rows. IDs that match the Wall 1 source of truth keep their kind, label, and notes.")
                if let parseMessage {
                    Text(parseMessage.text)
                        .foregroundStyle(parseMessage.isError ? .red : .green)
                }
            }
        }
    }

    private var segmentsSection: some View {
        Section {
            ForEach($draft.rows) { $row in
                ChainRowEditor(row: $row)
            }
            .onDelete { offsets in
                draft.deleteRows(at: offsets)
                invalidateValidation()
            }
            .onMove { source, destination in
                draft.moveRows(from: source, to: destination)
                invalidateValidation()
            }

            Button {
                draft.addRow()
                invalidateValidation()
            } label: {
                Label("Add Segment", systemImage: "plus")
            }
        } header: {
            Text("Segments (\(draft.rows.count))")
        } footer: {
            Text("Order is left to right along the wall. Use Edit to reorder or delete rows.")
        }
    }

    private var rulesSection: some View {
        Section {
            if draft.rules.isEmpty {
                Text("No rules attached.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(Array(draft.rules.enumerated()), id: \.offset) { item in
                    Text(item.element)
                        .font(.caption)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        } header: {
            Text("Locked Rules")
        } footer: {
            WallRegistryLockedRulesFooter()
        }
    }

    private var actionsSection: some View {
        Section {
            Button {
                draft.loadWall1Template()
                parseMessage = nil
                invalidateValidation()
            } label: {
                Label("Load Wall 1 Template", systemImage: "square.stack.3d.up")
            }

            Button {
                validate()
            } label: {
                Label("Validate Chain", systemImage: "checkmark.seal")
            }

            Button {
                showingJSON = true
            } label: {
                Label("Preview Payload", systemImage: "curlybraces")
            }

            Button {
                Task { await push() }
            } label: {
                HStack {
                    Label("Send to Perplexity", systemImage: "paperplane.fill")
                    if isPushing {
                        Spacer()
                        ProgressView()
                    }
                }
            }
            .disabled(isPushing)
        } footer: {
            VStack(alignment: .leading, spacing: 4) {
                if !issues.isEmpty {
                    ForEach(Array(issues.enumerated()), id: \.offset) { item in
                        Text(item.element)
                            .foregroundStyle(.red)
                    }
                } else if didValidate {
                    Text("Chain validates. Segments add up to the expected total.")
                        .foregroundStyle(.green)
                }

                if let pushError {
                    Text(pushError)
                        .foregroundStyle(.red)
                }
            }
        }
    }

    // MARK: - Actions

    private func invalidateValidation() {
        didValidate = false
        issues = []
        pushError = nil
    }

    private func parseChainString() {
        do {
            try draft.applyChainString()
            parseMessage = ParseMessage(
                text: "Parsed \(draft.rows.count) segment\(draft.rows.count == 1 ? "" : "s").",
                isError: false
            )
            invalidateValidation()
        } catch {
            parseMessage = ParseMessage(text: error.localizedDescription, isError: true)
        }
    }

    @discardableResult
    private func validate() -> [String] {
        didValidate = true
        pushError = nil
        issues = draft.validationIssues
        return issues
    }

    private func push() async {
        isPushing = true
        defer { isPushing = false }

        guard validate().isEmpty else { return }
        response = nil

        do {
            let endpoint = try settings.resolvedEndpoint()
            let client = WallRegistryPushClient(endpoint: endpoint, pushToken: settings.pushToken)
            response = try await client.validateAndPush(draft.envelope())
        } catch {
            pushError = error.localizedDescription
        }
    }

    private struct ParseMessage {
        var text: String
        var isError: Bool
    }
}

/// One editable segment row: global ID, kind, label, width, optional height, optional panel split.
private struct ChainRowEditor: View {
    @Binding var row: WallRegistryChainDraft.Row

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                TextField("ID", text: $row.globalId)
                    .font(.system(.body, design: .monospaced))
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .frame(maxWidth: 90)

                Picker("Kind", selection: $row.kind) {
                    ForEach(WallRegistryEnvelope.WallSegmentKind.allCases, id: \.self) { kind in
                        Text(kind.displayName).tag(kind)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()

                Spacer(minLength: 0)
            }

            TextField("Label / description", text: $row.label)
                .font(.subheadline)

            HStack(alignment: .top, spacing: 16) {
                measurementField("Width", text: $row.widthText)
                measurementField("Height (optional)", text: $row.heightText)
            }

            measurementField("Panel split (22 / 52 / 22)", text: $row.panelSplitText)

            TextField("Notes (optional)", text: $row.notes, axis: .vertical)
                .font(.footnote)

            if let issue {
                Text(issue)
                    .font(.caption2)
                    .foregroundStyle(.red)
            }
        }
        .padding(.vertical, 4)
    }

    private func measurementField(_ title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.tertiary)
            TextField(title, text: text)
                .font(.system(.footnote, design: .monospaced))
                .keyboardType(.numbersAndPunctuation)
                .autocorrectionDisabled()
        }
    }

    /// Inline feedback while typing. A completely blank row stays quiet until it has content.
    private var issue: String? {
        let number = WallRegistryEnvelope.trimmedNumber
        let isBlank = row.globalId.trimmed.isEmpty
            && row.label.trimmed.isEmpty
            && row.widthText.trimmed.isEmpty
        if isBlank { return nil }

        if row.globalId.trimmed.isEmpty {
            return "Needs a global ID, continuous with the rest of the room."
        }
        guard let width = row.parsedWidth, width > 0 else {
            return "Width must be a positive measurement, e.g. 12 3/4."
        }
        if row.hasInvalidPanelSplit {
            return "Panel split must be measurements separated by / — e.g. 22 / 52 / 22."
        }
        if let panelSplit = row.parsedPanelSplit {
            let panelTotal = panelSplit.reduce(0, +)
            if abs(panelTotal - width) > WallRegistryChainDraft.tolerance {
                return "Panel split totals \(number(panelTotal)) but this segment is \(number(width)) wide."
            }
        }
        if !row.heightText.trimmed.isEmpty, row.parsedHeight == nil {
            return "Height must be a measurement or left empty."
        }
        return nil
    }
}
