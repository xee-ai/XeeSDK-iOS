// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  HTTPDecoder.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 26.08.2024
//

import Foundation

typealias HTTPDecoder<Body> = @Sendable (HTTPDataResponse, HTTPCodableConfiguration?, HTTPRequest) async throws -> HTTPResponse<Body>
