// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  Xee+Activate.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 22.09.2024
//

import Foundation

private let log = Log.default

public extension Xee {
    /// Use this method to initialize the Xee SDK.
    ///
    /// Call this method in the `application(_:didFinishLaunchingWithOptions:)`.
    ///
    /// - Parameter apiKey: You can find it in your app settings in [Xee Dashboard](https://xee.invalid/docs) *App settings* > *General*.
    /// - Parameter observerMode: A boolean value controlling [Observer mode](https://xee.invalid/docs). Turn it on if you handle purchases and subscription status yourself and use Xee for sending subscription events and analytics
    /// - Parameter customerUserId: User identifier in your system
    nonisolated static func activate(
        _ apiKey: String,
        observerMode: Bool = false,
        customerUserId: String? = nil
    ) async throws(XeeError) {
        try await activate(
            with: XeeConfiguration
                .builder(withAPIKey: apiKey)
                .with(customerUserId: customerUserId)
                .with(observerMode: observerMode)
                .build()
        )
    }

    /// Use this method to initialize the Xee SDK.
    ///
    /// Call this method in the `application(_:didFinishLaunchingWithOptions:)`.
    ///
    /// - Parameter configuration: `XeeConfiguration` which allows to configure Xee SDK
    static func activate(
        with configuration: XeeConfiguration
    ) async throws(XeeError) {
        let stamp = Log.stamp

        #if XEE_KIDS_MODE
        let kidsModeEnabled = true
        #else
        let kidsModeEnabled = false
        #endif

        let logParams: EventParameters? = [
            "observer_mode": configuration.observerMode,
            "customer_user_id": configuration.customerUserId,
            "app_account_token": configuration.appAccountToken?.uuidString,
            "idfa_collection_disabled": configuration.idfaCollectionDisabled,
            "ip_address_collection_disabled": configuration.ipAddressCollectionDisabled,
            "clear_data_on_backup": configuration.clearDataOnBackup,
            "kids_mode_enabled": kidsModeEnabled,
        ]

        trackSystemEvent(XeeSDKMethodRequestParameters(methodName: .activate, stamp: stamp, params: logParams))
        log.verbose("Calling Xee activate [\(stamp)] with params: \(logParams?.description ?? "nil")")

        guard !isActivated else {
            let error = XeeError.activateOnceError()
            trackSystemEvent(XeeSDKMethodResponseParameters(methodName: .activate, stamp: stamp, error: error.localizedDescription))
            log.error("Xee activate [\(stamp)] encountered an error: \(error).")
            throw error
        }

        let task = Task<Xee, Never>.detached { @XeeActor @Sendable () async -> Xee in
            if let logLevel = configuration.logLevel { Xee.logLevel = logLevel }

            await Storage.clearAllDataIf(
                differentApiKey: configuration.apiKey,
                onRestoreFromBackup: configuration.clearDataOnBackup
            )

            XeeConfiguration.transactionFinishBehavior = configuration.transactionFinishBehavior
            XeeConfiguration.callbackDispatchQueue = configuration.callbackDispatchQueue // TODO: Refactoring
            XeeConfiguration.idfaCollectionDisabled = configuration.idfaCollectionDisabled // TODO: Refactoring
            XeeConfiguration.ipAddressCollectionDisabled = configuration.ipAddressCollectionDisabled // TODO: Refactoring

            let environment = await Environment.instance

            let backend = await Backend(with: configuration, environment: environment)

            await eventsManager.set(backend: backend)

            let sdk = await Xee(
                configuration: configuration,
                backend: backend
            )

            trackSystemEvent(XeeSDKMethodResponseParameters(methodName: .activate, stamp: stamp))
            log.info("Xee activated successfully. [\(stamp)]")

            set(shared: sdk)

            UserAcquisitionManager.activate(sdk)

            LifecycleManager.shared.initialize()
            return sdk
        }
        set(activatingSDK: task)
        _ = await task.value
    }
}
