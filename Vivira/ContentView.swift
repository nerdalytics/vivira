import SwiftUI
import ViviraDesignSystem

struct ContentView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        NavigationStack {
            switch appState.kind {
            case .notConnected:
                EmptyState(
                    symbol: "photo.on.rectangle.angled",
                    message: "Vivira keeps Immich shared albums\nin sync with your iPhone.",
                    ctaLabel: "Add a server",
                    action: { appState.kind = .connected }
                )
                .background(Color.vivira.bg.ignoresSafeArea())
            case .connected:
                ConnectedRoot()
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(\.viviraTheme, .lumen)
        .environmentObject(ThemeStorage())
        .environmentObject(AppState())
}
