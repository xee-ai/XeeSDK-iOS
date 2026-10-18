// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  Environment.Device.idfa.swift
//  XeeSDK
//
//  Created by Andrey Kyashkin on 19.12.2019.
//

import Foundation

#if !XEE_KIDS_MODE && canImport(AdSupport)
import AdSupport
#endif

#if !XEE_KIDS_MODE && canImport(AppTrackingTransparency)
import AppTrackingTransparency
#endif

private let log = Log.default

extension XeeConfiguration {
    @XeeActor
    static var idfaCollectionDisabled = Self.default.idfaCollectionDisabled
}

extension Environment.Device {
    enum IdfaRetrievalStatus: Sendable {
        case notAvailable
        case notDetermined
        case denied
        case allowed
    }

    static var appTrackingTransparencyStatus: UInt? {
        #if XEE_KIDS_MODE || !canImport(AppTrackingTransparency)
        return nil
        #else
        if #available(iOS 14.0, macOS 11.0, tvOS 14.0, visionOS 1.0, *) {
            return ATTrackingManager.trackingAuthorizationStatus.rawValue
        } else {
            return nil
        }
        #endif
    }

    @XeeActor
    static var idfaRetrievalStatus: IdfaRetrievalStatus {
        get async {
            #if XEE_KIDS_MODE || !canImport(AdSupport) || targetEnvironment(simulator) || os(macOS)
            return .notAvailable
            #else
            guard !XeeConfiguration.idfaCollectionDisabled else {
                return .notAvailable
            }

            guard #available(iOS 14.5, macOS 11.0, tvOS 14.0, visionOS 1.0, *) else {
                return .allowed
            }

            #if !canImport(AppTrackingTransparency)
            return .notAvailable
            #else
            return await ATTrackingManager.canTakeIdfa
            #endif
            #endif
        }
    }

    @XeeActor
    private static var _idfa: String?

    @XeeActor
    static var idfa: String? {
        get async {
            #if XEE_KIDS_MODE || !canImport(AdSupport) || targetEnvironment(simulator) || os(macOS)
            return nil
            #else

            guard !XeeConfiguration.idfaCollectionDisabled else { return nil }

            if let result = _idfa { return result }

            // Get and return IDFA

            let result: String? = await MainActor.run {
                guard #available(iOS 14.5, macOS 11.0, tvOS 14.0, visionOS 1.0, *) else {
                    return ASIdentifierManager.shared().advertisingIdentifier.uuidString
                }

                #if canImport(AppTrackingTransparency)
                return switch ATTrackingManager.trackingAuthorizationStatus {
                case .authorized:
                    ASIdentifierManager.shared().advertisingIdentifier.uuidString
                default:
                    nil
                }
                #else
                return ASIdentifierManager.shared().advertisingIdentifier.uuidString
                #endif
            }

            if let result {
                _idfa = result
            }
            return result

            #endif
        }
    }
}

#if !XEE_KIDS_MODE && canImport(AppTrackingTransparency)
@available(iOS 14.0, macOS 11.0, tvOS 14.0, visionOS 1.0, *)
private extension ATTrackingManager {
    @MainActor
    static var canTakeIdfa: Environment.Device.IdfaRetrievalStatus {
        switch ATTrackingManager.trackingAuthorizationStatus {
        case .notDetermined: return .notDetermined
        case .restricted, .denied: return .denied
        case .authorized: return .allowed
        @unknown default: return .notDetermined
        }
    }
}
#endif
