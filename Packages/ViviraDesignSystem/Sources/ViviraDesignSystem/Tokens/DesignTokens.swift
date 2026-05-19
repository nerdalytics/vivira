import SwiftUI

public extension Color {
    enum Vivira {
        public static let bg = Color("vivira.bg", bundle: .module)
        public static let surface = Color("vivira.surface", bundle: .module)
        public static let surface2 = Color("vivira.surface2", bundle: .module)
        public static let ink = Color("vivira.ink", bundle: .module)
        public static let ink2 = Color("vivira.ink2", bundle: .module)
        public static let muted = Color("vivira.muted", bundle: .module)
        public static let faint = Color("vivira.faint", bundle: .module)
        public static let line = Color("vivira.line", bundle: .module)
        public static let lineStrong = Color("vivira.lineStrong", bundle: .module)
    }
}

public extension CGFloat {
    enum Vivira {
        public static let xs: CGFloat = 4
        public static let sm: CGFloat = 8
        public static let md: CGFloat = 16
        public static let mdPlus: CGFloat = 20
        public static let lg: CGFloat = 24
        public static let xl: CGFloat = 32
        public static let xxxl: CGFloat = 48

        public enum Radius {
            public static let md: CGFloat = 10
            public static let lg: CGFloat = 14
        }
    }
}
