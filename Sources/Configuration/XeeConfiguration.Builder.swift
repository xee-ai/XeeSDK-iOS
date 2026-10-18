// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  XeeConfiguration.Builder.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 23.04.2024.
//

import XeeLogger
import Foundation

extension XeeConfiguration {
    fileprivate init(with builder: XeeConfiguration.Builder) {
        let apiKey = builder.apiKey
        assert(apiKey.starts(with: "xee_"), "It looks like you have passed the wrong apiKey value to the Xee SDK.")

        let defaultValue = XeeConfiguration.default

        self.init(
            apiKey: apiKey.trimmed,
            customerUserId: builder.customerUserId.trimmed.nonEmptyOrNil,
            appAccountToken: builder.appAccountToken,
            observerMode: builder.observerMode ?? defaultValue.observerMode,
            idfaCollectionDisabled: builder.idfaCollectionDisabled ?? defaultValue.idfaCollectionDisabled,
            ipAddressCollectionDisabled: builder.ipAddressCollectionDisabled ?? defaultValue.ipAddressCollectionDisabled,
            callbackDispatchQueue: builder.callbackDispatchQueue,
            backend: Backend.Configuration(
                cluster: builder.serverCluster ?? .default,
                devBaseUrls: builder.devBaseUrls,
                proxy: builder.backendProxy,
                protocolClasses: builder.urlProtocolClasses
            ),
            logLevel: builder.logLevel,
            crossPlatformSDK: builder.crossPlatformSDK.map {
                (name: $0.name.trimmed, version: $0.version.trimmed)
            },
            transactionFinishBehavior: builder.transactionFinishBehavior ?? defaultValue.transactionFinishBehavior,
            clearDataOnBackup: builder.clearDataOnBackup ?? defaultValue.clearDataOnBackup
        )
    }

    public static func builder(withAPIKey apiKey: String) -> XeeConfiguration.Builder {
        .init(
            apiKey: apiKey.trimmed,
            customerUserId: nil,
            appAccountToken: nil,
            observerMode: nil,
            idfaCollectionDisabled: nil,
            ipAddressCollectionDisabled: nil,
            callbackDispatchQueue: nil,
            clearDataOnBackup: nil,
            serverCluster: nil,
            devBaseUrls: [:],
            backendProxy: nil,
            transactionFinishBehavior: nil,
            logLevel: nil,
            crossPlatformSDK: nil,
            urlProtocolClasses: nil
        )
    }
}

public extension XeeConfiguration {
    final class Builder {
        public private(set) var apiKey: String
        public private(set) var customerUserId: String?
        public private(set) var appAccountToken: UUID?
        public private(set) var observerMode: Bool?
        public private(set) var idfaCollectionDisabled: Bool?
        public private(set) var ipAddressCollectionDisabled: Bool?
        public private(set) var callbackDispatchQueue: DispatchQueue?

        public private(set) var clearDataOnBackup: Bool?

        public private(set) var serverCluster: XeeServerCluster?
        package private(set) var devBaseUrls: [XeeServerKind: URL]
        public private(set) var backendProxy: (host: String, port: Int)?

        public private(set) var transactionFinishBehavior: TransactionFinishBehavior?
        public private(set) var urlProtocolClasses: [AnyClass]?
        public private(set) var logLevel: XeeLog.Level?

        package private(set) var crossPlatformSDK: (name: String, version: String)?

        init(
            apiKey: String,
            customerUserId: String?,
            appAccountToken: UUID?,
            observerMode: Bool?,
            idfaCollectionDisabled: Bool?,
            ipAddressCollectionDisabled: Bool?,
            callbackDispatchQueue: DispatchQueue?,
            clearDataOnBackup: Bool?,
            serverCluster: XeeServerCluster?,
            devBaseUrls: [XeeServerKind: URL],
            backendProxy: (host: String, port: Int)?,
            transactionFinishBehavior: TransactionFinishBehavior?,
            logLevel: XeeLog.Level?,
            crossPlatformSDK: (name: String, version: String)?,
            urlProtocolClasses: [AnyClass]?
        ) {
            self.apiKey = apiKey
            self.customerUserId = customerUserId
            self.appAccountToken = appAccountToken
            self.observerMode = observerMode
            self.idfaCollectionDisabled = idfaCollectionDisabled
            self.ipAddressCollectionDisabled = ipAddressCollectionDisabled
            self.callbackDispatchQueue = callbackDispatchQueue
            self.clearDataOnBackup = clearDataOnBackup
            self.serverCluster = serverCluster ?? .default
            self.devBaseUrls = devBaseUrls
            self.backendProxy = backendProxy
            self.transactionFinishBehavior = transactionFinishBehavior
            self.logLevel = logLevel
            self.crossPlatformSDK = crossPlatformSDK
            self.urlProtocolClasses = urlProtocolClasses
        }

        /// Call this method to get the ``XeeConfiguration`` object.
        public func build() -> XeeConfiguration {
            .init(with: self)
        }
    }
}

public extension XeeConfiguration.Builder {
    /// - Parameter apiKey: You can find it in your app settings in [Xee Dashboard](https://xee.invalid/docs) *App settings* > *General*.
    @discardableResult
    func with(apiKey key: String) -> Self {
        apiKey = key
        return self
    }

    /// - Parameter customerUserId: User identifier in your system
    @discardableResult
    func with(customerUserId id: String?, withAppAccountToken token: UUID? = nil) -> Self {
        customerUserId = id
        appAccountToken = id != nil ? token : nil
        return self
    }

    /// - Parameter observerMode: A boolean value controlling [Observer mode](https://xee.invalid/docs). Turn it on if you handle purchases and subscription status yourself and use Xee for sending subscription events and analytics
    @discardableResult
    func with(observerMode mode: Bool) -> Self {
        observerMode = mode
        return self
    }

    /// - Parameter idfaCollectionDisabled: A boolean value controlling idfa collection logic
    @discardableResult
    func with(idfaCollectionDisabled value: Bool) -> Self {
        idfaCollectionDisabled = value
        return self
    }

    /// - Parameter ipAddressCollectionDisabled: A boolean value controlling ip-address collection logic
    @discardableResult
    func with(ipAddressCollectionDisabled value: Bool) -> Self {
        ipAddressCollectionDisabled = value
        return self
    }
    
    @discardableResult
    func with(clearDataOnBackup value: Bool) -> Self {
        clearDataOnBackup = value
        return self
    }

    /// - Parameter dispatchQueue: Specify the Dispatch Queue where callbacks will be executed
    @discardableResult
    func with(callbackDispatchQueue queue: DispatchQueue) -> Self {
        callbackDispatchQueue = queue
        return self
    }

    @discardableResult
    func with(serverCluster value: XeeServerCluster) -> Self {
        serverCluster = XeeServerCluster(rawValue: value.rawValue)
        return self
    }

    /// The server Xee talks to, for every kind of request: API, configuration and fallback.
    @discardableResult
    func with(serverUrl url: URL) -> Self {
        for kind in XeeServerKind.allCases {
            devBaseUrls[kind] = url
        }
        return self
    }

    @discardableResult
    package func with(backendBaseUrl url: URL, for kind: XeeServerKind = .main) -> Self {
        devBaseUrls[kind] = url
        return self
    }

    @discardableResult
    func with(proxy host: String, port: Int) -> Self {
        backendProxy = (host: host.trimmed, port: port)
        return self
    }

    @discardableResult
    func with(transactionFinishBehavior value: XeeConfiguration.TransactionFinishBehavior) -> Self {
        transactionFinishBehavior = value
        return self
    }

    @discardableResult
    func with(logLevel level: XeeLog.Level) -> Self {
        logLevel = level
        return self
    }

    @discardableResult
    package func with(crossplatformSDKName name: String, version: String) -> Self {
        crossPlatformSDK = (name: name, version: version)
        return self
    }

    @discardableResult
    package func with(urlProtocolClasses classes: [AnyClass]) -> Self {
        urlProtocolClasses = classes
        return self
    }
}
