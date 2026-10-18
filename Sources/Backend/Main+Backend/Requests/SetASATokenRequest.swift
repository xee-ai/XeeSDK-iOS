// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  SetASATokenRequest.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 01.03.2024.
//

import Foundation

private struct SetASATokenRequest: BackendEncodableRequest {
    let endpoint = HTTPEndpoint(
        method: .post,
        path: "/sdk/attribution/asa/"
    )
    let headers: HTTPHeaders
    let stamp = Log.stamp
    let requestName = BackendRequestName.sendASAToken
    let logParams: EventParameters?

    let token: String

    init(userId: XeeUserId, token: String, responseHash: String?) {
        headers = HTTPHeaders()
            .setUserProfileId(userId)
            .setBackendResponseHash(responseHash)

        self.token = token
        logParams = ["token": token]
    }

    enum CodingKeys: String, CodingKey {
        case token
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Backend.CodingKeys.self)
        var dataObject = container.nestedContainer(keyedBy: Backend.CodingKeys.self, forKey: .data)
        try dataObject.encode("adapty_attribution_asa", forKey: .type)
        var attributesObject = dataObject.nestedContainer(keyedBy: CodingKeys.self, forKey: .attributes)
        try attributesObject.encode(token, forKey: .token)
    }
}

private typealias ResponseBody = XeeProfile?
extension Backend.MainExecutor {
    func sendASAToken(
        userId: XeeUserId,
        token: String,
        responseHash: String?
    ) async throws(HTTPError) -> VH<XeeProfile>? {
        let request = SetASATokenRequest(
            userId: userId,
            token: token,
            responseHash: responseHash
        )
        let response = try await perform(request, withDecoder: VH<XeeProfile>?.decoder)
        return response.body
    }
}
