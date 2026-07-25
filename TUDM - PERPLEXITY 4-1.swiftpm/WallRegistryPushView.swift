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

    private var envelope: WallRegistryEnvelope {
        WallRegistryBridge.envelope(for: wall, in: room)
    }

    var body: some View {
        NavigationStack {
            Form {
                sourceOfTruthSection
                backendSection
                actionsSection

                if let response {
                    resultSection(response)
                }
            }
            .navigationTitle("Wall Registry Push")
            .onChange(of: settings.endpointString) { settings.save() }
            .onChange(of: settings.pushToken) { settings.save() }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showingJSON) {
                NavigationStack {
                    ScrollView {
                        Text(jsonPreview)
                            .font(.system(.caption, design: .monospaced))
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                    }
                    .navigationTitle("Payload")
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Close") { showingJSON = false }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Sections

    private var sourceOfTruthSection: some View {
        Section("Current Source of Truth") {
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
        }
    }

    private var backendSection: some View {
        Section {
            TextField("https://your-backend.example.com/wall-registry", text: $settings.endpointString)
                .textContentType(.URL)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(.URL)

            SecureField("X-Wall-Push-Token (optional)", text: $settings.pushToken)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
        } header: {
            Text("Backend Proxy")
        } footer: {
            Text("The endpoint and token are stored on this device only, never in Git. The Perplexity API key lives solely in the backend's environment — this app never holds it.")
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

    private func resultSection(_ response: WallRegistryPushResponse) -> some View {
        Section("Last Push") {
            Text(response.message)
            if let totalWidth = response.totalWidth {
                LabeledContent("Stored Total", value: WallRegistryEnvelope.trimmedNumber(totalWidth))
            }
            if let receivedAt = response.receivedAt {
                LabeledContent("Received", value: receivedAt.formatted(date: .abbreviated, time: .standard))
            }
            if let nextAction = response.nextAction, !nextAction.isEmpty {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Next Action")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    Text(nextAction)
                        .font(.caption)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    // MARK: - Actions

    private var jsonPreview: String {
        guard
            let data = try? WallRegistryPushClient.makeEncoder().encode(envelope),
            let text = String(data: data, encoding: .utf8)
        else {
            return "Unable to encode this registry."
        }
        return text
    }

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
