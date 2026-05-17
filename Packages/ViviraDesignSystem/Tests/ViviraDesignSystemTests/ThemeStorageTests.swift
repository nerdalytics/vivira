// ThemeStorage UserDefaults round-trip tests.
import Foundation
import Testing
@testable import ViviraDesignSystem

@MainActor
@Suite struct ThemeStorageTests {

    @Test func defaultsToLumenWhenStorageEmpty() {
        let suite = UserDefaults(suiteName: UUID().uuidString)!
        let storage = ThemeStorage(userDefaults: suite)
        #expect(storage.current == .lumen)
    }

    @Test func writesToUserDefaultsOnSet() {
        let suite = UserDefaults(suiteName: UUID().uuidString)!
        let storage = ThemeStorage(userDefaults: suite)
        storage.current = .iris
        #expect(suite.string(forKey: ThemeStorage.userDefaultsKey) == "iris")
    }

    @Test func readsBackTheStoredTheme() {
        let suiteName = UUID().uuidString
        let writer = UserDefaults(suiteName: suiteName)!
        let storageA = ThemeStorage(userDefaults: writer)
        storageA.current = .magenta

        let reader = UserDefaults(suiteName: suiteName)!
        let storageB = ThemeStorage(userDefaults: reader)
        #expect(storageB.current == .magenta)
    }

    @Test func fallsBackToLumenForInvalidStoredString() {
        let suite = UserDefaults(suiteName: UUID().uuidString)!
        suite.set("not-a-theme", forKey: ThemeStorage.userDefaultsKey)
        let storage = ThemeStorage(userDefaults: suite)
        #expect(storage.current == .lumen)
    }
}
