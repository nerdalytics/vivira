// Hero status card — idle initializer only at Bullet 2 fidelity.
// Active and degraded states land when real transfer state exists.
// Per design system §6.2.
import SwiftUI

public struct HeroStatusCard: View {
    private let summary: LocalizedStringKey
    private let hint: LocalizedStringKey?

    public static func idle(
        summary: LocalizedStringKey,
        hint: LocalizedStringKey? = nil
    ) -> HeroStatusCard {
        HeroStatusCard(summary: summary, hint: hint)
    }

    private init(summary: LocalizedStringKey, hint: LocalizedStringKey?) {
        self.summary = summary
        self.hint = hint
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: .vivira.xs) {
            Text(summary)
                .font(.vivira.headline)
                .foregroundStyle(Color.vivira.ink)

            if let hint {
                Text(hint)
                    .font(.vivira.caption)
                    .foregroundStyle(Color.vivira.muted)
            }
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
