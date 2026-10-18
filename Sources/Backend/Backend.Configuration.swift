// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  Backend.Configuration.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 30.10.2023
//

import Foundation

extension Backend {
    struct Configuration {
        let cluster: XeeServerCluster
        let devBaseUrls: [XeeServerKind: URL]?
        let proxy: (host: String, port: Int)?
        let protocolClasses: [AnyClass]?

        init(
            cluster: XeeServerCluster = .default,
            devBaseUrls: [XeeServerKind: URL]? = nil,
            proxy: (host: String, port: Int)? = nil,
            protocolClasses: [AnyClass]? = nil
        ) {
            self.cluster = cluster
            self.devBaseUrls = devBaseUrls
            self.proxy = proxy
            self.protocolClasses = protocolClasses
        }
    }
}
