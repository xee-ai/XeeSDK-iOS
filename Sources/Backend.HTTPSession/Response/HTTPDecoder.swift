//  HTTPDecoder.swift
//  XeeSDK
//
//  Created by Xee team.
//

import Foundation

typealias HTTPDecoder<Body> = @Sendable (HTTPDataResponse, HTTPCodableConfiguration?, HTTPRequest) async throws -> HTTPResponse<Body>
