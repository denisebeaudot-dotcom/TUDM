import SwiftUI
import Observation

@main
struct MyApp: App {
    
    @State
    private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
        }
    }
}

