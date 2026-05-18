import SwiftUI
import ViviraDesignSystem

@main
struct ViviraApp: App {
    @StateObject private var themeStorage = ThemeStorage()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.viviraTheme, themeStorage.current)
                .environmentObject(themeStorage)
        }
    }
}
