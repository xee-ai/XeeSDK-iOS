#if canImport(Testing)

@testable import Xee
import Foundation
import Testing

/// Which language a paywall or view is asked for, and when a cached copy is still the right one.
struct PaywallLocaleTests {
    @Test func noLocaleMeansTheAppsLanguage() {
        #expect(Xee.requestLocale(nil).id == XeeLocale.app.id)
        #expect(Xee.requestLocale("  ").id == XeeLocale.app.id)
        #expect(Xee.requestLocale("fr_FR").id == "fr-FR")
        #expect(Xee.requestLocale("not a locale").id == XeeLocale.app.id)
    }

    @Test func aCachedPaywallMatchesOnlyTheLanguageItWasAskedIn() throws {
        let url = Bundle.module.url(forResource: "fallback.json", withExtension: nil)!
        let chosen: XeePaywallChosen<XeePaywallVariant>? = try FallbackPaywalls(fileURL: url).getPaywall(
            byPaywallId: "promo",
            withVariationId: nil,
            userId: XeeUserId(profileId: "test_profile", customerId: nil),
            requestLocale: "fr-FR"
        )
        let content = try #require(chosen?.content)
        #expect(content.matches(requestLocale: "fr_FR"))
        #expect(!content.matches(requestLocale: "fr"))
        #expect(!content.matches(requestLocale: "en"))
    }

    @Test func aViewIsAskedInTheLanguageGiven() async {
        let asked = Box()
        _ = await Xee.view("onboarding", locale: "de") { locale in
            asked.value = locale.id
            throw URLError(.notConnectedToInternet)
        }
        #expect(asked.value == "de")
        _ = await Xee.view("onboarding", locale: nil) { locale in
            asked.value = locale.id
            throw URLError(.notConnectedToInternet)
        }
        #expect(asked.value == XeeLocale.app.id)
    }
}

private final class Box: @unchecked Sendable {
    var value: String?
}

#endif
