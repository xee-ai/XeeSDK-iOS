//  FetchProfileRequest.swift
//  XeeSDK
//
//  Created by Xee team.
//

import Foundation

private struct FetchProfileRequest: BackendRequest {
    let endpoint: HTTPEndpoint
    let headers: HTTPHeaders
    let stamp = Log.stamp
    let requestName = BackendRequestName.fetchProfile
    /// Idempotent, and a failed read falls back to the saved profile (`ProfileManager.fetchProfile`).
    let isQuickRead = true

    init(userId: XeeUserId, responseHash: String?) {
        endpoint = HTTPEndpoint(
            method: .get,
            path: "/sdk/analytics/profiles/\(userId.profileId)/"
        )

        headers = HTTPHeaders()
            .setUserProfileId(userId)
            .setBackendResponseHash(responseHash)
    }
}

extension Backend.MainExecutor {
    func fetchProfile(
        userId: XeeUserId,
        responseHash: String?
    ) async throws(HTTPError) -> VH<XeeProfile>? {
        let request = FetchProfileRequest(
            userId: userId,
            responseHash: responseHash
        )
        let response = try await perform(request, withDecoder: VH<XeeProfile>?.decoder)
        return response.body
    }
}
