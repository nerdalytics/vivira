// EmptyState snapshot baseline tests (Lumen light + dark).
import SnapshotTesting
import SwiftUI
import Testing
@testable import ViviraDesignSystem

@MainActor
@Suite struct EmptyStateSnapshotTests {

    @Test func emptyState_lumen_light() {
        let view = AnyView(
            EmptyState(
                symbol: "photo.on.rectangle.angled",
                message: "Vivira keeps Immich shared albums\nin sync with your iPhone.",
                ctaLabel: "Add a server",
                action: {}
            )
            .environment(\.viviraTheme, .lumen)
            .background(Color.vivira.bg)
            .frame(width: 393, height: 852)
            .preferredColorScheme(.light)
        )

        assertSnapshot(of: view, as: .image)
    }

    @Test func emptyState_lumen_dark() {
        let view = AnyView(
            EmptyState(
                symbol: "photo.on.rectangle.angled",
                message: "Vivira keeps Immich shared albums\nin sync with your iPhone.",
                ctaLabel: "Add a server",
                action: {}
            )
            .environment(\.viviraTheme, .lumen)
            .background(Color.vivira.bg)
            .frame(width: 393, height: 852)
            .preferredColorScheme(.dark)
        )

        assertSnapshot(of: view, as: .image)
    }
}
