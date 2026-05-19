// AppState transition tests.
import Testing
@testable import Vivira

@MainActor
@Suite struct AppStateTests {

    @Test func defaultsToNotConnected() {
        let state = AppState()
        #expect(state.kind == .notConnected)
    }

    @Test func transitionsForwardToConnected() {
        let state = AppState()
        state.kind = .connected
        #expect(state.kind == .connected)
    }

    @Test func transitionsBackwardToNotConnected() {
        let state = AppState()
        state.kind = .connected
        state.kind = .notConnected
        #expect(state.kind == .notConnected)
    }
}
