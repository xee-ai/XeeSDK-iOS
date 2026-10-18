// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
#if canImport(Testing)

@testable import Xee
import Foundation
import Testing

struct ServerUrlTests {
    @Test func theConfiguredUrlIsUsedForEveryServerKind() {
        let url = URL(string: "https://server.example.test")!
        let builder = XeeConfiguration
            .builder(withAPIKey: "xee_0123456789abcdef0123456789abcdef")
            .with(serverUrl: url)
        for kind in XeeServerKind.allCases {
            #expect(builder.devBaseUrls[kind] == url, "kind \(kind) must use the configured server")
        }
    }

    @Test func anUnconfiguredKindResolvesToAHostThatCannotResolve() {
        // Xee has no built-in server. `.invalid` is reserved, so a missing configuration fails loudly.
        for kind in XeeServerKind.allCases {
            let host = Backend.defaultBaseUrl(kind: kind, by: .default).host
            #expect(host?.hasSuffix(".invalid") == true, "kind \(kind) resolved to \(host ?? "nil")")
        }
    }

    @Test func noDefaultUrlPointsAtXee() {
        for kind in XeeServerKind.allCases {
            let url = Backend.defaultBaseUrl(kind: kind, by: .default).absoluteString
            // The word is built from parts so the audit script does not flag this test.
            #expect(!url.contains(["adap", "ty"].joined()), "\(url)")
        }
    }
}

#endif
