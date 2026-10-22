// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  Xee+Paywalls.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 01.11.2023
//

import Foundation

private let log = Log.default

extension Xee {
    /// Xee allows you remotely configure the products that will be displayed in your app. This way you don't have to hardcode the products and can dynamically change offers or run A/B tests without app releases.
    ///
    /// Read more on the [Xee Documentation](https://xee.invalid/docs)
    ///
    /// - Parameters:
    ///   - paywallId: The identifier of the desired paywall. This is the value you specified when you created the paywall in the Xee Dashboard.
    ///   - locale: The identifier of the paywall [localization](https://xee.invalid/docs).
    ///             This parameter is expected to be a language code composed of one or more subtags separated by the "-" character. The first subtag is for the language, the second one is for the region (The support for regions will be added later).
    ///             Example: "en" means English, "en-US" represents US English.
    ///             If the parameter is omitted, the paywall will be returned in the default locale.
    ///   - fetchPolicy: by default SDK will try to load data from server and will return cached data in case of failure. Otherwise use `.returnCacheDataElseLoad` to return cached data if it exists.
    /// - Returns: The ``XeePaywallVariant`` object. This model contains the list of the products ids, paywall's identifier, custom payload, and several other properties.
    /// - Throws: An ``XeeError`` object
    public nonisolated static func getPaywallVariant(
        paywallId: String,
        locale: String? = nil,
        fetchPolicy: XeePaywallFetchPolicy = .default,
        loadTimeout: TimeInterval? = nil
    ) async throws(XeeError) -> XeePaywallVariant {
        let loadTimeout = (loadTimeout ?? .defaultLoadPaywallTimeout).allowedLoadPaywallTimeout
        let locale = locale.trimmed.nonEmptyOrNil.map { XeeLocale($0) } ?? .defaultPaywallLocale
        let paywallId = paywallId.trimmed
        // TODO: throw error if paywallId isEmpty

        let logParams: EventParameters = [
            "paywall_id": paywallId,
            "locale": locale,
            "fetch_policy": fetchPolicy,
            "load_timeout": loadTimeout.asMilliseconds,
        ]

        return try await withActivatedSDK(methodName: .getPaywallVariant, logParams: logParams) { sdk throws(XeeError) in
            let paywallVariant: XeePaywallVariant = try await sdk.getPaywall(
                paywallId: paywallId,
                locale: locale,
                fetchPolicy: fetchPolicy,
                loadTimeout: loadTimeout
            )
            return paywallVariant
        }
    }

    private func getPaywall<Content: PaywallContent>(
        paywallId: String,
        locale: XeeLocale,
        fetchPolicy: XeePaywallFetchPolicy,
        loadTimeout: TaskDuration
    ) async throws(XeeError) -> Content {
        do {
            return try await fetchPaywallOrFallbackPaywall(
                paywallId,
                locale,
                fetchPolicy,
                loadTimeout
            )
        } catch {
            if error.isProfileWasChanged { throw error }

            if let content: Content = getCacheOrFallbackFilePaywall(
                profileStorage.userId,
                paywallId,
                locale
            ) {
                return content
            } else {
                throw error
            }
        }
    }

    private func fetchPaywallOrFallbackPaywall<Content: PaywallContent>(
        _ paywallId: String,
        _ locale: XeeLocale,
        _ fetchPolicy: XeePaywallFetchPolicy,
        _ loadTimeout: TaskDuration
    ) async throws(XeeError) -> Content {
        var userId = profileStorage.userId
        let startTaskTime = Date()

        do {
            return try await withThrowingTimeout(loadTimeout - .milliseconds(500)) {
                let createdUserId = try await self.createdProfileManager.userId
                if createdUserId.isNotEqualProfileId(userId) {
                    log.verbose("fetchPaywallOrFallbackPaywall: profile changed from \(userId) to \(createdUserId)")
                    userId = createdUserId
                }

                return try await self.fetchPaywall(
                    paywallId,
                    locale,
                    withPolicy: fetchPolicy,
                    forUserId: userId
                )
            }

        } catch let error as XeeError {
            guard error.canUseFallbackServer else { throw error }
        } catch {
            guard error is TimeoutError else { throw .unknown(error) }
        }

        return try await fetchFallbackPaywall(
            paywallId,
            locale,
            forUserId: userId,
            withTimeout: loadTimeout.asTimeInterval + startTaskTime.timeIntervalSinceNow
        )
    }

    private func fetchPaywall<Content: PaywallContent>(
        _ paywallId: String,
        _ locale: XeeLocale,
        withPolicy fetchPolicy: XeePaywallFetchPolicy,
        forUserId userId: XeeUserId
    ) async throws(XeeError) -> Content {
        let manager = try profileManager(withProfileId: userId).orThrows

        let cached: Content? = manager
            .paywallStorage
            .getPaywallById(
                paywallId,
                withLocale: locale,
                orDefaultLocale: true,
                withVariationId: nil
            )?
            .withFetchPolicy(fetchPolicy)?
            .value

        if let cached { return cached }

        return try await self.fetchPaywall(
            paywallId,
            locale,
            forUserId: userId
        )
    }

    private func fetchPaywall<Content: PaywallContent>(
        _ paywallId: String,
        _ locale: XeeLocale,
        forUserId userId: XeeUserId
    ) async throws(XeeError) -> Content {
        while !Task.isCancelled {
            let (segmentId, cached, isTestUser) = try { () throws(XeeError) in
                let manager = try profileManager(withProfileId: userId).orThrows
                let cached: Content? = manager.paywallStorage
                    .getPaywallById(
                        paywallId,
                        withLocale: locale,
                        orDefaultLocale: false,
                        withVariationId: nil
                    )?
                    .value
                return (manager.segmentId, cached, manager.isTestUser)
            }()

            do throws(HTTPError) {
                var chosen: XeePaywallChosen<Content> = try await httpSession.fetchPaywallVariations(
                    apiKeyPrefix: apiKeyPrefix,
                    userId: userId,
                    paywallId: paywallId,
                    locale: locale,
                    segmentId: segmentId,
                    cached: cached,
                    disableServerCache: isTestUser
                )

                if let manager = try? profileManager(withProfileId: userId) {
                    chosen = manager.paywallStorage.savedPaywallChosen(chosen)
                }

                Xee.trackEventIfNeed(chosen)
                return chosen.content

            } catch {
                if error.has(decodingError: [.notFoundVariationId]) { continue }

                guard Backend.wrongProfileSegmentId(error),
                      try await updateSegmentId(for: userId, oldSegmentId: segmentId)
                else {
                    throw error.asXeeError
                }
            }
        }

        throw XeeError.taskCancelled()

        func updateSegmentId(for userId: XeeUserId, oldSegmentId: String) async throws(XeeError) -> Bool {
            let manager = try profileManager(withProfileId: userId).orThrows
            guard manager.segmentId == oldSegmentId else { return true }
            return await manager.fetchSegmentId() != oldSegmentId
        }
    }

    func getCacheOrFallbackFilePaywall<Content: PaywallContent>(
        _ userId: XeeUserId,
        _ paywallId: String,
        _ locale: XeeLocale
    ) -> Content? {
        let chosen: XeePaywallChosen<Content>?
        if let manager = try? profileManager(withProfileId: userId) {
            chosen = manager.paywallStorage.getPaywallWithFallback(
                byPaywallId: paywallId,
                withVariationId: nil,
                userId: userId,
                locale: locale
            )
        } else {
            chosen = Xee.fallbackPaywalls?.getPaywall(
                byPaywallId: paywallId,
                withVariationId: nil,
                userId: userId,
                requestLocale: locale
            )
        }

        guard let chosen else { return nil }

        Xee.trackEventIfNeed(chosen)
        return chosen.content
    }

    private func fetchFallbackPaywall<Content: PaywallContent>(
        _ paywallId: String,
        _ locale: XeeLocale,
        forUserId userId: XeeUserId,
        withTimeout timeoutInterval: TimeInterval?
    ) async throws(XeeError) -> Content {
        var params: (cached: Content?, isTestUser: Bool)?
        while !Task.isCancelled {
            params = {
                guard let manager = try? profileManager(withProfileId: userId) else { return nil }
                return (
                    cached: manager.paywallStorage.getPaywallById(
                        paywallId,
                        withLocale: locale,
                        orDefaultLocale: false,
                        withVariationId: nil
                    )?.value,
                    isTestUser: manager.isTestUser
                )
            }() ?? params

            if let cached = params?.cached {
                return cached
            }

            do throws(HTTPError) {
                var chosen: XeePaywallChosen<Content> = try await httpFallbackSession.fetchFallbackPaywallVariations(
                    apiKeyPrefix: apiKeyPrefix,
                    userId: userId,
                    paywallId: paywallId,
                    locale: locale,
                    cached: params?.cached,
                    disableServerCache: params?.isTestUser ?? false,
                    timeoutInterval: timeoutInterval
                )

                if let manager = try? profileManager(withProfileId: userId) {
                    chosen = manager.paywallStorage.savedPaywallChosen(chosen)
                }

                Xee.trackEventIfNeed(chosen)
                return chosen.content

            } catch {
                if error.has(decodingError: [.notFoundVariationId]) {
                    continue
                } else {
                    throw error.asXeeError
                }
            }
        }
        throw XeeError.taskCancelled()
    }
}

extension TimeInterval {
    static let defaultLoadPaywallTimeout: TimeInterval = 5.0
    static let minimumLoadPaywallVariantTimeout: TimeInterval = 1.0

    var allowedLoadPaywallTimeout: TaskDuration {
        let minimum: TimeInterval = .minimumLoadPaywallVariantTimeout
        guard self < minimum else { return TaskDuration(self) }
        log.warn("The  paywall load timeout parameter cannot be less than \(minimum)s")
        return TaskDuration(minimum)
    }
}

private extension Error {}

private extension XeeError {
    var canUseFallbackServer: Bool {
        if let error = wrapped as? HTTPError,
           Backend.canUseFallbackServer(error)
        {
            true
        } else {
            false
        }
    }

    var isProfileWasChanged: Bool {
        if let error = wrapped as? InternalXeeError,
           case .profileWasChanged = error
        {
            true
        } else {
            false
        }
    }
}

private extension HTTPError {
    func has(decodingError: Set<PaywallDecodingError>) -> Bool {
        guard case let .decoding(_, _, _, _, _, value) = self,
              let value = value as? PaywallDecodingError
        else { return false }

        return decodingError.contains(value)
    }
}
