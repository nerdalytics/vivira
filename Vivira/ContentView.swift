import SwiftUI
import ViviraDesignSystem

struct ContentView: View {
    var body: some View {
        NavigationStack {
            EmptyState(
                symbol: "photo.on.rectangle.angled",
                message: "Vivira keeps Immich shared albums\nin sync with your iPhone.",
                ctaLabel: "Add a server",
                action: { }
            )
            .background(Color.vivira.bg.ignoresSafeArea())
        }
    }
}

#Preview {
    ContentView()
        .environment(\.viviraTheme, .lumen)
}
