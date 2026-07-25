import SwiftUI

/// Advanced, deliberately hard-to-reach controls for the manifest sync folder.
///
/// Disconnecting the folder is the only action here that undoes user setup, so it is
/// gated behind three separate steps: reveal the section, type the confirmation word,
/// then confirm the dialog.
struct AdvancedSyncSettingsView: View {
    @Environment(ManifestSyncFolder.self) private var syncFolder
    @Environment(\.dismiss) private var dismiss

    private static let confirmationWord = "DELETE"

    @State private var showingDangerZone = false
    @State private var typedConfirmation = ""
    @State private var showingDisconnectConfirmation = false

    private var canDisconnect: Bool {
        typedConfirmation.trimmed.uppercased() == Self.confirmationWord
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    if let path = syncFolder.displayPath {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Folder:")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(path)
                                .font(.footnote)
                                .lineLimit(3)
                                .truncationMode(.middle)
                        }
                    } else {
                        Text("No sync folder is connected.")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Connected Folder")
                } footer: {
                    Text("Syncing writes \(ManifestTxtWriter.filename) into this folder. Nothing in the app or in the folder is ever deleted by a sync.")
                }

                if syncFolder.displayPath != nil {
                    Section {
                        Toggle("Show folder link removal", isOn: $showingDangerZone)

                        if showingDangerZone {
                            Text("Disconnecting makes the app forget which folder to write to. Your projects, rooms, walls, and the \(ManifestTxtWriter.filename) already in the folder are all kept — but automatic syncing stops until you pick the folder again.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)

                            TextField("Type \(Self.confirmationWord) to enable", text: $typedConfirmation)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.characters)

                            Button(role: .destructive) {
                                showingDisconnectConfirmation = true
                            } label: {
                                Label("Disconnect Sync Folder", systemImage: "xmark.circle")
                            }
                            .disabled(!canDisconnect)
                        }
                    } header: {
                        Text("Danger Zone")
                    }
                }
            }
            .navigationTitle("Advanced Sync Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .confirmationDialog(
                "Disconnect the sync folder?",
                isPresented: $showingDisconnectConfirmation,
                titleVisibility: .visible
            ) {
                Button("Disconnect and Stop Syncing", role: .destructive) {
                    syncFolder.clearFolder()
                    typedConfirmation = ""
                    showingDangerZone = false
                    dismiss()
                }
                Button("Keep Syncing", role: .cancel) { }
            } message: {
                Text("The app will forget this folder and stop writing \(ManifestTxtWriter.filename) to it. No files are deleted and no project data is lost. You will have to pick the folder again to resume syncing.")
            }
            .onChange(of: showingDangerZone) { _, isShown in
                if !isShown { typedConfirmation = "" }
            }
        }
    }
}
