// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  FetchCrossPaywallStateRequest.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 01.04.2025.
//

import Foundation

private struct FetchCrossPaywallStateRequest: BackendRequest {
    let endpoint = HTTPEndpoint(
        method: .get,
        path: "/sdk/in-apps/profile/cross-paywall-info/"
    )
    let headers: HTTPHeaders
    let stamp = Log.stamp
    let requestName = BackendRequestName.fetchCrossPaywallState

    init(userId: XeeUserId) {
        headers = HTTPHeaders()
            .setUserProfileId(userId)
    }
}

private typealias ResponseBody = Backend.Response.Data<CrossPaywallState>

extension Backend.MainExecutor {
    func fetchCrossPaywallState(
        userId: XeeUserId
    ) async throws(HTTPError) -> CrossPaywallState {
        let request = FetchCrossPaywallStateRequest(
            userId: userId
        )
        let response: HTTPResponse<ResponseBody> = try await perform(request)
        return response.body.value
    }
}
