import SwiftUI

public extension Color {
    enum vivira {
        public static let bg    = Color("vivira.bg",    bundle: .module)
        public static let ink2  = Color("vivira.ink2",  bundle: .module)
        public static let faint = Color("vivira.faint", bundle: .module)
    }
}

public extension CGFloat {
    enum vivira {
        public static let xs:     CGFloat = 4
        public static let sm:     CGFloat = 8
        public static let md:     CGFloat = 16
        public static let mdPlus: CGFloat = 20
        public static let lg:     CGFloat = 24
        public static let xl:     CGFloat = 32
        public static let xxxl:   CGFloat = 48

        public enum radius {
            public static let md: CGFloat = 10
            public static let lg: CGFloat = 14
        }
    }
}
