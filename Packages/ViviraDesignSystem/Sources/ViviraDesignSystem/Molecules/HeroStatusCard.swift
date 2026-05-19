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
        VStack(alignment: .leading, spacing: .Vivira.xs) {
            Text(summary)
                .font(.Vivira.headline)
                .foregroundStyle(Color.Vivira.ink)

            if let hint {
                Text(hint)
                    .font(.Vivira.caption)
                    .foregroundStyle(Color.Vivira.muted)
            }
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
