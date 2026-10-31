//  XeeSubscriptionOfferType.swift
//  XeeSDK
//
//  Created by Xee team.
//

import StoreKit

public enum XeeSubscriptionOfferType: String, Sendable {
    case introductory
    case promotional
    case winBack = "win_back"
    case code
}

extension XeeSubscriptionOfferType: Codable {}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, visionOS 1.0, *)
extension SK2Transaction.OfferType {
    var asSubscriptionOfferType: XeeSubscriptionOfferType? {
        switch self {
        case .introductory: .introductory
        case .promotional: .promotional
        case .winBack: .winBack
        case .code: .code
        default: nil
        }
    }
}
