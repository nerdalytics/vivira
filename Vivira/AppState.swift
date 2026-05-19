import Foundation
import SwiftUI

@MainActor
public final class AppState: ObservableObject {
    public enum Kind: Equatable, Sendable {
        case notConnected
        case connected
    }

    @Published public var kind: Kind = .notConnected

    public init() {}
}
