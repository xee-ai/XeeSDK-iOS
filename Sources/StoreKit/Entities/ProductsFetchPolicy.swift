// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  ProductsFetchPolicy.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 03.10.2024
//

import Foundation

enum ProductsFetchPolicy: Sendable, Hashable {
    case `default`
    case returnCacheDataElseLoad
}
