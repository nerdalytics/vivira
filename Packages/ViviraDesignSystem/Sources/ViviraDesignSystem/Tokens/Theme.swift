// Theme enum and EnvironmentValues.viviraTheme.
import SwiftUI

public enum Theme: String, CaseIterable, Codable, Sendable {
    case lumen, pomelo, iris, aqua, magenta

    public var displayName: String {
        switch self {
        case .lumen:   return String(localized: "Lumen",   bundle: Bundle.module)
        case .pomelo:  return String(localized: "Pomelo",  bundle: Bundle.module)
        case .iris:    return String(localized: "Iris",    bundle: Bundle.module)
        case .aqua:    return String(localized: "Aqua",    bundle: Bundle.module)
        case .magenta: return String(localized: "Magenta", bundle: Bundle.module)
        }
    }
}

extension EnvironmentValues {
    @Entry public var viviraTheme: Theme = .lumen
}
