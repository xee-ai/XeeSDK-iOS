//
//  FetchPaywallAssignmentRequest.swift
//  XeeSDK
//

import Foundation

/// The arm the server chose for this profile in a paywall's running test (server/src/sdk.rs, paywall_assignment).
struct PaywallAssignment: Codable, Sendable, Equatable {
    let variationId: String
    let audienceVersionId: String

    enum CodingKeys: String, CodingKey {
        case variationId = "variation_id"
        case audienceVersionId = "paywall_audience_version_id"
    }
}

/// `{ "data": PaywallAssignment | null }`: null when the paywall has no running test.
struct PaywallAssignmentAnswer: Decodable, Sendable {
    let data: PaywallAssignment?
}

private struct FetchPaywallAssignmentRequest: BackendRequest {
    let endpoint: HTTPEndpoint
    let headers: HTTPHeaders
    let stamp = Log.stamp
    let requestName = BackendRequestName.fetchPaywallAssignment
    let logParams: EventParameters?

    init(apiKeyPrefix: String, userId: XeeUserId, paywallId: String) {
        endpoint = HTTPEndpoint(
            method: .post,
            path: "/sdk/in-apps/\(apiKeyPrefix)/paywall/assignment/\(paywallId)/"
        )
        headers = HTTPHeaders().setUserProfileId(userId)
        logParams = ["api_prefix": apiKeyPrefix, "paywall_id": paywallId]
    }
}

extension Backend.MainExecutor {
    func fetchPaywallAssignment(
        apiKeyPrefix: String,
        userId: XeeUserId,
        paywallId: String
    ) async throws(HTTPError) -> PaywallAssignment? {
        let request = FetchPaywallAssignmentRequest(apiKeyPrefix: apiKeyPrefix, userId: userId, paywallId: paywallId)
        let response: HTTPResponse<PaywallAssignmentAnswer> = try await perform(request)
        return response.body.data
    }
}
