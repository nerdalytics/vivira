// Font tokens bound to Apple text styles.
import SwiftUI

public extension Font {
    enum vivira {
        public static let displayLarge: Font = .system(.largeTitle, design: .default, weight: .bold)
        public static let body:         Font = .system(.body,       design: .default, weight: .regular)
        public static let bodyBold:     Font = .system(.body,       design: .default, weight: .semibold)
        public static let headline:     Font = .system(.headline,   design: .default, weight: .semibold)
    }
}
