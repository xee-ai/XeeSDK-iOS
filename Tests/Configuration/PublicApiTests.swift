// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
#if canImport(Testing)

import Xee
import Foundation
import Testing

/// A plain `import` (no `@testable`) is what an app sees. If `with(serverUrl:)` stops being public,
/// this file stops compiling.
struct PublicApiTests {
    @Test func serverUrlIsPartOfThePublicBuilder() {
        let configuration: XeeConfiguration = XeeConfiguration
            .builder(withAPIKey: "xee_0123456789abcdef0123456789abcdef")
            .with(serverUrl: URL(string: "https://server.example.test")!)
            .build()
        #expect(String(describing: configuration).isEmpty == false)
    }

    /// Only named, never called: a call would queue a real event while `WireTests` has the SDK activated.
    @Test func trackAndTimeArePublic() {
        let track: (String, [String: XeeProperty]) -> Void = Xee.track(_:properties:)
        let time: (String) -> Void = Xee.time(_:)
        let properties: [String: XeeProperty] = ["screen": "goals", "step": 2, "skipped": false, "ratio": 0.5]
        #expect(properties.count == 4)
        _ = (track, time)
    }

    /// Only named, never called, for the same reason as above: a call would reach the shared SDK.
    @Test func viewsArePublic() {
        let get: (String, TimeInterval) async -> XeeView = Xee.getView(_:loadTimeout:)
        let log: (XeeView) async -> Void = Xee.logShowView(_:)
        let empty: XeePaywallConfig = .empty
        #expect(empty.string("welcome_title", default: "Hi") == "Hi")
        _ = (get, log)
    }
}

#endif
