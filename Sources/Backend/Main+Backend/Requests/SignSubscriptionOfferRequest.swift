// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  SignSubscriptionOfferRequest.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 08.09.2022.
//

import Foundation

private struct SignSubscriptionOfferRequest: BackendRequest {
    let endpoint = HTTPEndpoint(
        method: .get,
        path: "/sdk/in-apps/apple/subscription-offer/sign/"
    )
    let headers: HTTPHeaders
    let queryItems: QueryItems
    let stamp = Log.stamp
    let requestName = BackendRequestName.signSubscriptionOffer
    let logParams: EventParameters?

    init(vendorProductId: String, offerId: String, userId: XeeUserId, appAccountToken: UUID?) {
        headers = HTTPHeaders()
            .setUserProfileId(userId)

        queryItems = QueryItems()
            .setUserProfileId(userId)
            .setVendorProductId(vendorProductId)
            .setOfferId(offerId)
            .setAppAccountToken(appAccountToken)

        logParams = [
            "product_id": vendorProductId,
            "discount_id": offerId
        ]
    }
}

private typealias ResponseBody = Backend.Response.Data<XeeSubscriptionOffer.Signature>

extension Backend.MainExecutor {
    func signSubscriptionOffer(
        userId: XeeUserId,
        vendorProductId: String,
        offerId: String,
        appAccountToken: UUID?
    ) async throws(HTTPError) -> XeeSubscriptionOffer.Signature {
        let request = SignSubscriptionOfferRequest(
            vendorProductId: vendorProductId,
            offerId: offerId,
            userId: userId,
            appAccountToken: appAccountToken
        )
        let response: HTTPResponse<ResponseBody> = try await perform(request)
        return response.body.value
    }
}
