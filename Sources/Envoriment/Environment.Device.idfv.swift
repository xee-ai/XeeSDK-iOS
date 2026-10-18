// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  Environment.Device.idfv.swift
//  XeeSDK
//
//  Created by Andrey Kyashkin on 19.12.2019.
//

#if canImport(UIKit)
import UIKit
#elseif os(macOS)
import AppKit
#endif

private let log = Log.default

extension Environment.Device {
    @XeeActor
    private static var _idfv: String??

    @XeeActor
    static var idfv: String? {
        get async {
            if let result = _idfv {
                return result
            }

            #if os(macOS) || targetEnvironment(macCatalyst)
            let result: String? = await MainActor.run {
                let matchingDict = IOServiceMatching("IOPlatformExpertDevice")
                let platformExpert = IOServiceGetMatchingService(kIOMasterPortDefault, matchingDict)
                defer { IOObjectRelease(platformExpert) }

                guard platformExpert != 0 else { return nil }
                return IORegistryEntryCreateCFProperty(
                    platformExpert,
                    kIOPlatformUUIDKey as CFString,
                    kCFAllocatorDefault,
                    0
                ).takeRetainedValue() as? String
            }
            #else
            let result = await UIDevice.current.identifierForVendor?.uuidString
            #endif

            _idfv = .some(result)
            return result
        }
    }
}
