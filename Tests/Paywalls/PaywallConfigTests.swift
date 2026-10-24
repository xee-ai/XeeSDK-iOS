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

    @Test func theAppBuildIsSentAsAHeader() {
        #expect(HTTPHeaders().setAppBuild("142")["xee-app-build"] == "142")
        #expect(HTTPHeaders().setAppBuild(" 1.4.2\n")["xee-app-build"] == "1.4.2")
        #expect(HTTPHeaders().setAppBuild("")["xee-app-build"] == nil)
        #expect(HTTPHeaders().setAppBuild(nil)["xee-app-build"] == nil)
        #expect(HTTPHeaders().setAppBuild("142").setAppBuild(nil)["xee-app-build"] == nil, "nil removes it")
    }

    @Test func aFallbackIsReportedOncePerKey() {
        let seen = FirstSightings()
        #expect(seen.isFirst("days") == true)
        #expect(seen.isFirst("days") == false)
        #expect(seen.isFirst("title") == true)
    }
}

#endif
