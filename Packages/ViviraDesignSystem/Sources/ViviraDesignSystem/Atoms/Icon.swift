// SF Symbols wrapper with size, weight, and accessibility defaults.
import SwiftUI

public struct Icon: View {
    private let symbol: String
    private let size: CGFloat
    private let weight: Font.Weight

    public init(symbol: String, size: CGFloat = 17, weight: Font.Weight = .regular) {
        self.symbol = symbol
        self.size = size
        self.weight = weight
    }

    public var body: some View {
        Image(systemName: symbol)
            .font(.system(size: size, weight: weight))
            .accessibilityHidden(true)
    }
}
