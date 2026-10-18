// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  Environment.Device.webUserAgent.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 24.09.2024
//

import Foundation

#if canImport(WebKit)
import WebKit
#endif

private let log = Log.default

extension Environment.Device {
    @XeeActor
    private static var _userAgent: String??

    @XeeActor
    static var webUserAgent: String? {
        get async {
            if let result = _userAgent {
                return result
            }
            
            #if canImport(WebKit)
            let result = await WKWebView().value(forKey: "userAgent").flatMap { $0 as? String }
            #else
            let result = nil
            #endif

            _userAgent = .some(result)
            return result
        }
    }
}
