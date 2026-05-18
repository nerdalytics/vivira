// HeroStatusCard idle-state smoke snapshot. Active and degraded states land later.
#if canImport(UIKit)
import SnapshotTesting
import SwiftUI
import XCTest
@testable import ViviraDesignSystem

@MainActor
final class HeroStatusCardSnapshotTests: XCTestCase {

    func test_heroStatusCard_idle_lumen_light() {
        let view = HeroStatusCard.idle(
            summary: "✓ Connected · 0 subscriptions",
            hint: "Add an album to start syncing"
        )
        .padding(.vivira.md)
        .frame(width: 393)
        .background(Color.vivira.bg)
        .environment(\.viviraTheme, .lumen)

        assertSnapshot(
            of: view,
            as: .image(
                layout: .fixed(width: 393, height: 120),
                traits: UITraitCollection(userInterfaceStyle: .light)
            )
        )
    }
}
#endif
