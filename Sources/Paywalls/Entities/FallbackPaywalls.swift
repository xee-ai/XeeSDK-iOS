// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  FallbackPaywalls.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 30.09.2022.
//

import Foundation

private let log = Log.fallbackPaywalls

struct FallbackPaywalls: Sendable {
    private let fileURL: URL
    private let head: Head
    var formatVersion: Int { head.formatVersion }
    var version: Int64 { head.version }

    init(fileURL url: URL) throws(XeeError) {
        guard url.isFileURL else {
            throw .isNotFileUrl()
        }
        let decoder = FallbackPaywalls.decoder()

        do {
            head = try decoder.decode(Head.self, from: Data(contentsOf: url))
        } catch {
            throw .decodingFallback(error)
        }
        fileURL = url
    }

    func contains(paywallId id: String) -> Bool? {
        head.paywallIds?.contains(id)
    }

    func restorePaywallVariant(
        _ id: String,
        withVariationId variationId: String,
        withInstanceIdentity: String,
        withPaywallRevision: Int
    ) -> XeePaywallVariant? {
        guard let chosen: XeePaywallChosen<XeePaywallVariant> = getPaywall(
            byPaywallId: id,
            withVariationId: variationId,
            userId: XeeUserId(profileId: "", customerId: nil),
            requestLocale: .defaultPaywallLocale
        )
        else { return nil }

        let paywallVariant = chosen.content

        guard paywallVariant.instanceIdentity == withInstanceIdentity,
              paywallVariant.paywall.revision == withPaywallRevision
        else {
            return nil
        }

        return paywallVariant
    }

    func getPaywall<Content: PaywallContent>(
        byPaywallId id: String,
        withVariationId: String?,
        userId: XeeUserId,
        requestLocale: XeeLocale
    ) -> XeePaywallChosen<Content>? {
        guard contains(paywallId: id) ?? true else { return nil }

        let draw: XeePaywall.Draw<Content>?

        do {
            draw = try FallbackPaywalls.decodePaywallVariation(
                Data(contentsOf: fileURL),
                withUserId: userId,
                withPaywallId: id,
                withVariationId: withVariationId,
                withRequestLocale: requestLocale,
                version: version
            )
        } catch {
            log.error(String(describing: error))
            draw = nil
        }

        Log.crossAB.verbose("fallbackFile request: paywallId = \(id), variationId = \(withVariationId ?? "nil DRAW") response: variationId = \(draw?.content.variationId ?? "nil")")

        return draw.map { .draw($0) }
    }
}

private extension FallbackPaywalls {
    struct Head: Sendable, Decodable {
        let paywallIds: Set<String>?
        let version: Int64
        let formatVersion: Int

        enum CodingKeys: String, CodingKey {
            case formatVersion = "version"
            case version = "response_created_at"
            case paywallIds = "developer_ids"
        }

        init(from decoder: Decoder) throws {
            let container = try decoder
                .container(keyedBy: Backend.CodingKeys.self)
                .nestedContainer(keyedBy: CodingKeys.self, forKey: .meta)

            let formatVersion = try container.decode(Int.self, forKey: .formatVersion)

            guard formatVersion == Xee.fallbackFormatVersion else {
                let error = Xee.fallbackFormatVersion > formatVersion
                    ? "The fallback paywallVariants version is not correct. Download a new one from the Xee Dashboard."
                    : "The fallback paywallVariants version is not correct. Please update the XeeSDK."
                log.error(error)

                Xee.trackSystemEvent(XeeInternalEventParameters(eventName: "fallback_wrong_version", params: [
                    "in_version": formatVersion,
                    "expected_version": Xee.fallbackFormatVersion,
                ]))

                throw XeeError.wrongVersionFallback(error)
            }

            self.formatVersion = formatVersion
            version = try container.decode(Int64.self, forKey: .version)
            paywallIds = try container.decodeIfPresent(Set<String>.self, forKey: .paywallIds)
        }
    }

    static func decodePaywallVariation<Content: PaywallContent>(
        _ data: Data,
        withUserId userId: XeeUserId,
        withPaywallId paywallId: String,
        withVariationId variationId: String?,
        withRequestLocale requestLocale: XeeLocale,
        version: Int64
    ) throws -> XeePaywall.Draw<Content>? {
        let jsonDecoder = FallbackPaywalls.decoder()
        jsonDecoder.userInfo.setPaywallId(paywallId)
        jsonDecoder.userInfo.setUserId(userId)
        jsonDecoder.userInfo.setRequestLocale(requestLocale)

        if let variationId {
            jsonDecoder.userInfo.setPaywallVariationId(variationId)
        }

        if let string = try? jsonDecoder.decode(Backend.Response.Data<String>.Paywall.self, from: data).value {
            let draw: XeePaywall.Draw<Content> = try decodePaywallVariation(
                jsonDecoder,
                string.data(using: .utf8) ?? Data(),
                version: version
            )
            return draw
        }

        guard let paywall = try jsonDecoder
            .decode(
                Backend.Response.Data<XeePaywall>.Paywall.Meta.self,
                from: data
            )
            .value?.replace(version: version)
        else { return nil }

        jsonDecoder.userInfo.setPaywall(paywall)

        return try jsonDecoder.decode(
            Backend.Response.Data<XeePaywall.Draw<Content>>.Paywall.Data.self,
            from: data
        ).value
    }

    private static func decodePaywallVariation<Content: PaywallContent>(
        _ jsonDecoder: JSONDecoder,
        _ data: Data,
        version: Int64
    ) throws -> XeePaywall.Draw<Content> {
        let paywall = try jsonDecoder.decode(
            Backend.Response.Meta<XeePaywall>.self,
            from: data
        ).value.replace(version: version)

        jsonDecoder.userInfo.setPaywall(paywall)

        return try jsonDecoder.decode(
            Backend.Response.Data<XeePaywall.Draw<Content>>.self,
            from: data
        ).value
    }
}

private extension FallbackPaywalls {
    static func decoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        Backend.configure(jsonDecoder: decoder)
        return decoder
    }
}

private extension Backend.Response.Data {
    private static func data(from decoder: Decoder) throws -> KeyedDecodingContainer<AnyCodingKeys> {
        try decoder
            .container(keyedBy: Backend.CodingKeys.self)
            .nestedContainer(keyedBy: AnyCodingKeys.self, forKey: .data)
    }

    struct Paywall: Sendable, Decodable where Value: Decodable, Value: Sendable {
        let value: Value?

        init(from decoder: Decoder) throws {
            value = try data(from: decoder)
                .decodeIfPresent(Value.self, forKey: AnyCodingKeys(stringValue: decoder.userInfo.paywallId))
        }

        private static func paywall(from decoder: Decoder) throws -> KeyedDecodingContainer<Backend.CodingKeys>? {
            let data = try data(from: decoder)
            let paywallId = try AnyCodingKeys(stringValue: decoder.userInfo.paywallId)

            guard data.contains(paywallId), try !data.decodeNil(forKey: paywallId) else {
                return nil
            }

            return try data.nestedContainer(keyedBy: Backend.CodingKeys.self, forKey: paywallId)
        }

        struct Data: Sendable, Decodable {
            let value: Value?

            init(from decoder: Decoder) throws {
                value = try paywall(from: decoder)?
                    .decode(Value.self, forKey: .data)
            }
        }

        struct Meta: Sendable, Decodable where Value: Decodable, Value: Sendable {
            let value: Value?

            init(from decoder: Decoder) throws {
                value = try paywall(from: decoder)?
                    .decode(Value.self, forKey: .meta)
            }
        }
    }
}
