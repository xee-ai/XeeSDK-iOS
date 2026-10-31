//  Xee+SyncIPv4.swift
//  XeeSDK
//
//  Created by Xee team.
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
