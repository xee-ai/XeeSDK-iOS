// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  Environment.System.swift
//  XeeSDK
//
//  Created by Andrey Kyashkin on 19.12.2019.
//

import Foundation

#if canImport(UIKit)
import UIKit
#endif

private let log = Log.default

extension Environment {
    enum System {
        static var timezone: String { TimeZone.current.identifier }

        static var locale: XeeLocale { XeeLocale(Locale.preferredLanguages.first ?? Locale.current.identifier) }

        @XeeActor
        private static var _version: String?

        @XeeActor
        static var version: String {
            get async {
                if let result = _version { return result }

                #if os(macOS) || targetEnvironment(macCatalyst)
                let result = await MainActor.run { ProcessInfo().operatingSystemVersionString }
                #else
                let result = await UIDevice.current.systemVersion
                #endif

                _version = result
                return result
            }
        }

        @XeeActor
        private static var _name: String?

        @XeeActor
        static var name: String {
            get async {
                if let result = _name { return result }

                #if os(macOS) || targetEnvironment(macCatalyst)
                let result = "macOS"
                #else
                let result = await UIDevice.current.systemName
                #endif

                _name = result
                return result
            }
        }
    }
}
