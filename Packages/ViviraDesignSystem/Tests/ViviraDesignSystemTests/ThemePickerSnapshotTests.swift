// ThemePicker snapshot baseline tests — 5 themes × 2 modes = 10 snapshots.
#if canImport(UIKit)
import SnapshotTesting
import SwiftUI
import XCTest
@testable import ViviraDesignSystem

@MainActor
final class ThemePickerSnapshotTests: XCTestCase {

    // Lumen
    func test_themePicker_lumen_light() { assertPicker(selected: .lumen, scheme: .light) }
    func test_themePicker_lumen_dark()  { assertPicker(selected: .lumen, scheme: .dark)  }

    // Pomelo
    func test_themePicker_pomelo_light() { assertPicker(selected: .pomelo, scheme: .light) }
    func test_themePicker_pomelo_dark()  { assertPicker(selected: .pomelo, scheme: .dark)  }

    // Iris
    func test_themePicker_iris_light() { assertPicker(selected: .iris, scheme: .light) }
    func test_themePicker_iris_dark()  { assertPicker(selected: .iris, scheme: .dark)  }

    // Aqua
    func test_themePicker_aqua_light() { assertPicker(selected: .aqua, scheme: .light) }
    func test_themePicker_aqua_dark()  { assertPicker(selected: .aqua, scheme: .dark)  }

    // Magenta
    func test_themePicker_magenta_light() { assertPicker(selected: .magenta, scheme: .light) }
    func test_themePicker_magenta_dark()  { assertPicker(selected: .magenta, scheme: .dark)  }

    private func assertPicker(
        selected: Theme,
        scheme: ColorScheme,
        file: StaticString = #file,
        testName: String = #function,
        line: UInt = #line
    ) {
        struct Host: View {
            @State var selection: Theme
            var body: some View {
                ThemePicker(selection: $selection)
                    .padding(.vivira.md)
                    .frame(width: 360, alignment: .center)
                    .background(Color.vivira.surface)
            }
        }

        let view = Host(selection: selected)
            .preferredColorScheme(scheme)

        assertSnapshot(
            of: view,
            as: .image(layout: .fixed(width: 360, height: 96)),
            file: file,
            testName: testName,
            line: line
        )
    }
}
#endif
