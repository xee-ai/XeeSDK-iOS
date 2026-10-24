// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  Backend.Headers.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 08.09.2022.
//

import Foundation

extension Backend.Request {
    fileprivate static let authorizationHeaderKey = "Authorization"
    fileprivate static let hashHeaderKey = "xee-sdk-previous-response-hash"
    fileprivate static let paywallVariantLocaleHeaderKey = "xee-paywall-locale"
    fileprivate static let paywallVariantBuilderLocaleHeaderKey = "xee-paywall-builder-locale"
    fileprivate static let paywallVariantBuilderVersionHeaderKey = "xee-paywall-builder-version"
    fileprivate static let paywallVariantBuilderConfigurationFormatVersionHeaderKey = "xee-paywall-builder-config-format-version"
    fileprivate static let segmentIdHeaderKey = "xee-profile-segment-hash"

    fileprivate static let profileIdHeaderKey = "xee-sdk-profile-id"
    fileprivate static let sdkVersionHeaderKey = "xee-sdk-version"
    fileprivate static let sdkPlatformHeaderKey = "xee-sdk-platform"
    fileprivate static let sdkStoreHeaderKey = "xee-sdk-store"
    fileprivate static let sessionIDHeaderKey = "xee-sdk-session"
    fileprivate static let appVersionHeaderKey = "xee-app-version"
    fileprivate static let appBuildHeaderKey = "xee-app-build"

    fileprivate static let isSandboxHeaderKey = "xee-sdk-sandbox-mode-enabled"
    fileprivate static let isObserveModeHeaderKey = "xee-sdk-observer-mode-enabled"
    fileprivate static let storeKit2EnabledHeaderKey = "xee-sdk-storekit2-enabled"
    fileprivate static let appInstallIdHeaderKey = "xee-sdk-device-id"
    fileprivate static let crossSDKVersionHeaderKey = "xee-sdk-crossplatform-version"
    fileprivate static let crossSDKPlatformHeaderKey = "xee-sdk-crossplatform-name"

    static func globalHeadersWithStoreKit(_ configuration: XeeConfiguration, _ environment: Environment) -> HTTPHeaders {
        var headers = globalHeaders(configuration, environment)
        headers[sdkStoreHeaderKey] = Environment.StoreKit.name
        headers[isObserveModeHeaderKey] = configuration.observerMode ? "true" : "false"
        headers[storeKit2EnabledHeaderKey] = Environment.StoreKit.storeKit2Enabled ? "enabled" : "unavailable"
        return headers
    }

    static func globalHeaders(_ configuration: XeeConfiguration, _ environment: Environment) -> HTTPHeaders {
        var headers = [
            authorizationHeaderKey: "Api-Key \(configuration.apiKey)",
            sdkVersionHeaderKey: Xee.SDKVersion,
            sdkPlatformHeaderKey: environment.system.name,
            sessionIDHeaderKey: environment.sessionIdentifier,
            appInstallIdHeaderKey: environment.application.installationIdentifier,
        ]

        if let ver = environment.application.version {
            headers[appVersionHeaderKey] = ver
        }

        // The build picks which version of each paywall and view the server sends: the newest one
        // pushed for this build or an older one, so this build's code can read every key it gets.
        headers = headers.setAppBuild(environment.application.build)

        if let crossPlatformSDK = configuration.crossPlatformSDK {
            headers[crossSDKPlatformHeaderKey] = crossPlatformSDK.name
            headers[crossSDKVersionHeaderKey] = crossPlatformSDK.version
        }

        return headers
    }
}

private extension Backend.Response {
    static let hashHeaderKey = "x-response-hash"
    static let requestIdHeaderKey = "request-id"
    static let retryAfterKey = "retry-after"
}

extension HTTPHeaders {
    func setPaywallVariantLocale(_ locale: XeeLocale?) -> Self {
        updateOrRemoveValue(locale?.id, forKey: Backend.Request.paywallVariantLocaleHeaderKey)
    }

    /// The app's CFBundleVersion, trimmed; no header when it is missing or empty.
    func setAppBuild(_ build: String?) -> Self {
        let trimmed = build?.trimmingCharacters(in: .whitespacesAndNewlines)
        return updateOrRemoveValue(trimmed?.isEmpty == false ? trimmed : nil, forKey: Backend.Request.appBuildHeaderKey)
    }

    func setPaywallVariantBuilderLocale(_ locale: XeeLocale?) -> Self {
        updateOrRemoveValue(locale?.id, forKey: Backend.Request.paywallVariantBuilderLocaleHeaderKey)
    }

    func setPaywallVariantBuilderVersion(_ version: String?) -> Self {
        updateOrRemoveValue(version, forKey: Backend.Request.paywallVariantBuilderVersionHeaderKey)
    }

    func setPaywallVariantBuilderConfigurationFormatVersion(_ version: String?) -> Self {
        updateOrRemoveValue(version, forKey: Backend.Request.paywallVariantBuilderConfigurationFormatVersionHeaderKey)
    }

    func setSegmentId(_ id: String?) -> Self {
        updateOrRemoveValue(id, forKey: Backend.Request.segmentIdHeaderKey)
    }

    func setBackendResponseHash(_ hash: String?) -> Self {
        updateOrRemoveValue(hash, forKey: Backend.Request.hashHeaderKey)
    }

    func setUserProfileId(_ userId: XeeUserId?) -> Self {
        updateOrRemoveValue(userId?.profileId, forKey: Backend.Request.profileIdHeaderKey)
    }

    private func updateOrRemoveValue(_ value: String?, forKey key: String) -> Self {
        var headers = self
        if let value {
            headers.updateValue(value, forKey: key)
        } else {
            headers.removeValue(forKey: key)
        }
        return headers
    }

    func hasSameBackendResponseHash(_ responseHeaders: HTTPHeaders) -> Bool {
        guard let requestHash = self[Backend.Request.hashHeaderKey],
              let responseHash = responseHeaders.getBackendResponseHash(),
              requestHash == responseHash
        else { return false }
        return true
    }
}

extension HTTPHeaders {
    func getRetryAfter(_ now: Date = Date()) -> Date? {
        guard let value = value(forHTTPHeaderField: Backend.Response.retryAfterKey),
              let duration = TimeInterval(value)
        else { return nil }
        return now.addingTimeInterval(duration)
    }

    func getBackendResponseHash() -> String? {
        value(forHTTPHeaderField: Backend.Response.hashHeaderKey)
    }

    func getBackendRequestId() -> String? {
        value(forHTTPHeaderField: Backend.Response.requestIdHeaderKey)
    }
}
