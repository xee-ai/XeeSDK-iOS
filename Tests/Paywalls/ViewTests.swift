#if canImport(Testing)

@testable import Xee
import Foundation
import Testing

struct ViewTests {
    @Test func anEmptyConfigReturnsEveryDefault() {
        let config = XeePaywallConfig.empty
        #expect(config.string("title", default: "Hi") == "Hi")
        #expect(config.int("days", default: 3) == 3)
        #expect(config.double("ratio", default: 0.5) == 0.5)
        #expect(config.bool("show_skip", default: true) == true)
        #expect(config.stringList("screen_order", default: ["a", "b"]) == ["a", "b"])
    }

    @Test func aViewThatCannotLoadReadsTheCodesDefaults() async {
        let view = await Xee.getView("view_never_pushed", loadTimeout: 1)
        #expect(view.id == "view_never_pushed")
        #expect(view.variationId == nil)
        #expect(view.config.string("welcome_title", default: "Trade smarter") == "Trade smarter")
        await Xee.logShowView(view)  // a fallback view logs nothing and does not throw
    }

    @Test func aLoadedViewReadsItsValues() {
        let view = XeeView(id: "onboarding", variationId: "onboarding.v2.B", config: XeePaywallConfig(json: #"{"welcome_title":"Trade faster"}"#))
        #expect(view.config.string("welcome_title", default: "Trade smarter") == "Trade faster")
        #expect(view.variationId == "onboarding.v2.B")
    }
}

#endif
