import SwiftUI
import ViviraDesignSystem

@main
struct ViviraApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.viviraTheme, .lumen)
        }
    }
}
