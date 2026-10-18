// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  Xee+UnfinishedTransaction.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 18.09.2025.
//

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, visionOS 1.0, *)
public extension Xee {
    nonisolated static func getUnfinishedTransactions() async throws(XeeError) -> [XeeUnfinishedTransaction] {
        try await withActivatedSDK(methodName: .getUnfinishedTransactions) { sdk async throws(XeeError) in
            try await sdk.getUnfinishedTransactions()
        }
    }
}


