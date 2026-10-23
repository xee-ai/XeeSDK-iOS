// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
#if canImport(Testing)

@testable import Xee
import Foundation
import Testing

/// A fallback file exactly as the dashboard generates it (dashboard/lib/fallback.ts), read by the SDK.
@Suite struct DashboardFallbackFileTests {
    private let json = #"{"data":{"main":{"data":[{"variation_id":"main.v2.A","paywall_variant_id":"main.v2.A","paywall_variant_name":"main v2 A","products":[{"title":"w","is_consumable":false,"adapty_product_id":"xee_w","vendor_product_id":"w","access_level_id":"premium","product_type":"annual"},{"title":"y","is_consumable":false,"adapty_product_id":"xee_y","vendor_product_id":"y","access_level_id":"premium","product_type":"annual"}],"remote_config":{"lang":"en","data":"{\"title\":\"Go premium\",\"cta\":\"Start now\"}"},"remote_configs":[{"lang":"en","data":"{\"title\":\"Go premium\",\"cta\":\"Start now\"}"},{"lang":"fr","data":"{\"title\":\"Passez premium\",\"cta\":\"Commencer\"}"}],"cross_paywall_info":null,"weight":60},{"variation_id":"main.v2.B","paywall_variant_id":"main.v2.B","paywall_variant_name":"main v2 B","products":[{"title":"w","is_consumable":false,"adapty_product_id":"xee_w","vendor_product_id":"w","access_level_id":"premium","product_type":"annual"},{"title":"y","is_consumable":false,"adapty_product_id":"xee_y","vendor_product_id":"y","access_level_id":"premium","product_type":"annual"}],"remote_config":{"lang":"en","data":"{\"title\":\"Go premium\",\"cta\":\"Try free\"}"},"remote_configs":[{"lang":"en","data":"{\"title\":\"Go premium\",\"cta\":\"Try free\"}"},{"lang":"fr","data":"{\"title\":\"Passez premium\",\"cta\":\"Essai gratuit\"}"}],"cross_paywall_info":null,"weight":40}],"meta":{"paywall":{"developer_id":"main","audience_name":"All users","revision":3,"ab_test_name":"CTA test","paywall_audience_version_id":"t1","is_tracking_purchases":false}}}},"meta":{"version":10,"response_created_at":1800000000000,"developer_ids":["main"]}}"#

    @Test func theSdkReadsTheDashboardsFallbackFile() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("xee-fallback-\(UUID().uuidString).json")
        try Data(json.utf8).write(to: url)
        defer { try? FileManager.default.removeItem(at: url) }

        let fallback = try FallbackPaywalls(fileURL: url)
        #expect(fallback.formatVersion == Xee.fallbackFormatVersion)
        #expect(fallback.version == 1_800_000_000_000)
        #expect(fallback.contains(paywallId: "main") == true)
        #expect(fallback.contains(paywallId: "other") == false)

        let user = XeeUserId(profileId: "33333333-cccc-4ccc-8ccc-333333333333", customerId: nil)
        let chosen: XeePaywallChosen<XeePaywallVariant>? = fallback.getPaywall(
            byPaywallId: "main", withVariationId: nil, userId: user, requestLocale: .defaultPaywallLocale
        )
        let paywallVariant = try #require(chosen).content
        // Two arms of the running test (60/40): the profile draws one; each carries its own value.
        let ctaByVariation = ["main.v2.A": "Start now", "main.v2.B": "Try free"]
        let expectedCta = try #require(ctaByVariation[paywallVariant.variationId])
        #expect(paywallVariant.vendorProductIds == ["w", "y"])
        #expect(paywallVariant.paywall.revision == 3)
        let config = try #require(paywallVariant.remoteConfig?.dictionary)
        #expect(config["cta"] as? String == expectedCta)
        #expect(config["title"] as? String == "Go premium")
        #expect(paywallVariant.remoteConfig?.locale == "en")
    }

    /// Format 10 carries every language; a request picks the one the server would (XeeLocale.resolve).
    @Test func theSdkPicksTheRequestedLanguageFromTheFile() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("xee-fallback-\(UUID().uuidString).json")
        try Data(json.utf8).write(to: url)
        defer { try? FileManager.default.removeItem(at: url) }
        let fallback = try FallbackPaywalls(fileURL: url)
        let user = XeeUserId(profileId: "33333333-cccc-4ccc-8ccc-333333333333", customerId: nil)

        let french: XeePaywallChosen<XeePaywallVariant>? = fallback.getPaywall(
            byPaywallId: "main", withVariationId: nil, userId: user, requestLocale: "fr-CA"
        )
        let fr = try #require(french).content
        let ctaByVariation = ["main.v2.A": "Commencer", "main.v2.B": "Essai gratuit"]
        let config = try #require(fr.remoteConfig?.dictionary)
        #expect(config["cta"] as? String == ctaByVariation[fr.variationId])
        #expect(config["title"] as? String == "Passez premium")
        #expect(fr.remoteConfig?.locale == "fr")

        let german: XeePaywallChosen<XeePaywallVariant>? = fallback.getPaywall(
            byPaywallId: "main", withVariationId: nil, userId: user, requestLocale: "de"
        )
        #expect(try #require(german).content.remoteConfig?.dictionary?["title"] as? String == "Go premium")
    }
}
#endif
