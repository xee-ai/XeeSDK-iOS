// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  Xee+SyncIPv4.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 19.12.2023
//

import Foundation

extension XeeConfiguration {
    @XeeActor
    static var ipAddressCollectionDisabled = Self.default.ipAddressCollectionDisabled
}

extension Environment.Device {
    /// Never fetched: the server reads the device's address from the request itself (unless
    /// `ipAddressCollectionDisabled`, sent as the `xee-ip-collection-disabled` header), so no profile
    /// update goes out just for it.
    @XeeActor
    static var ipV4Address: String?
}
