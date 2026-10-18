// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  SetAttributionDataRequest.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 23.09.2022.
//

import Foundation

private struct SetAttributionDataRequest: BackendEncodableRequest {
    let endpoint = HTTPEndpoint(
        method: .post,
        path: "/sdk/attribution/profile/set/data/"
    )
    let headers: HTTPHeaders
    let contentType: String? = "application/json"
    let stamp = Log.stamp
    let requestName = BackendRequestName.setAttributionData
    let logParams: EventParameters?

    let source: String
    let attributionJson: String
    let userId: XeeUserId

    init(userId: XeeUserId, source: String, attributionJson: String, responseHash: String?) {
        headers = HTTPHeaders()
            .setUserProfileId(userId)
            .setBackendResponseHash(responseHash)

        self.source = source
        self.attributionJson = attributionJson
        self.userId = userId

        logParams = [
            "source": source
        ]
    }

    enum CodingKeys: String, CodingKey {
        case source
        case attributionJson = "attribution_json"
        case profileId = "profile_id"
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(source, forKey: .source)
        try container.encode(attributionJson, forKey: .attributionJson)
        try container.encode(userId.profileId, forKey: .profileId)
    }
}

private typealias ResponseBody = XeeProfile?

extension Backend.MainExecutor {
    func setAttributionData(
        userId: XeeUserId,
        source: String,
        attributionJson: String,
        responseHash: String?
    ) async throws(HTTPError) -> VH<XeeProfile>? {
        let request = SetAttributionDataRequest(
            userId: userId,
            source: source,
            attributionJson: attributionJson,
            responseHash: responseHash
        )
        let response = try await perform(request, withDecoder: VH<XeeProfile>?.decoder)
        return response.body
    }
}
