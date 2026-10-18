// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  XeeProfile+Decoder.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 11.11.2025.
//

extension VH<XeeProfile> {
    static func decoder(
        _ response: HTTPDataResponse,
        _ configuration: HTTPCodableConfiguration?,
        _ request: HTTPRequest
    ) async throws -> HTTPResponse<VH<XeeProfile>> {
        let body = try response.decodeBody(Backend.Response.Data<XeeProfile>.self, with: configuration)
        return response.replaceBody(VH(body.value, hash: response.headers.getBackendResponseHash()))
    }
}

extension VH<XeeProfile>? {
    static func decoder(
        _ response: HTTPDataResponse,
        _ configuration: HTTPCodableConfiguration?,
        _ request: HTTPRequest
    ) async throws -> HTTPResponse<VH<XeeProfile>?> {
        guard !request.headers.hasSameBackendResponseHash(response.headers) else {
            return response.replaceBody(nil)
        }
        let body = try response.decodeBody(Backend.Response.Data<XeeProfile>.self, with: configuration)
        return response.replaceBody(VH(body.value, hash: response.headers.getBackendResponseHash()))
    }
}
