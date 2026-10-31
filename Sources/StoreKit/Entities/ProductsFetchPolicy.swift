//  ProductsFetchPolicy.swift
//  XeeSDK
//
//  Created by Xee team.
//

import Foundation

enum ProductsFetchPolicy: Sendable, Hashable {
    case `default`
    case returnCacheDataElseLoad
}
