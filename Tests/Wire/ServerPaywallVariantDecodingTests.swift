// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
#if canImport(Testing)

@testable import Xee
import Foundation
import Testing

/// The paywall responses exactly as the Xee server (server/src/sdk.rs) renders them, decoded the way
/// `XeePaywallChosen.createDecoder` decodes them.
@Suite struct ServerPaywallVariantDecodingTests {
    private let variant = { (id: String, weight: Int, cta: String) in
        """
        {"type":"adapty_paywall_variant","id":"\(id)","attributes":{"paywall_variant_id":"\(id)","paywall_variant_name":"PaywallVariant \(cta)",
         "variation_id":"\(id)","weight":\(weight),
         "remote_config":{"lang":"en","data":"{\\"title\\":\\"Go premium\\",\\"cta\\":\\"\(cta)\\"}"},
         "products":[{"vendor_product_id":"com.example.yearly","adapty_product_id":"xee_com.example.yearly","access_level_id":"premium","product_type":"annual"}]}}
        """
    }
    private let meta = """
    {"paywall":{"developer_id":"main","audience_name":"All users","revision":4,"ab_test_name":"CTA test",
      "paywall_audience_version_id":"t-1","is_tracking_purchases":false},"response_created_at":1800000000123}
    """
    private let a = "11111111-aaaa-4aaa-8aaa-111111111111"
    private let b = "22222222-bbbb-4bbb-8bbb-222222222222"

    private func decoder(userId: XeeUserId, paywall: XeePaywall) -> JSONDecoder {
        let decoder = JSONDecoder()
        Backend.configure(jsonDecoder: decoder)
        decoder.userInfo.setPaywall(paywall)
        decoder.userInfo.setUserId(userId)
        decoder.userInfo.setRequestLocale(XeeLocale("en"))
        return decoder
    }

    @Test func theVariationListDecodesAndTheSdkDrawsOneOfThem() throws {
        let body = Data("""
        {"data":[\(variant(a, 50, "Start free trial")),\(variant(b, 50, "Try 3 days free"))],"meta":\(meta)}
        """.utf8)
        let plain = JSONDecoder()
        Backend.configure(jsonDecoder: plain)
        let paywall = try plain.decode(Backend.Response.Meta<XeePaywall>.self, from: body).value
        #expect(paywall.id == "main")
        #expect(paywall.revision == 4)
        #expect(paywall.version == 1_800_000_000_123)

        let user = XeeUserId(profileId: "33333333-cccc-4ccc-8ccc-333333333333", customerId: nil)
        let draw = try decoder(userId: user, paywall: paywall)
            .decode(Backend.Response.Data<XeePaywall.Draw<XeePaywallVariant>>.self, from: body).value
        let paywallVariant = draw.content
        #expect([a, b].contains(paywallVariant.variationId))
        #expect(paywallVariant.vendorProductIds == ["com.example.yearly"])
        let config = try #require(paywallVariant.remoteConfig?.dictionary)
        #expect(config["title"] as? String == "Go premium")
        #expect(draw.paywallAudienceVersionId == "t-1")
    }

    @Test func aSingleVariationFetchedByIdDecodes() throws {
        let body = Data("""
        {"data":\(variant(b, 50, "Try 3 days free")),"meta":\(meta)}
        """.utf8)
        let plain = JSONDecoder()
        Backend.configure(jsonDecoder: plain)
        let paywall = try plain.decode(Backend.Response.Meta<XeePaywall>.self, from: body).value
        let d = decoder(userId: XeeUserId(profileId: "p", customerId: nil), paywall: paywall)
        let variation = try d.decode(Backend.Response.Data<XeePaywall.Variation>.self, from: body).value
        #expect(variation.variationId == b)
        #expect(variation.weight == 50)
        let paywallVariant = try d.decode(Backend.Response.Data<XeePaywallVariant>.self, from: body).value
        #expect(paywallVariant.name == "PaywallVariant Try 3 days free")
    }
}
#endif
