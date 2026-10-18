// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  SK1Product.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 01.02.2024
//

import StoreKit

typealias SK1Product = SKProduct

extension SK1Product {
    @inlinable
    var unfIsFamilyShareable: Bool {
        guard #available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, visionOS 1.0, *) else { return false }
        return isFamilyShareable
    }
}
