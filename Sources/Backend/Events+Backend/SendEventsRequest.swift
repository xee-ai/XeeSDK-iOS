// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  SendEventsRequest.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 13.10.2022.
//

import Foundation

struct SendEventsRequest: BackendEncodableRequest {
    let endpoint = HTTPEndpoint(
        method: .post,
        path: "/sdk/events/"
    )
    let headers: HTTPHeaders
    let stamp = Log.stamp
    var requestName = BackendRequestName.sendEvents

    /// The JSON body, gzipped when `gzip` was asked for and zlib managed it (then `headers` say so).
    private let body: Data

    init(userId: XeeUserId, events: [Data], gzip: Bool) {
        var plain = Data()
        plain.append(Constants.prefix)
        plain.append(contentsOf: events.joined(separator: Constants.separator))
        plain.append(Constants.suffix)
        var headers = HTTPHeaders().setUserProfileId(userId)
        if gzip, let packed = plain.gzipped() {
            headers["Content-Encoding"] = "gzip"
            body = packed
        } else {
            body = plain
        }
        self.headers = headers
    }

    /// Whether the body went out gzipped.
    var isGzipped: Bool { headers["Content-Encoding"] == "gzip" }

    enum CodingKeys: String, CodingKey {
        case events
    }

    private enum Constants {
        static let prefix = [
            "{", Backend.CodingKeys.data.stringValue,
            ":{", Backend.CodingKeys.type.stringValue,
            ":", "sdk_background_event",
            ",", Backend.CodingKeys.attributes.stringValue,
            ":{", CodingKeys.events.stringValue, ":[",
        ].joined(separator: "\"").data(using: .utf8)!

        static let separator = ",".data(using: .utf8)!
        static let suffix = "]}}}".data(using: .utf8)!
    }

    func getData(configuration _: HTTPConfiguration) throws -> Data? {
        body
    }

    /// Not used: `getData` returns the body built in `init`.
    func encode(to _: Encoder) throws {}
}

extension Backend.EventsExecutor {
    /// Sends one batch; `gzip` compresses the body. Returns whether it went out gzipped.
    @discardableResult
    func sendEvents(
        userId: XeeUserId,
        events: [Data],
        gzip: Bool
    ) async throws(EventsError) -> Bool {
        let request = SendEventsRequest(
            userId: userId,
            events: events,
            gzip: gzip
        )

        let baseUrl: URL
        do {
            baseUrl = try await manager.baseUrl(request, for: kind)
        } catch {
            throw EventsError.sending(HTTPError.perform(request.endpoint, error: error))
        }

        do {
            let _: HTTPEmptyResponse = try await session.perform(request, baseUrl: baseUrl)
        } catch {
            manager.handleNetworkState(kind, request.requestName, baseUrl, error)
            throw EventsError.sending(error)
        }
        return request.isGzipped
    }
}
