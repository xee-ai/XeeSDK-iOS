// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  CrossPaywallStorage.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 21.08.2025.
//

import Foundation

private let log = Log.crossAB

@XeeActor
final class CrossPaywallStorage {
    private enum Constants {
        static let crossPaywallStateKey = "XeeSDK_Cross_Paywall_State"
    }

    private static let userDefaults = Storage.userDefaults

    private static var crossPaywallState: CrossPaywallState? = {
        do {
            return try userDefaults.getJSON(CrossPaywallState.self, forKey: Constants.crossPaywallStateKey)
        } catch {
            log.warn(error.localizedDescription)
            return nil
        }
    }()

    var state: CrossPaywallState? { Self.crossPaywallState }

    func setState(_ value: CrossPaywallState) {
        do {
            try Self.userDefaults.setJSON(value, forKey: Constants.crossPaywallStateKey)
            Self.crossPaywallState = value
            log.verbose("saving crossPaywallState success = \(value)")
        } catch {
            log.error("saving crossPaywallState fail. \(error.localizedDescription)")
        }
    }

    static func clear() {
        userDefaults.removeObject(forKey: Constants.crossPaywallStateKey)
        crossPaywallState = nil
        log.verbose("clear CrossPaywallStorage")
    }
}
