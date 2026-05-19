// Tinted accent button atom (a11y-aware press feedback).

import SwiftUI

public struct ViviraButton<Label: View>: View {
    private let action: () -> Void
    private let label: Label

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(
        action: @escaping () -> Void,
        @ViewBuilder label: () -> Label
    ) {
        self.action = action
        self.label = label()
    }

    public var body: some View {
        Button(action: action, label: {
            label
                .font(.Vivira.bodyBold)
                .lineLimit(1)
                .frame(maxWidth: .infinity, minHeight: 44)
                .padding(.horizontal, .Vivira.mdPlus)
                .foregroundStyle(Color.Vivira.bg)
                .background(.accent, in: RoundedRectangle(cornerRadius: .Vivira.Radius.md))
        })
        .buttonStyle(ViviraButtonStyle(reduceMotion: reduceMotion))
        .accessibilityAddTraits(.isButton)
    }
}

private struct ViviraButtonStyle: ButtonStyle {
    let reduceMotion: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.95 : 1.0)
            .opacity(configuration.isPressed && !reduceMotion ? 0.6 : 1.0)
            .animation(reduceMotion ? .none : .easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

public extension ViviraButton where Label == Text {
    init(_ titleKey: LocalizedStringKey, action: @escaping () -> Void) {
        self.init(action: action) {
            Text(titleKey)
        }
    }
}
