import SwiftUI

/// "Validate Wall" and "Send to Perplexity" for a single wall, plus the current source of truth.
struct WallRegistryPushView: View {
    let wall: WallSpec
    let room: Room

    @Environment(\.dismiss) private var dismiss

    @State private var settings = WallRegistryPushSettings()
    @State private var validationError: String?
    @State private var didValidate = false
    @State private var pushError: String?
    @State private var response: WallRegistryPushResponse?
    @State private var isPushing = false
    @State private var showingJSON = false
    @State private var showingChainEditor = false

    private var envelope: WallRegistryEnvelope {
        WallRegistryBridge.envelope(for: wall, in: room)
    }

    var body: some View {
        NavigationStack {
            Form {
                sourceOfTruthSection
                WallRegistryBackendSection(settings: settings)
                actionsSection

                if let response {
                    WallRegistryResultSection(response: response)
                }
            }
            .navigationTitle("Wall Registry Push")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showingJSON) {
                WallRegistryPayloadPreview(envelope: envelope) { showingJSON = false }
            }
            .sheet(isPresented: $showingChainEditor) {
                WallRegistryChainEntryView(draft: WallRegistryChainDraft(envelope: envelope))
            }
        }
    }

    // MARK: - Sections

    private var sourceOfTruthSection: some View {
        Section {
            let current = envelope
            LabeledContent("Room", value: current.roomId.isEmpty ? "—" : current.roomId)
            LabeledContent("Wall", value: current.wallId.isEmpty ? "—" : current.wallId)
            LabeledContent("Expected Total", value: WallRegistryEnvelope.trimmedNumber(current.expectedTotalWidth))
            LabeledContent("Segment Total", value: WallRegistryEnvelope.trimmedNumber(current.calculatedTotalWidth))
            LabeledContent("Segments", value: "\(current.segments.count)")

            VStack(alignment: .leading, spacing: 2) {
                Text("Chain")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                Text(current.chainDescription.isEmpty ? "No segments" : current.chainDescription)
                    .font(.system(.caption, design: .monospaced))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.vertical, 2)
        } header: {
            Text("Current Source of Truth")
        } footer: {
            WallRegistryLockedRulesFooter()
        }
    }

    private var actionsSection: some View {
        Section {
            Button {
                validate()
            } label: {
                Label("Validate Wall", systemImage: "checkmark.seal")
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

            Button {
                showingJSON = true
            } label: {
                Label("Preview Payload", systemImage: "curlybraces")
            }

            Button {
                showingChainEditor = true
            } label: {
                Label("Edit Chain by Hand…", systemImage: "list.number")
            }
        } footer: {
            if let validationError {
                Text(validationError)
                    .foregroundStyle(.red)
            } else if didValidate {
                Text("Wall validates. Segments add up to the expected total.")
                    .foregroundStyle(.green)
            }

            if let pushError {
                Text(pushError)
                    .foregroundStyle(.red)
            }
        }
    }

    // MARK: - Actions

    private func validate() {
        didValidate = true
        pushError = nil
        do {
            try envelope.validate()
            validationError = nil
        } catch {
            validationError = error.localizedDescription
        }
    }

    private func push() async {
        isPushing = true
        defer { isPushing = false }

        pushError = nil
        response = nil

        do {
            let endpoint = try settings.resolvedEndpoint()
            let client = WallRegistryPushClient(endpoint: endpoint, pushToken: settings.pushToken)
            response = try await client.validateAndPush(envelope)
            validationError = nil
            didValidate = true
        } catch {
            pushError = error.localizedDescription
        }
    }
}
