import SwiftUI

@main
struct InteriorAuthorityApp: App {
    @State private var store: InteriorAuthorityStore
    @State private var manifestSyncFolder = ManifestSyncFolder()
    
    init() {
        // Fail loud on launch if any code-frozen window lock is
        // internally inconsistent. This guards against a bad edit to
        // WindowLockLibrary shipping unnoticed.
        WindowLockLibrary.assertAllSelfConsistent()
        
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
