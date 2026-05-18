// EmptyState snapshot baseline tests (Lumen light + dark).

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
        .background(Color.vivira.bg)
        .preferredColorScheme(.light)

        assertSnapshot(of: view, as: .image(layout: .fixed(width: 393, height: 852)))
    }

    func test_emptyState_lumen_dark() {
        let view = EmptyState(
            symbol: "photo.on.rectangle.angled",
            message: "Vivira keeps Immich shared albums\nin sync with your iPhone.",
            ctaLabel: "Add a server",
            action: {}
        )
        .background(Color.vivira.bg)
        .preferredColorScheme(.dark)

        assertSnapshot(of: view, as: .image(layout: .fixed(width: 393, height: 852)))
    }
}
