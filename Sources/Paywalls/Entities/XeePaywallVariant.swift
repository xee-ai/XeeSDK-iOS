// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  XeePaywallVariant.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 08.04.2025.
//

import Foundation

public struct XeePaywallVariant: PaywallContent {
    public let paywall: XeePaywall

    public let instanceIdentity: String

    /// An identifier of a variation, used to attribute purchases to this paywall.
    public let variationId: String

    /// A paywall name.
    public let name: String

    public let remoteConfig: XeeRemoteConfig?

    let products: [ProductReference]

    /// Array of related products ids.
    public var vendorProductIds: [String] { products.map { $0.productInfo.vendorId } }

    var requestLocale: XeeLocale
}

extension XeePaywallVariant: CustomStringConvertible {
    public var description: String {
        "(paywall:\(paywall), instanceIdentity: \(instanceIdentity), name: \(name), variationId: \(variationId)"
            + (remoteConfig.map { ", remoteConfig: \($0)" } ?? "")
            + ", vendorProductIds: [\(vendorProductIds.joined(separator: ", "))])"
    }
}

extension XeePaywallVariant: Codable {
    enum CodingKeys: String, CodingKey {
        case instanceIdentity = "paywall_variant_id"
        case variationId = "variation_id"
        case name = "paywall_variant_name"
        case remoteConfig = "remote_config"
        case products
        case requestLocale = "request_locale"
    }

    public init(from decoder: Decoder) throws {
        paywall = try decoder.userInfo.paywallOrNil ?? XeePaywall(from: decoder)

        let superContainer = try decoder.container(keyedBy: Backend.CodingKeys.self)

        let container =
            if superContainer.contains(.attributes) {
                try superContainer.nestedContainer(keyedBy: CodingKeys.self, forKey: .attributes)
            } else {
                try decoder.container(keyedBy: CodingKeys.self)
            }

        instanceIdentity = try container.decode(String.self, forKey: .instanceIdentity)
        name = try container.decode(String.self, forKey: .name)
        variationId = try container.decode(String.self, forKey: .variationId)
        remoteConfig = try container.decodeIfPresent(XeeRemoteConfig.self, forKey: .remoteConfig)

        products = try {
            var arrayContainer = try container.nestedUnkeyedContainer(forKey: .products)
            var products = [ProductReference]()
            var index = 0

            while !arrayContainer.isAtEnd {
                let product = try ProductReference(
                    from: arrayContainer.nestedContainer(keyedBy: ProductReference.CodingKeys.self),
                    index: index
                )
                index += 1
                products.append(product)
            }

            return products
        }()

        requestLocale = try decoder.userInfo.requestLocaleOrNil ?? container.decode(XeeLocale.self, forKey: .requestLocale)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(instanceIdentity, forKey: .instanceIdentity)
        try container.encode(name, forKey: .name)
        try container.encode(variationId, forKey: .variationId)
        try container.encodeIfPresent(remoteConfig, forKey: .remoteConfig)
        try container.encode(products, forKey: .products)
        try container.encode(requestLocale, forKey: .requestLocale)
        try paywall.encode(to: encoder)
    }
}
