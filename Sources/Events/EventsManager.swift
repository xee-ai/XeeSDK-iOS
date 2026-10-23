// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  EventsManager.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 13.10.2022.
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif

private let log = Log.events

/// Keeps the SDK's events on disk (`EventsDatabase`) and sends them in batches.
///
/// A new event waits a few seconds so the ones around it go in the same request. A batch holds up to
/// 500 events and `EventsSendPolicy.byteBudget` bytes (under the server's 256 KB body limit) and is
/// gzipped. A failed batch is shrunk, resent plain, dropped or retried later as the policy decides.
/// When the app goes to the background the queue is sent at once, inside a background task.
@EventsManagerActor
final class EventsManager {
    static var shared: EventsManager?

    private enum Constants {
        /// The server reads at most 500 events per request.
        static let batchMaxEvents = 500
        /// The newest rows kept per kind; older ones are dropped.
        static let queueLimit: [EventsDatabase.Kind: Int] = [.default: 5000, .sysLog: 500]
        /// How long a new event waits for others before the batch goes.
        static let gatherDelay: TimeInterval = 3
        /// The pause between two full batches.
        static let nextBatchDelay: TimeInterval = 1
    }

    private let database: EventsDatabase
    private var configuration = EventsBackendConfiguration()
    private var backendSession: Backend.EventsExecutor?
    private var policy = EventsSendPolicy()
    private var sending = false
    /// Set by a flush (the app going to the background): skip the gathering wait.
    private var flushRequested = false
    private var observing = false

    init(database: EventsDatabase = .shared) {
        self.database = database
        EventsStorage.moveLegacyEvents(into: database)
    }

    func set(backend: Backend) async {
        backendSession = backend.createEventsExecutor()
        let state = await backend.networkManager.currentState
        configuration = .init(state)
        observeBackground()
        guard !database.isEmpty || configuration.isExpired else { return }
        needSendEvents(gather: false)
    }

    func trackEvent(_ unpacked: Event.Unpacked) throws(EventsError) {
        guard !configuration.blacklist.contains(unpacked.event.name) else {
            return
        }
        let kind: EventsDatabase.Kind = unpacked.event.isLowPriority ? .sysLog : .default
        do {
            let packed = try Event.Packed(from: unpacked, counter: EventsStorage.nextCounter(kind))
            database.insert(kind: kind, name: packed.name, data: packed.data)
        } catch {
            let error = EventsError.encoding(error)
            log.error(error.description)
            throw error
        }
        if let limit = Constants.queueLimit[kind] {
            let dropped = database.trim(kind: kind, keep: limit)
            if dropped > 0 { log.warn("Dropped the \(dropped) oldest events: the queue keeps \(limit)") }
        }
        needSendEvents(gather: true)
    }

    /// Removes the queued events with this name (`Xee.optOutTracking` removes `xee_track`).
    func removeEvents(named name: String) {
        database.delete(name: name)
    }

    /// Sends everything queued now, and returns when the queue is empty, a send failed, or `timeout`
    /// passed.
    func flush(timeout: TimeInterval = 25) async {
        flushRequested = true
        needSendEvents(gather: false)
        let deadline = Date().addingTimeInterval(timeout)
        while sending, Date() < deadline {
            try? await Task.sleep(nanoseconds: 200_000_000)
        }
    }

    private func needSendEvents(gather: Bool) {
        guard let backendSession, !sending else { return }
        sending = true

        Task.detached(priority: .utility) { @EventsManagerActor @Sendable [weak self] in
            defer { self?.sending = false; self?.flushRequested = false }
            if gather { await self?.waitToGather() }
            while !Task.isCancelled {
                guard let self, let wait = await self.sendBatch(backendSession) else { return }
                try? await Task.sleep(nanoseconds: UInt64(wait * 1_000_000_000))
            }
        }
    }

    /// Waits `gatherDelay`, in short steps so a flush cuts it short.
    private func waitToGather() async {
        let deadline = Date().addingTimeInterval(Constants.gatherDelay)
        while Date() < deadline, !flushRequested {
            try? await Task.sleep(nanoseconds: 250_000_000)
        }
    }

    /// Sends one batch. Returns how long to wait before the next one, or `nil` to stop: the queue is
    /// empty, the send was cancelled, or a flush met a failure (the next launch or event retries).
    private func sendBatch(_ session: Backend.EventsExecutor) async -> TimeInterval? {
        let currentState = await session.manager.fetchCurrentState()
        configuration = .init(currentState)

        let rows = database.rows(maxCount: Constants.batchMaxEvents, maxBytes: policy.byteBudget)
        guard !rows.isEmpty else { return nil }
        let sent = rows.filter { !configuration.blacklist.contains($0.name) }
        guard !sent.isEmpty else {
            database.delete(ids: rows.map(\.id))
            return 0
        }

        let gzip = policy.gzip
        do throws(EventsError) {
            try await session.sendEvents(userId: ProfileStorage.userId, events: sent.map(\.data), gzip: gzip)
            database.delete(ids: rows.map(\.id))
            policy.succeeded()
            return database.isEmpty ? nil : Constants.nextBatchDelay
        } catch {
            if error.isInterrupted { return nil }
            let http = error.originalError as? HTTPError
            let decision = policy.failed(
                status: http?.statusCode,
                retryAfter: http?.headers.flatMap(Self.retryAfter),
                eventCount: sent.count,
                gzipped: gzip,
                jitter: Double.random(in: 0 ... 1)
            )
            switch decision {
            case .drop:
                log.error("Dropped \(sent.count) events the server refused: \(error.description)")
                database.delete(ids: rows.map(\.id))
                return 0
            case .shrink:
                log.warn("The batch was too large; sending \(policy.byteBudget) bytes at most")
                return 0
            case .resendPlain:
                log.warn("The server did not read a gzipped batch; sending batches uncompressed")
                return 0
            case let .backoff(seconds):
                log.verbose("Sending events failed; next try in \(Int(seconds)) s: \(error.description)")
                return flushRequested ? nil : seconds
            }
        }
    }

    /// `Retry-After` in seconds (the HTTP-date form is not used by Xee's servers).
    private static func retryAfter(_ headers: HTTPHeaders) -> TimeInterval? {
        headers.first { $0.key.lowercased() == "retry-after" }.flatMap { TimeInterval($0.value.trimmingCharacters(in: .whitespaces)) }
    }

    private func observeBackground() {
        #if canImport(UIKit) && !os(watchOS)
        guard !observing else { return }
        observing = true
        NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { _ in
            MainActor.assumeIsolated { EventsManager.flushInBackgroundTask() }
        }
        #endif
    }

    #if canImport(UIKit) && !os(watchOS)
    /// Asks iOS for time to send the queue as the app goes to the background. Uses the shared
    /// application only when there is one (not in an app extension).
    @MainActor
    private static func flushInBackgroundTask() {
        guard let app = UIApplication.value(forKey: "sharedApplication") as? UIApplication else { return }
        let task = BackgroundTask(app: app)
        Task { @EventsManagerActor in
            await Xee.eventsManager.flush()
            await task.end()
        }
    }
    #endif
}

#if canImport(UIKit) && !os(watchOS)
/// One `beginBackgroundTask`, ended once: by the flush, or by iOS when the time runs out.
@MainActor
private final class BackgroundTask {
    private let app: UIApplication
    private var id = UIBackgroundTaskIdentifier.invalid

    init(app: UIApplication) {
        self.app = app
        id = app.beginBackgroundTask(withName: "Xee events") { [weak self] in
            MainActor.assumeIsolated { self?.end() }
        }
    }

    func end() {
        guard id != .invalid else { return }
        app.endBackgroundTask(id)
        id = .invalid
    }
}
#endif
