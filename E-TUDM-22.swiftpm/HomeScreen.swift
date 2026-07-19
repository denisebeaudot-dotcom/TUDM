import SwiftUI
import UniformTypeIdentifiers

struct HomeScreen: View {

    @Environment(AppState.self)
    private var appState

    @State
    private var isExporting = false

    @State
    private var isImporting = false

    @State
    private var exportDocument = AuthorityJSONDocument()

    @State
    private var statusMessage = ""

    var body: some View {

        NavigationStack {

            VStack(alignment: .leading, spacing: 24) {

                Text("TUDM")
                    .font(.largeTitle)
                    .bold()

                Text("Projects")
                    .font(.title2)
                    .bold()

                NavigationLink("➕ New Project") {
                    ProjectCreateScreen()
                }
                .buttonStyle(.borderedProminent)

                HStack {

                    Button("Export JSON") {
                        exportDocument = AuthorityJSONDocument(
                            data: AuthorityJSONStore.exportData()
                        )
                        isExporting = true
                    }

                    Button("Import JSON") {
                        isImporting = true
                    }
                }
                .buttonStyle(.bordered)

                if !statusMessage.isEmpty {

                    Text(statusMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Divider()

                Text("Recent Projects")
                    .font(.headline)

                List {

                    if appState.projects.isEmpty {

                        Text("No projects yet")

                    } else {

                        ForEach(appState.projects) { project in

                            NavigationLink {

                                ProjectWorkspace(project: project)

                            } label: {

                                Text(project.name)
                            }
                        }
                    }
                }
            }
            .padding()
            .navigationTitle("Dashboard")
            .fileExporter(
                isPresented: $isExporting,
                document: exportDocument,
                contentType: .json,
                defaultFilename: "project-authority"
            ) { result in

                switch result {

                case .success:
                    statusMessage = "JSON exported."

                case .failure(let error):
                    statusMessage = "Export failed: \(error.localizedDescription)"
                }
            }
            .fileImporter(
                isPresented: $isImporting,
                allowedContentTypes: [.json],
                allowsMultipleSelection: false
            ) { result in

                do {

                    let urls = try result.get()

                    guard let url = urls.first else {
                        return
                    }

                    let accessGranted = url.startAccessingSecurityScopedResource()
                    defer {
                        if accessGranted {
                            url.stopAccessingSecurityScopedResource()
                        }
                    }

                    let data = try Data(contentsOf: url)
                    try AuthorityJSONStore.importData(data)
                    appState.reloadFromJSON()
                    statusMessage = "JSON imported."

                } catch {

                    statusMessage = "Import failed: \(error.localizedDescription)"
                }
            }
        }
    }
}
