import SwiftUI

struct NavigationRoot: View {
    
    private let currentScreen: AppScreen = .home
    
    @ViewBuilder
    var body: some View {
        
        switch currentScreen {
            
        case .home:
            HomeScreen()
        }
    }
}
