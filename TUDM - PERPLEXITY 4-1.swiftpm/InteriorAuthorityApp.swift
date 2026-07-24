import SwiftUI

@main
struct InteriorAuthorityApp: App {
    @State private var store = InteriorAuthorityStore()
    
    var body: some Scene {
        WindowGroup {
            InteriorAuthorityRootView()
                .environment(store)
        }
    }
}
