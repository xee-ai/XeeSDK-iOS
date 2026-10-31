// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
#if canImport(Testing)

@testable import Xee
import Foundation
import Testing

/// A fallback file exactly as the dashboard downloads it: the server builds it from the SDK's own offer
/// (server/src/fallback.rs; `WRITE_FALLBACK_SAMPLE=<path> cargo test --test fallback` writes this one).
@Suite struct DashboardFallbackFileTests {
    private let json = #"{"data":{"main":{"data":[{"paywall_variant_id":"main.v2.A","paywall_variant_name":"main v2 A","products":[{"access_level_id":"premium","product_id":"xee_w","product_type":"annual","vendor_product_id":"w"},{"access_level_id":"premium","product_id":"xee_y","product_type":"annual","vendor_product_id":"y"}],"remote_config":{"data":"{\"cta\":\"Start now\",\"title\":\"Go premium\"}","lang":"en"},"remote_configs":[{"data":"{\"cta\":\"Start now\",\"title\":\"Go premium\"}","lang":"en"},{"data":"{\"cta\":\"Commencer\",\"title\":\"Passez premium\"}","lang":"fr"}],"variation_id":"main.v2.A","weight":60},{"paywall_variant_id":"main.v2.B","paywall_variant_name":"main v2 B","products":[{"access_level_id":"premium","product_id":"xee_w","product_type":"annual","vendor_product_id":"w"},{"access_level_id":"premium","product_id":"xee_y","product_type":"annual","vendor_product_id":"y"}],"remote_config":{"data":"{\"cta\":\"Try free\",\"title\":\"Go premium\"}","lang":"en"},"remote_configs":[{"data":"{\"cta\":\"Try free\",\"title\":\"Go premium\"}","lang":"en"},{"data":"{\"cta\":\"Essai gratuit\",\"title\":\"Passez premium\"}","lang":"fr"}],"variation_id":"main.v2.B","weight":40}],"meta":{"paywall":{"ab_test_name":"CTA test","audience_name":"All users","developer_id":"main","is_tracking_purchases":false,"paywall_audience_version_id":"t1","revision":3},"response_created_at":1800000000003}}},"meta":{"developer_ids":["main"],"response_created_at":1800000000000,"version":10}}"#

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
