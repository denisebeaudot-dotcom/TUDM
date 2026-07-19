import SwiftUI
import UniformTypeIdentifiers

struct AuthorityJSONDocument: FileDocument {

    static var readableContentTypes: [UTType] {
        [.json]
    }

    var data: Data

    init(
        data: Data = AuthorityJSONStore.exportData()
    ) {
        self.data = data
    }

    init(
        configuration: ReadConfiguration
    ) throws {

        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }

        self.data = data
    }

    func fileWrapper(
        configuration: WriteConfiguration
    ) throws -> FileWrapper {

        FileWrapper(
            regularFileWithContents: data
        )
    }
}
