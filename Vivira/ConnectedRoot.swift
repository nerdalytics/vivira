import SwiftUI
import ViviraDesignSystem

struct ConnectedRoot: View {
    @EnvironmentObject private var themeStorage: ThemeStorage
    @EnvironmentObject private var appState: AppState

    var body: some View {
        ScrollView {
            VStack(spacing: .Vivira.md) {
                HeroStatusCard.idle(
                    summary: "✓ Connected · 0 subscriptions",
                    hint: "Add an album to start syncing"
                )

                SubscriptionListPlaceholder()

                AppearanceSection(selection: $themeStorage.current)

                #if DEBUG
                Button {
                    appState.kind = .notConnected
                } label: {
                    Text("Disconnect (debug)")
                        .font(.Vivira.caption)
                        .foregroundStyle(Color.Vivira.faint)
                }
                .padding(.top, .Vivira.md)
                #endif
            }
            .padding(.Vivira.md)
        }
        .background(Color.Vivira.bg.ignoresSafeArea())
    }
}

private struct SubscriptionListPlaceholder: View {
    var body: some View {
        Text("subscription list — Bullet 3")
            .font(.Vivira.caption)
            .foregroundStyle(Color.Vivira.faint)
            .italic()
            .frame(maxWidth: .infinity, minHeight: 80)
            .background(
                RoundedRectangle(cornerRadius: .Vivira.Radius.lg, style: .continuous)
                    .fill(Color.Vivira.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: .Vivira.Radius.lg, style: .continuous)
                    .stroke(style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    .foregroundStyle(Color.Vivira.line)
            )
            .accessibilityHidden(true)
    }
}

private struct AppearanceSection: View {
    @Binding var selection: Theme

    var body: some View {
        VStack(alignment: .leading, spacing: .Vivira.md) {
            Text("Appearance")
                .font(.Vivira.monoLabel)
                .tracking(1.4)
                .textCase(.uppercase)
                .foregroundStyle(Color.Vivira.muted)

            ThemePicker(selection: $selection)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.Vivira.md)
        .background(
            RoundedRectangle(cornerRadius: .Vivira.Radius.lg, style: .continuous)
                .fill(Color.Vivira.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: .Vivira.Radius.lg, style: .continuous)
                .stroke(Color.Vivira.line, lineWidth: 1)
        )
    }
}

#Preview("Connected — Lumen light") {
    ConnectedRoot()
        .environment(\.viviraTheme, .lumen)
        .environmentObject(ThemeStorage())
        .environmentObject({
            let state = AppState()
            state.kind = .connected
            return state
        }())
}
