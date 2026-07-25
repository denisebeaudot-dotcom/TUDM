import SwiftUI

/// Backend proxy endpoint + push token, shared by every screen that can push a registry.
/// Both screens read and write the same `WallRegistryPushSettings`, so the endpoint only
/// has to be entered once on the device.
struct WallRegistryBackendSection: View {
    @Bindable var settings: WallRegistryPushSettings

    var body: some View {
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
        .onChange(of: settings.endpointString) { settings.save() }
        .onChange(of: settings.pushToken) { settings.save() }
    }
}

struct WallRegistryResultSection: View {
    let response: WallRegistryPushResponse

    var body: some View {
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
}

/// Exact JSON the proxy will receive, so the payload can be checked before sending.
struct WallRegistryPayloadPreview: View {
    let envelope: WallRegistryEnvelope
    let onClose: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                Text(Self.json(for: envelope))
                    .font(.system(.caption, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
            .navigationTitle("Payload")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Close", action: onClose)
                }
            }
        }
    }

    static func json(for envelope: WallRegistryEnvelope) -> String {
        guard
            let data = try? WallRegistryPushClient.makeEncoder().encode(envelope),
            let text = String(data: data, encoding: .utf8)
        else {
            return "Unable to encode this registry."
        }
        return text
    }
}

/// The two rules that must survive every edit and every render pass.
struct WallRegistryLockedRulesFooter: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Clear wall returns (Z2 / Z4 style) beside a window unit stay separate locked zones. Never absorb them into the window unit.")
            Text("Global IDs are continuous across the room. Do not restart like-structure IDs on each wall.")
        }
    }
}
