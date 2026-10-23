// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  Event.Name.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 07.10.2022.
//

import Foundation

extension Event {
    static var defaultBlackList: Set<String> { Set([Name.system.rawValue]) }
    private enum Name: String, Sendable, Hashable {
        case appOpened = "app_opened"
        case paywallShowed = "paywall_showed"

        case system = "system_log"
        case paywallVariantAssigned = "paywall_variation_assigned"

        case profileRefundSaverSettings = "profile_refund_saver_settings"
        case activity = "xee_activity"
        case track = "xee_track"
    }

    var name: String {
        let name: Name =
            switch self {
            case .appOpened:
                .appOpened
            case .paywallShowed:
                .paywallShowed
            case .system:
                .system
            case .paywallVariantAssigned:
                .paywallVariantAssigned
            case .сonsentToCollectingRefundData:
                .profileRefundSaverSettings
            case .refundPreference:
                .profileRefundSaverSettings
            case .activity:
                .activity
            case .track:
                .track
            }

        return name.rawValue
    }
}
