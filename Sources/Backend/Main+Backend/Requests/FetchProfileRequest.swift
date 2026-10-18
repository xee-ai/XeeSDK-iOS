// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  FetchProfileRequest.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 23.09.2022.
//

import Foundation

private struct FetchProfileRequest: BackendRequest {
    let endpoint: HTTPEndpoint
    let headers: HTTPHeaders
    let stamp = Log.stamp
    let requestName = BackendRequestName.fetchProfile

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
