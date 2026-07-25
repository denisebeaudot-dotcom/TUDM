import SwiftUI

@main
struct InteriorAuthorityApp: App {
    @State private var store: InteriorAuthorityStore
    @State private var manifestSyncFolder = ManifestSyncFolder()
    
    init() {
        let store = InteriorAuthorityStore()
        let sync = ManifestSyncFolder()
        store.manifestSyncFolder = sync
        _store = State(wrappedValue: store)
        _manifestSyncFolder = State(wrappedValue: sync)
    }
    
    var body: some Scene {
        WindowGroup {
            InteriorAuthorityRootView()
                .environment(store)
                .environment(manifestSyncFolder)
        }
    }
}
