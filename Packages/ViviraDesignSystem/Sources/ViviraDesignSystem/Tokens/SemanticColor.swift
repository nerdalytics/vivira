// AccentColor ShapeStyle resolving (viviraTheme, colorScheme) to an asset-catalog colorset.
import SwiftUI

public struct AccentColor: ShapeStyle, Sendable {
    public init() {}

    public func resolve(in environment: EnvironmentValues) -> some ShapeStyle {
        let theme = environment.viviraTheme
        let mode = environment.colorScheme == .dark ? "dark" : "light"
        return Color("accent.\(theme.rawValue).\(mode)", bundle: .module)
    }
}

public extension ShapeStyle where Self == AccentColor {
    static var accent: AccentColor { AccentColor() }
}
