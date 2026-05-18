// Single 28pt theme-color circle with donut-style selection ring.
// Purely visual; the picker wraps it in a Button for tap handling.
import SwiftUI

public struct ThemeSwatch: View {
    public static let diameter: CGFloat = 28
    public static let ringWidth: CGFloat = 2
    public static let ringGap: CGFloat = 2

    private let theme: Theme
    private let isSelected: Bool

    @Environment(\.colorScheme) private var colorScheme

    public init(theme: Theme, isSelected: Bool) {
        self.theme = theme
        self.isSelected = isSelected
    }

    public var body: some View {
        let fill = swatchColor(theme: theme, colorScheme: colorScheme)

        Circle()
            .fill(fill)
            .frame(width: Self.diameter, height: Self.diameter)
            .overlay(selectionRing)
            .accessibilityElement(children: .ignore)
            .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    @ViewBuilder
    private var selectionRing: some View {
        if isSelected {
            Circle()
                .stroke(Color.vivira.ink, lineWidth: Self.ringWidth)
                .frame(
                    width: Self.diameter + (Self.ringGap + Self.ringWidth) * 2,
                    height: Self.diameter + (Self.ringGap + Self.ringWidth) * 2
                )
        }
    }

    private func swatchColor(theme: Theme, colorScheme: ColorScheme) -> Color {
        let mode = colorScheme == .dark ? "dark" : "light"
        return Color("accent.\(theme.rawValue).\(mode)", bundle: .module)
    }
}
