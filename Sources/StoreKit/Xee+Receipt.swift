// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  Xee+Receipt.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 23.05.2023
//

import StoreKit

public extension Xee {
    /// You can fetch the StoreKit receipt by calling this method
    ///
    /// If the receipt is not presented on the device, Xee will try to refresh it by using [SKReceiptRefreshRequest](https://developer.apple.com/documentation/storekit/skreceiptrefreshrequest)
    ///
    /// - Returns: The receipt `Data`.
    /// - Throws: An ``XeeError`` object.
    nonisolated static func getReceipt() async throws(XeeError) -> Data {
        try await withActivatedSDK(methodName: .getReceipt) { sdk async throws(XeeError) in
            try await sdk.receiptManager.getReceipt()
        }
    }
}
