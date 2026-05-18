import SwiftUI

public enum Theme: String, CaseIterable, Codable, Sendable {
    case lumen, pomelo, iris, aqua, magenta

    public var displayName: String {
        switch self {
        case .lumen:   return String(localized: "Lumen")
        case .pomelo:  return String(localized: "Pomelo")
        case .iris:    return String(localized: "Iris")
        case .aqua:    return String(localized: "Aqua")
        case .magenta: return String(localized: "Magenta")
        }
    }
}

extension EnvironmentValues {
    @Entry public var viviraTheme: Theme = .lumen
}
