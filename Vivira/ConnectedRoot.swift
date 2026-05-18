import SwiftUI
import ViviraDesignSystem

struct ConnectedRoot: View {
    @EnvironmentObject private var themeStorage: ThemeStorage
    @EnvironmentObject private var appState: AppState

    var body: some View {
        ScrollView {
            VStack(spacing: .vivira.md) {
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
                        .font(.vivira.caption)
                        .foregroundStyle(Color.vivira.faint)
                }
                .padding(.top, .vivira.md)
                #endif
            }
            .padding(.vivira.md)
        }
        .background(Color.vivira.bg.ignoresSafeArea())
    }
}

private struct SubscriptionListPlaceholder: View {
    var body: some View {
        Text("subscription list — Bullet 3")
            .font(.vivira.caption)
            .foregroundStyle(Color.vivira.faint)
            .italic()
            .frame(maxWidth: .infinity, minHeight: 80)
            .background(
                RoundedRectangle(cornerRadius: .vivira.radius.lg, style: .continuous)
                    .fill(Color.vivira.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: .vivira.radius.lg, style: .continuous)
                    .stroke(style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    .foregroundStyle(Color.vivira.line)
            )
            .accessibilityHidden(true)
    }
}

private struct AppearanceSection: View {
    @Binding var selection: Theme

    var body: some View {
        VStack(alignment: .leading, spacing: .vivira.md) {
            Text("Appearance")
                .font(.vivira.monoLabel)
                .tracking(1.4)
                .textCase(.uppercase)
                .foregroundStyle(Color.vivira.muted)

            ThemePicker(selection: $selection)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vivira.md)
        .background(
            RoundedRectangle(cornerRadius: .vivira.radius.lg, style: .continuous)
                .fill(Color.vivira.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: .vivira.radius.lg, style: .continuous)
                .stroke(Color.vivira.line, lineWidth: 1)
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
