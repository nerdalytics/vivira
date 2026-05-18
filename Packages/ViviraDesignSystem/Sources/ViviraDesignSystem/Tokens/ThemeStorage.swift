import Foundation
import SwiftUI

@MainActor
public final class ThemeStorage: ObservableObject {
    static let userDefaultsKey = "ViviraDesignSystem.theme"

    @Published public var current: Theme {
        didSet {
            userDefaults.set(current.rawValue, forKey: Self.userDefaultsKey)
        }
    }

    private let userDefaults: UserDefaults

    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        let stored = userDefaults.string(forKey: Self.userDefaultsKey)
        self.current = Theme(rawValue: stored ?? "") ?? .lumen
    }
}
