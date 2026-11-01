#if canImport(Testing)

@testable import Xee
import Foundation
import Testing

/// The profile JSON exactly as the Xee server (server/src/sdk.rs) renders it for an active subscription.
@Suite struct ServerProfileDecodingTests {
    @Test func theServersProfileResponseDecodes() throws {
        let json = """
        {"data":{"type":"analytics_profile","id":"11111111-1111-4111-8111-111111111111","attributes":{
          "profile_id":"11111111-1111-4111-8111-111111111111","customer_user_id":null,
          "store_account_token":"aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa","segment_hash":"default",
          "paid_access_levels":{"premium":{"id":"premium","is_active":true,"vendor_product_id":"com.example.monthly","store":"app_store",
            "activated_at":"2026-10-17T01:02:03.000+0000","expires_at":"2026-11-17T01:02:03.000+0000","is_lifetime":false,
            "will_renew":true,"is_in_grace_period":false,"unsubscribed_at":null,"billing_issue_detected_at":null,"is_refund":false}},
          "subscriptions":{"com.example.monthly":{"store":"app_store","vendor_product_id":"com.example.monthly",
            "vendor_transaction_id":"1000","vendor_original_transaction_id":"1000","is_active":true,"is_lifetime":false,
            "activated_at":"2026-10-17T01:02:03.000+0000","expires_at":"2026-11-17T01:02:03.000+0000","will_renew":true,
            "is_in_grace_period":false,"is_sandbox":true,"is_refund":false,"unsubscribed_at":null,"billing_issue_detected_at":null}},
          "non_subscriptions":{},"timestamp":1760000000000}}}
        """
        let decoder = JSONDecoder()
        Backend.configure(jsonDecoder: decoder)
        let profile = try decoder.decode(Backend.Response.Data<XeeProfile>.self, from: Data(json.utf8)).value
        #expect(profile.accessLevels["premium"]?.isActive == true)
        #expect(profile.subscriptions["com.example.monthly"]?.isActive == true)
        #expect(profile.profileId == "11111111-1111-4111-8111-111111111111")
    }

    /// The same profile without `data.type`, `data.id`, an empty `non_subscriptions` or any `null`.
    @Test func aTrimmedProfileDecodesTheSame() throws {
        let json = """
        {"data":{"attributes":{
          "profile_id":"11111111-1111-4111-8111-111111111111",
          "store_account_token":"aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa","segment_hash":"default",
          "paid_access_levels":{"premium":{"id":"premium","is_active":true,"vendor_product_id":"com.example.monthly","store":"app_store",
            "activated_at":"2026-10-17T01:02:03.000+0000","expires_at":"2026-11-17T01:02:03.000+0000","is_lifetime":false,
            "will_renew":true,"is_in_grace_period":false,"is_refund":false}},
          "subscriptions":{"com.example.monthly":{"store":"app_store","vendor_product_id":"com.example.monthly",
            "vendor_transaction_id":"1000","vendor_original_transaction_id":"1000","is_active":true,"is_lifetime":false,
            "activated_at":"2026-10-17T01:02:03.000+0000","expires_at":"2026-11-17T01:02:03.000+0000","will_renew":true,
            "is_in_grace_period":false,"is_sandbox":true,"is_refund":false}},
          "timestamp":1760000000000}}}
        """
        let decoder = JSONDecoder()
        Backend.configure(jsonDecoder: decoder)
        let profile = try decoder.decode(Backend.Response.Data<XeeProfile>.self, from: Data(json.utf8)).value
        let premium = try #require(profile.accessLevels["premium"])
        #expect(premium.isActive)
        #expect(premium.unsubscribedAt == nil)
        #expect(premium.billingIssueDetectedAt == nil)
        #expect(profile.customerUserId == nil)
        #expect(profile.nonSubscriptions.isEmpty)
        #expect(profile.subscriptions["com.example.monthly"]?.isActive == true)
    }

    /// The edge answers `{}` with the same `x-response-hash` when the device already has the profile: nothing is decoded.
    @Test func theSameHashKeepsTheSavedProfile() async throws {
        let request = ProfileRead(previousHash: "h1")
        let response = HTTPDataResponse(
            endpoint: request.endpoint, statusCode: 200, headers: ["x-response-hash": "h1"], body: Data("{}".utf8), metrics: nil
        )
        let decoded = try await VH<XeeProfile>?.decoder(response, nil, request)
        #expect(decoded.body == nil)
    }

    @Test func aNewHashBringsTheNewProfileAndItsHash() async throws {
        let request = ProfileRead(previousHash: "h1")
        let json = #"{"data":{"attributes":{"profile_id":"11111111-1111-4111-8111-111111111111","segment_hash":"default"}}}"#
        let response = HTTPDataResponse(
            endpoint: request.endpoint, statusCode: 200, headers: ["x-response-hash": "h2"], body: Data(json.utf8), metrics: nil
        )
        let decoded = try await VH<XeeProfile>?.decoder(response, nil, request)
        #expect(decoded.body?.hash == "h2")
        #expect(decoded.body?.value.profileId == "11111111-1111-4111-8111-111111111111")
    }
}

/// A profile read that sends the device's last hash, as the SDK's own fetch does.
private struct ProfileRead: HTTPRequest {
    let endpoint = HTTPEndpoint(method: .get, path: "/sdk/analytics/profiles/11111111-1111-4111-8111-111111111111/")
    let headers: HTTPHeaders
    let stamp = "test"

    init(previousHash: String) {
        headers = HTTPHeaders().setBackendResponseHash(previousHash)
    }
}
#endif
