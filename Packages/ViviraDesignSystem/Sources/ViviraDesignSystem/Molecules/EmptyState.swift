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
            Spacer(minLength: .Vivira.xxxl)

            Icon(symbol: symbol, size: 48)
                .foregroundStyle(Color.Vivira.faint)

            Spacer().frame(height: .Vivira.lg)

            Text(message)
                .font(.Vivira.body)
                .foregroundStyle(Color.Vivira.ink2)
                .multilineTextAlignment(.center)

            Spacer().frame(height: .Vivira.xl)

            ViviraButton(ctaLabel, action: action)
                .padding(.horizontal, .Vivira.md)

            Spacer(minLength: .Vivira.xxxl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
