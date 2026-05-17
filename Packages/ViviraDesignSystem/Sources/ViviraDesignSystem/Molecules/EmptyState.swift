// Vertically centered icon + body copy + accent CTA molecule (UX flow §12.1, design system §6.5).
import SwiftUI

public struct EmptyState: View {
    private let symbol: String
    private let message: LocalizedStringKey
    private let ctaLabel: LocalizedStringKey
    private let action: () -> Void

    public init(
        symbol: String,
        message: LocalizedStringKey,
        ctaLabel: LocalizedStringKey,
        action: @escaping () -> Void
    ) {
        self.symbol = symbol
        self.message = message
        self.ctaLabel = ctaLabel
        self.action = action
    }

    public var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: .vivira.xxxl)

            Icon(symbol: symbol, size: 48)
                .foregroundStyle(Color.vivira.faint)

            Spacer().frame(height: .vivira.lg)

            Text(message)
                .font(.vivira.body)
                .foregroundStyle(Color.vivira.ink2)
                .multilineTextAlignment(.center)

            Spacer().frame(height: .vivira.xl)

            ViviraButton(ctaLabel, action: action)
                .padding(.horizontal, .vivira.md)

            Spacer(minLength: .vivira.xxxl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
