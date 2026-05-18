// Inline theme picker: row of 5 swatch buttons + current-name caption.
// Lives in the Connected root's Appearance section (UX flow §5.3, design system §3.3).
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

public struct ThemePicker: View {
    @Binding private var selection: Theme

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(selection: Binding<Theme>) {
        self._selection = selection
    }

    public var body: some View {
        VStack(spacing: .vivira.sm) {
            HStack(spacing: 0) {
                ForEach(Theme.allCases, id: \.self) { theme in
                    Button {
                        select(theme)
                    } label: {
                        ThemeSwatch(theme: theme, isSelected: theme == selection)
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(theme.displayName)
                }
            }

            Text(selection.displayName)
                .font(.vivira.caption)
                .foregroundStyle(Color.vivira.muted)
        }
    }

    private func select(_ theme: Theme) {
        guard theme != selection else { return }
        selection = theme
        fireHaptic()
    }

    private func fireHaptic() {
        guard !reduceMotion else { return }
        #if canImport(UIKit)
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
        #endif
    }
}
