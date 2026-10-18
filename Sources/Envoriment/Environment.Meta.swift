// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  Environment.Meta.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 26.09.2022.
//

import Foundation

extension Environment {
    struct Meta: Sendable, Encodable {
        let locale: XeeLocale
        let timezone: String
        let idfv: String?
        let idfa: String?
        let ipV4Address: String?
        let storefront: XeeStorefront?
        let webUserAgent: String?
        let environment: Environment

        @XeeActor
        init(includedAnalyticIds: Bool) async {
            locale = System.locale
            timezone = System.timezone
            ipV4Address = Device.ipV4Address
            storefront = await Environment.StoreKit.storefront
            webUserAgent = await Device.webUserAgent
            environment = await Environment.instance
            if includedAnalyticIds {
                idfv = await Device.idfv
                idfa = await Device.idfa
            } else {
                idfv = nil
                idfa = nil
            }
        }

        var appTrackingTransparencyStatus: UInt? { Device.appTrackingTransparencyStatus }

        enum CodingKeys: String, CodingKey {
            case appInstallId = "device_id"
            case SDKVersion = "adapty_sdk_version"
            case appBuild = "app_build"
            case appVersion = "app_version"
            case webUserAgent = "user_agent"
            case device
            case locale
            case sysVersion = "os"
            case sysName = "platform"
            case timezone
            case idfa
            case idfv
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(environment.application.installationIdentifier, forKey: .appInstallId)
            try container.encode(Xee.SDKVersion, forKey: .SDKVersion)
            try container.encodeIfPresent(environment.application.build, forKey: .appBuild)
            try container.encodeIfPresent(environment.application.version, forKey: .appVersion)
            try container.encodeIfPresent(webUserAgent, forKey: .webUserAgent)
            try container.encode(Device.model, forKey: .device)
            try container.encode(environment.system.version, forKey: .sysVersion)
            try container.encode(environment.system.name, forKey: .sysName)
            try container.encodeIfPresent(locale, forKey: .locale)
            try container.encodeIfPresent(timezone, forKey: .timezone)
            try container.encodeIfPresent(idfv, forKey: .idfv)
            try container.encodeIfPresent(idfa, forKey: .idfa)
        }
    }
}
