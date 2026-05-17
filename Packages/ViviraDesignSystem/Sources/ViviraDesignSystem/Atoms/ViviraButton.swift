// Tinted-accent button atom (.accent role only; other roles ship later).

import SwiftUI

public struct ViviraButton<Label: View>: View {
    public enum Role: Sendable {
        case accent
    }

    private let role: Role
    private let action: () -> Void
    private let label: Label

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isPressed = false

    public init(
        role: Role = .accent,
        action: @escaping () -> Void,
        @ViewBuilder label: () -> Label
    ) {
        self.role = role
        self.action = action
        self.label = label()
    }

    public var body: some View {
        Button(action: action, label: {
            label
                .font(.vivira.bodyBold)
                .lineLimit(1)
                .frame(maxWidth: .infinity, minHeight: 44)
                .padding(.horizontal, .vivira.mdPlus)
                .foregroundStyle(Color.vivira.bg)
                .background(.accent, in: RoundedRectangle(cornerRadius: .vivira.radius.md))
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
            .opacity(configuration.isPressed ? 0.6 : 1.0)
            .animation(reduceMotion ? .none : .easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

public extension ViviraButton where Label == Text {
    init(_ titleKey: LocalizedStringKey, role: Role = .accent, action: @escaping () -> Void) {
        self.init(role: role, action: action) {
            Text(titleKey)
        }
    }
}
