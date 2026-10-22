// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
#if canImport(Testing)

@testable import Xee
import Foundation
import Testing

@Suite(.serialized) struct PaywallConfigTests {
    private let config = XeePaywallConfig(json: #"{"title":"Try","days":7,"ratio":0.5,"on":true,"perks":["a","b"],"flag":1,"half":2.5}"#)

    @Test func eachTypeReadsItsValue() {
        #expect(config.string("title", default: "x") == "Try")
        #expect(config.int("days", default: 3) == 7)
        #expect(config.double("ratio", default: 0) == 0.5)
        #expect(config.double("days", default: 0) == 7, "an integer is a valid double")
        #expect(config.bool("on", default: false) == true)
        #expect(config.stringList("perks", default: []) == ["a", "b"])
    }

    @Test func aMissingKeyOrWrongTypeFallsBackToTheCodesDefault() {
        #expect(config.string("missing", default: "fallback") == "fallback")
        #expect(config.int("title", default: 3) == 3)
        #expect(config.int("half", default: 3) == 3, "2.5 is not an int")
        #expect(config.bool("flag", default: false) == false, "1 is not a bool")
        #expect(config.int("on", default: 9) == 9, "true is not an int")
        #expect(config.bool("days", default: true) == true, "7 is not a bool")
        #expect(config.double("on", default: 1.5) == 1.5, "true is not a double")
        #expect(config.string("days", default: "d") == "d", "7 is not a string")
        let mixed = XeePaywallConfig(json: #"{"perks":["a",1]}"#)
        #expect(mixed.stringList("perks", default: ["d"]) == ["d"], "a mixed list is not a string list")
        #expect(XeePaywallConfig(json: "not json").string("title", default: "d") == "d")
    }

    @Test func bundledVersionsAreReadAndSentAsAHeader() {
        XeePaywallVersions.setForTesting(["main": 4])
        defer { XeePaywallVersions.setForTesting(nil) }
        #expect(XeePaywallVersions.version(for: "main") == 4)
        #expect(XeePaywallVersions.version(for: "other") == nil)
        #expect(HTTPHeaders().setPaywallVersion(4)["xee-paywall-version"] == "4")
        #expect(HTTPHeaders().setPaywallVersion(nil)["xee-paywall-version"] == nil)
    }

    @Test func thePaywallFetchSendsTheBundledVersion() {
        XeePaywallVersions.setForTesting(["main": 4])
        defer { XeePaywallVersions.setForTesting(nil) }
        let user = XeeUserId(profileId: "33333333-cccc-4ccc-8ccc-333333333333", customerId: nil)
        let variants = FetchPaywallVariantsRequest(
            apiKeyPrefix: "k", userId: user, paywallId: "main", locale: .defaultPaywallLocale,
            segmentId: "s", disableServerCache: false
        )
        #expect(variants.headers["xee-paywall-version"] == "4")
        let unbundled = FetchPaywallVariantsRequest(
            apiKeyPrefix: "k", userId: user, paywallId: "other", locale: .defaultPaywallLocale,
            segmentId: "s", disableServerCache: false
        )
        #expect(unbundled.headers["xee-paywall-version"] == nil, "no bundled version, no header")
    }

    @Test func oneBadEntryDoesNotDiscardTheTable() {
        let data = Data(#"{"main": 4, "onboarding": "x", "bad": 0, "neg": -2, "flag": true, "half": 1.5, "whole": 2.0}"#.utf8)
        #expect(XeePaywallVersions.parse(data) == ["main": 4, "whole": 2])
        #expect(XeePaywallVersions.parse(Data("[1]".utf8)).isEmpty)
        #expect(XeePaywallVersions.parse(Data("nope".utf8)).isEmpty)
    }

    @Test func aFallbackIsReportedOncePerKey() {
        let seen = FirstSightings()
        #expect(seen.isFirst("days") == true)
        #expect(seen.isFirst("days") == false)
        #expect(seen.isFirst("title") == true)
    }
}

#endif
