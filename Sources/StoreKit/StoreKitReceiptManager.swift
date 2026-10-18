// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  StoreKitReceiptManager.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 05.10.2024
//

import StoreKit

private let log = Log.skReceiptManager

actor StoreKitReceiptManager {
    let httpSession: Backend.MainExecutor
    private let refresher = ReceiptRefresher()
    private var syncing: (task: XeeResultTask<Void>, userId: XeeUserId)?

    init(httpSession: Backend.MainExecutor, refreshIfEmpty: Bool) {
        self.httpSession = httpSession

        if refreshIfEmpty {
            Task {
                _ = try? await getReceipt()
            }
        }
    }

    func getReceipt() async throws(XeeError) -> Data {
        do {
            return try bundleReceipt()
        } catch {
            try await refresher.refresh()
            return try bundleReceipt()
        }
    }

    private func bundleReceipt() throws(XeeError) -> Data {
        let stamp = Log.stamp
        Xee.trackSystemEvent(XeeAppleRequestParameters(methodName: .getReceipt, stamp: stamp))

        do throws(XeeError) {
            guard let url = Bundle.main.appStoreReceiptURL else {
                log.error("Receipt URL is nil.")
                throw StoreKitManagerError.receiptIsEmpty().asXeeError
            }

            var data: Data
            do {
                data = try Data(contentsOf: url)
            } catch {
                log.error("The receipt data failed to load. \(error)")
                throw StoreKitManagerError.receiptIsEmpty(error).asXeeError
            }

            if data.isEmpty {
                log.error("The receipt data is empty.")
                throw StoreKitManagerError.receiptIsEmpty().asXeeError
            }

            Xee.trackSystemEvent(XeeAppleResponseParameters(methodName: .getReceipt, stamp: stamp))

            log.verbose("Loaded receipt")
            return data

        } catch {
            Xee.trackSystemEvent(XeeAppleResponseParameters(methodName: .getReceipt, stamp: stamp, error: error.localizedDescription))

            throw error
        }
    }
}

extension StoreKitReceiptManager {
    func syncTransactionHistory(for userId: XeeUserId) async throws(XeeError) {
        let task: XeeResultTask<Void>
        if let syncing, userId.isEqualProfileId(syncing.userId) {
            task = syncing.task
        } else {
            task = Task.detachedAsResultTask { () async throws(XeeError) in
                try await self.syncReceipt(for: userId)
            }
            syncing = (task, userId)
        }
        try await task.value.get()
    }

    private func syncReceipt(for userId: XeeUserId) async throws(XeeError) {
        defer { syncing = nil }
        let receipt = try await getReceipt()
        do throws(HTTPError) {
            let response = try await httpSession.validateReceipt(
                userId: userId,
                receipt: receipt
            )
            await Xee.optionalSDK?.handleTransactionResponse(response)
        } catch {
            throw error.asXeeError
        }
    }
}

private final class ReceiptRefresher: NSObject, @unchecked Sendable {
    private let queue = DispatchQueue(label: "Xee.SDK.ReceiptRefresher")
    private var refreshCompletionHandlers: [XeeErrorCompletion]?

    func refresh() async throws(XeeError) {
        try await withCheckedThrowingContinuation_ { continuation in
            refresh { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }

    func refresh(_ completion: @escaping XeeErrorCompletion) {
        queue.async { [weak self] in
            guard let self else {
                completion(StoreKitManagerError.interrupted().asXeeError)
                return
            }

            if let handlers = self.refreshCompletionHandlers {
                self.refreshCompletionHandlers = handlers + [completion]
                log.debug("Add handler to refreshCompletionHandlers.count = \(self.refreshCompletionHandlers?.count ?? 0)")
                return
            }

            self.refreshCompletionHandlers = [completion]

            log.verbose("Start refresh receipt")
            let request = SKReceiptRefreshRequest()
            request.delegate = self
            request.start()

            let stamp = "SKR\(request.hash)"
            Xee.trackSystemEvent(XeeAppleRequestParameters(methodName: .refreshReceipt, stamp: stamp))
        }
    }

    private func completedRefresh(_ request: SKRequest, _ error: XeeError? = nil) {
        let stamp = "SKR\(request.hash)"

        Xee.trackSystemEvent(XeeAppleResponseParameters(methodName: .refreshReceipt, stamp: stamp, error: error?.description))

        queue.async { [weak self] in
            guard let self else { return }

            guard let handlers = self.refreshCompletionHandlers.nonEmptyOrNil else {
                log.error("Not found refreshCompletionHandlers")
                return
            }
            self.refreshCompletionHandlers = nil

            if let error {
                log.error("Refresh receipt failed. \(error)")
            } else {
                log.verbose("Refresh receipt success.")
            }

            log.debug("Call refreshCompletionHandlers.count = \(handlers.count)\(error.map { " with error = \($0)" } ?? "")")

            handlers.forEach { $0(error) }
        }
    }
}

extension ReceiptRefresher: SKRequestDelegate {
    func requestDidFinish(_ request: SKRequest) {
        guard request is SKReceiptRefreshRequest else { return }
        completedRefresh(request)
        request.cancel()
    }

    func request(_ request: SKRequest, didFailWithError error: Error) {
        guard request is SKReceiptRefreshRequest else { return }
        completedRefresh(request, StoreKitManagerError.refreshReceiptFailed(error).asXeeError)
        request.cancel()
    }
}
