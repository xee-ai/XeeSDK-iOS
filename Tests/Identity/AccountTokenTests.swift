// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
#if canImport(Testing)

@testable import Xee
import Foundation
import Testing

/// Which StoreKit appAccountToken a purchase carries, and when a refused profile request is final.
/// The server grants access only from Apple's notifications, matched by that token, so a purchase
/// that carries none (or a token the server does not know) never unlocks anything.
@Suite struct AccountTokenTests {
    private let fromServer = UUID(uuidString: "AAAAAAAA-AAAA-4AAA-8AAA-AAAAAAAAAAAA")!
    private let explicit = UUID(uuidString: "BBBBBBBB-BBBB-4BBB-8BBB-BBBBBBBBBBBB")!
    private let customerUuid = UUID(uuidString: "CCCCCCCC-CCCC-4CCC-8CCC-CCCCCCCCCCCC")!

    @Test func theProfileResponseCarriesTheToken() throws {
        let json = """
        {"data":{"type":"adapty_analytics_profile","id":"11111111-1111-4111-8111-111111111111","attributes":{
          "profile_id":"11111111-1111-4111-8111-111111111111","customer_user_id":null,
          "store_account_token":"aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa","segment_hash":"default",
          "paid_access_levels":{},"subscriptions":{},"non_subscriptions":{},"timestamp":1}}}
        """
        let decoder = JSONDecoder()
        Backend.configure(jsonDecoder: decoder)
        let profile = try decoder.decode(Backend.Response.Data<XeeProfile>.self, from: Data(json.utf8)).value
        #expect(profile.storeAccountToken == fromServer)
        // It survives the cache the SDK keeps the profile in.
        let again = try JSONDecoder().decode(XeeProfile.self, from: JSONEncoder().encode(profile))
        #expect(again.storeAccountToken == fromServer)
    }

    @Test func aTokenTheServerKnowsIsUsedForEveryPurchase() {
        // Anonymous users too: before this they got none, and their purchases never matched a profile.
        #expect(Xee.purchaseAccountToken(profileToken: fromServer, explicit: nil, customerUserId: nil) == fromServer)
        #expect(Xee.purchaseAccountToken(profileToken: fromServer, explicit: explicit, customerUserId: "alice") == fromServer)
        #expect(Xee.purchaseAccountToken(profileToken: fromServer, explicit: nil, customerUserId: customerUuid.uuidString) == fromServer)
    }

    @Test func withoutTheProfileFromTheServerTheTokenTheAppGaveIsUsed() {
        #expect(Xee.purchaseAccountToken(profileToken: nil, explicit: explicit, customerUserId: "alice") == explicit)
        #expect(Xee.purchaseAccountToken(profileToken: nil, explicit: nil, customerUserId: customerUuid.uuidString) == customerUuid)
        #expect(Xee.purchaseAccountToken(profileToken: nil, explicit: nil, customerUserId: "alice") == nil)
        #expect(Xee.purchaseAccountToken(profileToken: nil, explicit: nil, customerUserId: nil) == nil)
    }

    private func backend(_ status: Int) -> HTTPError {
        .backend(HTTPEndpoint(method: .post, path: "/x"), XeeError.Source(), statusCode: status, headers: [:], metrics: nil, error: nil)
    }

    @Test func aRefusalThatWillNotChangeIsFinalButATemporaryOneIsRetried() {
        for status in [400, 401, 403, 404, 409, 422] { #expect(backend(status).isFinal, "\(status)") }
        for status in [408, 429, 500, 502, 503] { #expect(!backend(status).isFinal, "\(status)") }
        let offline = HTTPError.network(HTTPEndpoint(method: .post, path: "/x"), XeeError.Source(), metrics: nil, error: URLError(.notConnectedToInternet))
        #expect(!offline.isFinal)
    }
}
#endif
