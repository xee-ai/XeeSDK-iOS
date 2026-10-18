// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  Xee+Completion.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 19.09.2024
//

import StoreKit

public typealias XeeResult<Success> = Swift.Result<Success, XeeError>

public typealias XeeErrorCompletion = @Sendable (XeeError?) -> Void
public typealias XeeResultCompletion<Success> = @Sendable (XeeResult<Success>) -> Void
package typealias XeeResultTask<Success> = Task<XeeResult<Success>, Never>

public extension Result where Failure == XeeError {
    var error: XeeError? {
        switch self {
        case let .failure(error): error
        default: nil
        }
    }
}

package extension XeeConfiguration {
    @XeeActor
    static var callbackDispatchQueue: DispatchQueue?
}

public extension Xee {
    /// Use this method to initialize the Xee SDK.
    ///
    /// Call this method in the `application(_:didFinishLaunchingWithOptions:)`.
    ///
    /// - Parameter apiKey: You can find it in your app settings in [Xee Dashboard](https://xee.invalid/docs) *App settings* > *General*.
    /// - Parameter observerMode: A boolean value controlling [Observer mode](https://xee.invalid/docs). Turn it on if you handle purchases and subscription status yourself and use Xee for sending subscription events and analytics
    /// - Parameter customerUserId: User identifier in your system
    /// - Parameter dispatchQueue: Specify the Dispatch Queue where callbacks will be executed
    /// - Parameter completion: Result callback
    nonisolated static func activate(
        _ apiKey: String,
        observerMode: Bool = false,
        customerUserId: String? = nil,
        _ completion: XeeErrorCompletion? = nil
    ) {
        withCompletion(completion) { () async throws(XeeError) in
            try await activate(apiKey, observerMode: observerMode, customerUserId: customerUserId)
        }
    }

    /// Use this method to initialize the Xee SDK.
    ///
    /// Call this method in the `application(_:didFinishLaunchingWithOptions:)`.
    ///
    /// - Parameter configuration: `XeeConfiguration` which allows to configure Xee SDK
    /// - Parameter completion: Result callback
    nonisolated static func activate(
        with configuration: XeeConfiguration,
        _ completion: XeeErrorCompletion? = nil
    ) {
        withCompletion(completion) { () async throws(XeeError) in
            try await activate(with: configuration)
        }
    }

    /// Use this method for identifying user with it's user id in your system.
    ///
    /// If you don't have a user id on SDK configuration, you can set it later at any time with `.identify()` method. The most common cases are after registration/authorization when the user switches from being an anonymous user to an authenticated user.
    ///
    /// - Parameters:
    ///   - customerUserId: User identifier in your system.
    ///   - completion: Result callback.
    nonisolated static func identify(
        _ customerUserId: String,
        withAppAccountToken appAccountToken: UUID? = nil,
        _ completion: XeeErrorCompletion? = nil
    ) {
        withCompletion(completion) { () async throws(XeeError) in
            try await identify(customerUserId, withAppAccountToken: appAccountToken)
        }
    }

    /// You can logout the user anytime by calling this method.
    /// - Parameter completion: Result callback.
    nonisolated static func logout(
        _ completion: XeeErrorCompletion? = nil
    ) {
        withCompletion(completion) { () async throws(XeeError) in
            try await logout()
        }
    }

    /// The main function for getting a user profile. Allows you to define the level of access, as well as other parameters.
    ///
    /// The `getProfile` method provides the most up-to-date result as it always tries to query the API. If for some reason (e.g. no internet connection), the Xee SDK fails to retrieve information from the server, the data from cache will be returned. It is also important to note that the Xee SDK updates XeeProfile cache on a regular basis, in order to keep this information as up-to-date as possible.
    ///
    /// - Parameter completion: the result containing a `XeeProfile` object. This model contains info about access levels, subscriptions, and non-subscription purchases. Generally, you have to check only access level status to determine whether the user has premium access to the app.
    nonisolated static func getProfile(
        _ completion: @escaping XeeResultCompletion<XeeProfile>
    ) {
        withCompletion(completion) { () async throws(XeeError) in
            try await getProfile()
        }
    }

    /// You can set optional attributes such as email, phone number, etc, to the user of your app. You can then use attributes to create user [segments](https://xee.invalid/docs) or just view them in CRM.
    ///
    /// Read more on the [Xee Documentation](https://xee.invalid/docs)
    ///
    /// - Parameter params: use `XeeProfileParameters.Builder` class to build this object.
    nonisolated static func updateProfile(
        params: XeeProfileParameters,
        _ completion: XeeErrorCompletion? = nil
    ) {
        withCompletion(completion) { () async throws(XeeError) in
            try await updateProfile(params: params)
        }
    }

    /// To set attribution data for the profile, use this method.
    ///
    /// Read more on the [Xee Documentation](https://xee.invalid/docs)
    ///
    /// - Parameter attribution: a dictionary containing attribution (conversion) data.
    /// - Parameter source: a source of attribution.
    /// - Parameter completion: A result containing an optional error.
    nonisolated static func updateAttribution(
        _ attribution: [AnyHashable: Any],
        source: String,
        _ completion: XeeErrorCompletion? = nil
    ) {
        let attributionJson: String
        do {
            let data = try JSONSerialization.data(withJSONObject: attribution)
            attributionJson = String(decoding: data, as: UTF8.self)
        } catch {
            completion?(.wrongAttributeData(error))
            return
        }

        withCompletion(completion) { () async throws(XeeError) in
            try await updateAttribution(attributionJson, source: source)
        }
    }

    nonisolated static func setIntegrationIdentifier(
        key: String,
        value: String,
        _ completion: XeeErrorCompletion? = nil
    ) {
        withCompletion(completion) { () async throws(XeeError) in
            try await setIntegrationIdentifier(key: key, value: value)
        }
    }

    nonisolated static func getCurrentInstallationStatus(
        _ completion: @escaping XeeResultCompletion<XeeInstallationStatus>
    ) {
        withCompletion(completion) { () async throws(XeeError) in
            try await getCurrentInstallationStatus()
        }
    }

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
    ///   - fetchPolicy:by default SDK will try to load data from server and will return cached data in case of failure. Otherwise use `.returnCacheDataElseLoad` to return cached data if it exists.
    ///   - loadTimeout: This value limits the timeout for this method. If the timeout is reached, cached data or local fallback will be returned.
    ///   - completion: A result containing the ``XeePaywallVariant`` object. This model contains the list of the products ids, paywall's identifier, custom payload, and several other properties.
    nonisolated static func getPaywallVariant(
        paywallId: String,
        locale: String? = nil,
        fetchPolicy: XeePaywallFetchPolicy = .default,
        loadTimeout: TimeInterval? = nil,
        _ completion: @escaping XeeResultCompletion<XeePaywallVariant>
    ) {
        withCompletion(completion) { () async throws(XeeError) in
            try await getPaywallVariant(
                paywallId: paywallId,
                locale: locale,
                fetchPolicy: fetchPolicy,
                loadTimeout: loadTimeout
            )
        }
    }

    nonisolated static func getOnboarding(
        paywallId: String,
        locale: String? = nil,
        fetchPolicy: XeePaywallFetchPolicy = .default,
        loadTimeout: TimeInterval? = nil,
        _ completion: @escaping XeeResultCompletion<XeeOnboarding>
    ) {
        withCompletion(completion) { () async throws(XeeError) in
            try await getOnboarding(
                paywallId: paywallId,
                locale: locale,
                fetchPolicy: fetchPolicy,
                loadTimeout: loadTimeout
            )
        }
    }

    /// This method enables you to retrieve the paywall from the Default Audience without having to wait for the Xee SDK to send all the user information required for segmentation to the server.
    ///
    /// - Parameters:
    ///   - paywallId: The identifier of the desired paywall. This is the value you specified when you created the paywall in the Xee Dashboard.
    ///   - locale: The identifier of the paywall [localization](https://xee.invalid/docs).
    ///             This parameter is expected to be a language code composed of one or more subtags separated by the "-" character. The first subtag is for the language, the second one is for the region (The support for regions will be added later).
    ///             Example: "en" means English, "en-US" represents US English.
    ///             If the parameter is omitted, the paywall will be returned in the default locale.
    ///   - fetchPolicy:by default SDK will try to load data from server and will return cached data in case of failure. Otherwise use `.returnCacheDataElseLoad` to return cached data if it exists.
    ///   - completion: A result containing the ``XeePaywallVariant`` object. This model contains the list of the products ids, paywall's identifier, custom payload, and several other properties.
    nonisolated static func getPaywallVariantForDefaultAudience(
        paywallId: String,
        locale: String? = nil,
        fetchPolicy: XeePaywallFetchPolicy = .default,
        _ completion: @escaping XeeResultCompletion<XeePaywallVariant>
    ) {
        withCompletion(completion) { () async throws(XeeError) in
            try await getPaywallVariantForDefaultAudience(
                paywallId: paywallId,
                locale: locale,
                fetchPolicy: fetchPolicy
            )
        }
    }

    nonisolated static func getOnboardingForDefaultAudience(
        paywallId: String,
        locale: String? = nil,
        fetchPolicy: XeePaywallFetchPolicy = .default,
        _ completion: @escaping XeeResultCompletion<XeeOnboarding>
    ) {
        withCompletion(completion) { () async throws(XeeError) in
            try await getOnboardingForDefaultAudience(
                paywallId: paywallId,
                locale: locale,
                fetchPolicy: fetchPolicy
            )
        }
    }

    /// To set fallback paywall variants, use this method. You should pass exactly the same payload you're getting from Xee backend. You can copy it from Xee Dashboard.
    ///
    /// Xee allows you to provide fallback paywall variants that will be used when a user opens the app for the first time and there's no internet connection. Or in the rare case when Xee backend is down and there's no cache on the device.
    ///
    /// Read more on the [Xee Documentation](https://xee.invalid/docs)
    ///
    /// - Parameters:
    ///   - fileURL:
    ///   - completion: Result callback.
    nonisolated static func setFallback(
        fileURL url: URL,
        _ completion: XeeErrorCompletion? = nil
    ) {
        withCompletion(completion) { () async throws(XeeError) in
            try await setFallback(fileURL: url)
        }
    }

    /// Once you have a ``XeePaywallVariant``, fetch corresponding products array using this method.
    ///
    /// Read more on the [Xee Documentation](https://xee.invalid/docs)
    ///
    /// - Parameters:
    ///   - paywall: the ``XeePaywallVariant`` for which you want to get a products
    ///   - completion: A result containing the ``XeePaywallVariantProduct`` objects array. The order will be the same as in the paywall variants object. You can present them in your UI
    nonisolated static func getPaywallVariantProducts(
        paywallVariant: XeePaywallVariant,
        _ completion: @escaping XeeResultCompletion<[XeePaywallVariantProduct]>
    ) {
        withCompletion(completion) { () async throws(XeeError) in
            try await getPaywallVariantProducts(paywallVariant: paywallVariant)
        }
    }

    nonisolated static func getPaywallVariantProductsWithoutDeterminingOffer(
        paywallVariant: XeePaywallVariant,
        _ completion: @escaping XeeResultCompletion<[XeePaywallVariantProductWithoutDeterminingOffer]>
    ) {
        withCompletion(completion) { () async throws(XeeError) in
            try await getPaywallVariantProductsWithoutDeterminingOffer(paywallVariant: paywallVariant)
        }
    }

    /// To make the purchase, you have to call this method.
    ///
    /// Read more on the [Xee Documentation](https://xee.invalid/docs)
    ///
    /// - Parameters:
    ///   - product: a ``XeePaywallVariantProduct`` object retrieved from the paywall.
    ///   - completion: A result containing the ``XeePurchaseResult`` object.
    nonisolated static func makePurchase(
        product: XeePaywallVariantProduct,
        _ completion: @escaping XeeResultCompletion<XeePurchaseResult>
    ) {
        withCompletion(completion) { () async throws(XeeError) in
            try await makePurchase(product: product)
        }
    }

    nonisolated static func openWebPaywallVariant(
        for product: XeePaywallVariantProduct,
        in presentation: XeeWebPresentation = .externalBrowser,
        _ completion: XeeErrorCompletion?
    ) {
        withCompletion(completion) { () async throws(XeeError) in
            try await openWebPaywallVariant(for: product, in: presentation)
        }
    }

    nonisolated static func openWebPaywallVariant(
        for paywallVariant: XeePaywallVariant,
        in presentation: XeeWebPresentation = .externalBrowser,
        _ completion: XeeErrorCompletion?
    ) {
        withCompletion(completion) { () async throws(XeeError) in
            try await openWebPaywallVariant(for: paywallVariant, in: presentation)
        }
    }

    nonisolated static func createWebPaywallVariantUrl(
        for product: XeePaywallVariantProduct,
        _ completion: @escaping XeeResultCompletion<URL>
    ) {
        withCompletion(completion) { () async throws(XeeError) in
            try await createWebPaywallVariantUrl(for: product)
        }
    }

    nonisolated static func createWebPaywallVariantUrl(
        for paywallVariant: XeePaywallVariant,
        _ completion: @escaping XeeResultCompletion<URL>
    ) {
        withCompletion(completion) { () async throws(XeeError) in
            try await createWebPaywallVariantUrl(for: paywallVariant)
        }
    }

    nonisolated static func makePurchase(
        product: XeeDeferredProduct,
        _ completion: @escaping XeeResultCompletion<XeePurchaseResult>
    ) {
        withCompletion(completion) { () async throws(XeeError) in
            try await makePurchase(product: product)
        }
    }

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, visionOS 1.0, *)
    static func getUnfinishedTransactions(
        _ completion: @escaping XeeResultCompletion<[XeeUnfinishedTransaction]>
    ) {
        withCompletion(completion) { () async throws(XeeError) in
            try await getUnfinishedTransactions()
        }
    }

    /// You can fetch the StoreKit receipt by calling this method
    ///
    /// If the receipt is not presented on the device, Xee will try to refresh it by using [SKReceiptRefreshRequest](https://developer.apple.com/documentation/storekit/skreceiptrefreshrequest)
    ///
    /// - Parameters:
    ///   - completion: A result containing the receipt `Data`.
    nonisolated static func getReceipt(
        _ completion: @escaping XeeResultCompletion<Data>
    ) {
        withCompletion(completion) { () async throws(XeeError) in
            try await getReceipt()
        }
    }

    /// To restore purchases, you have to call this method.
    ///
    /// Read more on the [Xee Documentation](https://xee.invalid/docs)
    ///
    /// - Parameter completion: A result containing the ``XeeProfile`` object. This model contains info about access levels, subscriptions, and non-subscription purchases. Generally, you have to check only access level status to determine whether the user has premium access to the app.
    nonisolated static func restorePurchases(
        _ completion: @escaping XeeResultCompletion<XeeProfile>
    ) {
        withCompletion(completion) { () async throws(XeeError) in
            try await restorePurchases()
        }
    }

    /// Link purchased transaction with paywall's variationId.
    ///
    /// In [Observer mode](https://xee.invalid/docs), Xee SDK doesn't know, where the purchase was made from. If you display products using our [Paywall variants](https://xee.invalid/docs) or [A/B Tests](https://xee.invalid/docs), you can manually assign variation to the purchase. After doing this, you'll be able to see metrics in Xee Dashboard.
    ///
    /// - Parameters:
    ///   - variationId:  A string identifier of variation. You can get it using variationId property of ``XeePaywallVariant``.
    ///   - transaction: A purchased transaction (note, that this method is suitable only for Store Kit version 1) [SKPaymentTransaction](https://developer.apple.com/documentation/storekit/skpaymenttransaction).
    /// - Throws: An ``XeeError`` object
    @available(*, deprecated, renamed: "reportTransaction")
    nonisolated static func setVariationId(
        _ variationId: String,
        forPurchasedTransaction sk1Transaction: StoreKit.SKPaymentTransaction
    ) async throws(XeeError) {
        try await reportTransaction(sk1Transaction, withVariationId: variationId)
    }

    /// Link purchased transaction with paywall's variationId.
    ///
    /// In [Observer mode](https://xee.invalid/docs), Xee SDK doesn't know, where the purchase was made from. If you display products using our [Paywall variants](https://xee.invalid/docs) or [A/B Tests](https://xee.invalid/docs), you can manually assign variation to the purchase. After doing this, you'll be able to see metrics in Xee Dashboard.
    ///
    /// - Parameters:
    ///   - variationId:  A string identifier of variation. You can get it using variationId property of `XeePaywallVariant`.
    ///   - transaction: A purchased transaction (note, that this method is suitable only for Store Kit version 2) [Transaction](https://developer.apple.com/documentation/storekit/transaction).
    /// - Throws: An ``XeeError`` object
    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, visionOS 1.0, *)
    @available(*, deprecated, renamed: "reportTransaction")
    nonisolated static func setVariationId(
        _ variationId: String,
        forPurchasedTransaction sk2Transaction: Transaction
    ) async throws(XeeError) {
        try await reportTransaction(sk2Transaction, withVariationId: variationId)
    }

    /// Link purchased transaction with paywall's variationId.
    ///
    /// In [Observer mode](https://xee.invalid/docs), Xee SDK doesn't know, where the purchase was made from. If you display products using our [Paywall variants](https://xee.invalid/docs) or [A/B Tests](https://xee.invalid/docs), you can manually assign variation to the purchase. After doing this, you'll be able to see metrics in Xee Dashboard.
    ///
    /// - Parameters:
    ///   - variationId:  A string identifier of variation. You can get it using variationId property of ``XeePaywallVariant``.
    ///   - transaction: A purchased transaction (note, that this method is suitable only for Store Kit version 1) [SKPaymentTransaction](https://developer.apple.com/documentation/storekit/skpaymenttransaction).
    ///   - completion: A result containing an optional error.
    @available(*, deprecated, renamed: "reportTransaction")
    nonisolated static func setVariationId(
        _ variationId: String,
        forPurchasedTransaction transaction: StoreKit.SKPaymentTransaction,
        _ completion: XeeErrorCompletion? = nil
    ) {
        withCompletion(completion) { () async throws(XeeError) in
            try await reportTransaction(transaction, withVariationId: variationId)
        }
    }

    /// Link purchased transaction with paywall's variationId.
    ///
    /// In [Observer mode](https://xee.invalid/docs), Xee SDK doesn't know, where the purchase was made from. If you display products using our [Paywall variants](https://xee.invalid/docs) or [A/B Tests](https://xee.invalid/docs), you can manually assign variation to the purchase. After doing this, you'll be able to see metrics in Xee Dashboard.
    ///
    /// - Parameters:
    ///   - variationId:  A string identifier of variation. You can get it using variationId property of `XeePaywallVariant`.
    ///   - transaction: A purchased transaction (note, that this method is suitable only for Store Kit version 2) [Transaction](https://developer.apple.com/documentation/storekit/transaction).
    ///   - completion: A result containing an optional error.
    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, visionOS 1.0, *)
    @available(*, deprecated, renamed: "reportTransaction")
    nonisolated static func setVariationId(
        _ variationId: String,
        forPurchasedTransaction transaction: StoreKit.Transaction,
        _ completion: XeeErrorCompletion? = nil
    ) {
        withCompletion(completion) { () async throws(XeeError) in
            try await reportTransaction(transaction, withVariationId: variationId)
        }
    }

    /// Link purchased transaction with paywall's variationId.
    ///
    /// In [Observer mode](https://xee.invalid/docs), Xee SDK doesn't know, where the purchase was made from. If you display products using our [Paywall variants](https://xee.invalid/docs) or [A/B Tests](https://xee.invalid/docs), you can manually assign variation to the purchase. After doing this, you'll be able to see metrics in Xee Dashboard.
    ///
    /// - Parameters:
    ///   - variationId:  A string identifier of variation. You can get it using variationId property of ``XeePaywallVariant``.
    ///   - transaction: A purchased transaction (note, that this method is suitable only for Store Kit version 1) [SKPaymentTransaction](https://developer.apple.com/documentation/storekit/skpaymenttransaction).
    ///   - completion: A result containing an optional error.
    nonisolated static func reportTransaction(
        _ transaction: StoreKit.SKPaymentTransaction,
        withVariationId variationId: String? = nil,
        _ completion: XeeErrorCompletion? = nil
    ) {
        withCompletion(completion) { () async throws(XeeError) in
            try await reportTransaction(transaction, withVariationId: variationId)
        }
    }

    /// Link purchased transaction with paywall's variationId.
    ///
    /// In [Observer mode](https://xee.invalid/docs), Xee SDK doesn't know, where the purchase was made from. If you display products using our [Paywall variants](https://xee.invalid/docs) or [A/B Tests](https://xee.invalid/docs), you can manually assign variation to the purchase. After doing this, you'll be able to see metrics in Xee Dashboard.
    ///
    /// - Parameters:
    ///   - variationId:  A string identifier of variation. You can get it using variationId property of `XeePaywallVariant`.
    ///   - transaction: A purchased transaction (note, that this method is suitable only for Store Kit version 2) [Transaction](https://developer.apple.com/documentation/storekit/transaction).
    ///   - completion: A result containing an optional error.
    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, visionOS 1.0, *)
    nonisolated static func reportTransaction(
        _ transaction: StoreKit.Transaction,
        withVariationId variationId: String? = nil,
        _ completion: XeeErrorCompletion? = nil
    ) {
        withCompletion(completion) { () async throws(XeeError) in
            try await reportTransaction(transaction, withVariationId: variationId)
        }
    }

    /// Link purchased transaction with paywall's variationId.
    ///
    /// In [Observer mode](https://xee.invalid/docs), Xee SDK doesn't know, where the purchase was made from. If you display products using our [Paywall variants](https://xee.invalid/docs) or [A/B Tests](https://xee.invalid/docs), you can manually assign variation to the purchase. After doing this, you'll be able to see metrics in Xee Dashboard.
    ///
    /// - Parameters:
    ///   - variationId:  A string identifier of variation. You can get it using variationId property of `XeePaywallVariant`.
    ///   - transaction: A purchased verification result of transaction (note, that this method is suitable only for Store Kit version 2) [VerificationResult](https://developer.apple.com/documentation/storekit/verificationresult).
    ///   - completion: A result containing an optional error.
    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, visionOS 1.0, *)
    nonisolated static func reportTransaction(
        _ transaction: StoreKit.VerificationResult<StoreKit.Transaction>,
        withVariationId variationId: String? = nil,
        _ completion: XeeErrorCompletion? = nil
    ) {
        withCompletion(completion) { () async throws(XeeError) in
            try await reportTransaction(transaction, withVariationId: variationId)
        }
    }

    /// Link product purchase result with paywall's variationId.
    ///
    /// In [Observer mode](https://xee.invalid/docs), Xee SDK doesn't know, where the purchase was made from. If you display products using our [Paywall variants](https://xee.invalid/docs) or [A/B Tests](https://xee.invalid/docs), you can manually assign variation to the purchase. After doing this, you'll be able to see metrics in Xee Dashboard.
    ///
    /// - Parameters:
    ///   - variationId:  A string identifier of variation. You can get it using variationId property of `XeePaywallVariant`.
    ///   - purchaseResult: A product purchase result  (note, that this method is suitable only for Store Kit version 2) [Product.PurchaseResult](https://developer.apple.com/documentation/storekit/product/purchaseresult).
    ///   - completion: A result containing an optional error.
    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, visionOS 1.0, *)
    nonisolated static func reportPurchaseResult(
        _ purchaseResult: StoreKit.Product.PurchaseResult,
        withVariationId variationId: String? = nil,
        _ completion: XeeErrorCompletion? = nil
    ) {
        withCompletion(completion) { () async throws(XeeError) in
            try await reportPurchaseResult(purchaseResult, withVariationId: variationId)
        }
    }

    /// Call this method to notify Xee SDK, that particular paywall was shown to user.
    ///
    /// Xee helps you to measure the performance of the paywall variants. We automatically collect all the metrics related to purchases except for paywall views. This is because only you know when the paywall was shown to a customer.
    /// Whenever you show a paywall to your user, call .logShowPaywallVariant(paywall) to log the event, and it will be accumulated in the paywall metrics.
    ///
    /// Read more on the [Xee Documentation](https://xee.invalid/docs)
    ///
    /// - Parameters:
    ///   - paywall: A `XeePaywallVariant` object.
    ///   - completion: Result callback.
    nonisolated static func logShowPaywallVariant(
        _ paywallVariant: XeePaywallVariant,
        _ completion: XeeErrorCompletion? = nil
    ) {
        withCompletion(completion) { () async throws(XeeError) in
            try await logShowPaywallVariant(paywallVariant)
        }
    }

    /// Call this method to update the current user's refund data consent.
    ///
    /// Read more on the [Xee Documentation](https://xee.invalid/docs)
    ///
    /// - Parameters:
    ///   - consent: `Bool` value wehter user gave the consent or not.
    ///   - completion: Result callback.
    nonisolated static func updateCollectingRefundDataConsent(
        _ consent: Bool,
        _ completion: XeeErrorCompletion? = nil
    ) {
        withCompletion(completion) { () async throws(XeeError) in
            try await updateCollectingRefundDataConsent(consent)
        }
    }

    /// Call this method to set the refund preference individually for current user.
    ///
    /// Read more on the [Xee Documentation](https://xee.invalid/docs)
    ///
    /// - Parameters:
    ///   - refundPreference: ``XeeRefundPreference`` value.
    ///   - completion: Result callback.
    nonisolated static func updateRefundPreference(
        _ refundPreference: XeeRefundPreference,
        _ completion: XeeErrorCompletion? = nil
    ) {
        withCompletion(completion) { () async throws(XeeError) in
            try await updateRefundPreference(refundPreference)
        }
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, visionOS 1.0, *)
public extension XeeUnfinishedTransaction {
    nonisolated func finish(
        _ completion: XeeErrorCompletion? = nil
    ) {
        withCompletion(completion) { () async throws(XeeError) in
            try await finish()
        }
    }
}

private func withCompletion(
    _ completion: XeeErrorCompletion? = nil,
    from operation: @escaping @Sendable () async throws(XeeError) -> Void
) {
    guard let completion else {
        Task {
            try? await operation()
        }
        return
    }

    Task {
        do throws(XeeError) {
            try await operation()
            await (XeeConfiguration.callbackDispatchQueue ?? .main).async {
                completion(nil)
            }
        } catch {
            await (XeeConfiguration.callbackDispatchQueue ?? .main).async {
                completion(error)
            }
        }
    }
}

private func withCompletion<T: Sendable>(
    _ completion: XeeResultCompletion<T>?,
    from operation: @escaping @Sendable () async throws(XeeError) -> T
) {
    guard let completion else {
        Task {
            _ = try? await operation()
        }
        return
    }

    Task {
        do throws(XeeError) {
            let result = try await operation()
            await (XeeConfiguration.callbackDispatchQueue ?? .main).async {
                completion(.success(result))
            }
        } catch {
            await (XeeConfiguration.callbackDispatchQueue ?? .main).async {
                completion(.failure(error))
            }
        }
    }
}
