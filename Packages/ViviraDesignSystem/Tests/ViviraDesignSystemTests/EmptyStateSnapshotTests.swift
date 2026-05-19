// EmptyState snapshot baseline tests (Lumen light + dark).
// Gated on UIKit availability: swift-snapshot-testing's .image(layout:)
// only exists on UIKit-bearing platforms. On macOS this file compiles to
// nothing so `swift test` on the host stops hitting an API mismatch.
// These tests need an Xcode scheme that runs them against the iOS
// simulator to actually execute; see spec §6.2 follow-up.

#if canImport(UIKit)
import SnapshotTesting
import SwiftUI
import XCTest
@testable import ViviraDesignSystem

@MainActor
final class EmptyStateSnapshotTests: XCTestCase {

    func test_emptyState_lumen_light() {
        let view = EmptyState(
            symbol: "photo.on.rectangle.angled",
            message: "Vivira keeps Immich shared albums\nin sync with your iPhone.",
            ctaLabel: "Add a server",
            action: {}
        )
        .background(Color.Vivira.bg)

        assertSnapshot(
            of: view,
            as: .image(
                layout: .fixed(width: 393, height: 852),
                traits: UITraitCollection(userInterfaceStyle: .light)
            )
        )
    }

    func test_emptyState_lumen_dark() {
        let view = EmptyState(
            symbol: "photo.on.rectangle.angled",
            message: "Vivira keeps Immich shared albums\nin sync with your iPhone.",
            ctaLabel: "Add a server",
            action: {}
        )
        .background(Color.Vivira.bg)

        assertSnapshot(
            of: view,
            as: .image(
                layout: .fixed(width: 393, height: 852),
                traits: UITraitCollection(userInterfaceStyle: .dark)
            )
        )
    }
}
#endif
