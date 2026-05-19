import SwiftUI
import ViviraDesignSystem

@main
struct ViviraApp: App {
    @StateObject private var themeStorage = ThemeStorage()
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.viviraTheme, themeStorage.current)
                .environmentObject(themeStorage)
                .environmentObject(appState)
        }
    }
}
