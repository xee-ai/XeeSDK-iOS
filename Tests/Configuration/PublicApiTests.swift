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
}

#endif
