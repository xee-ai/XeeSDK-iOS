//
//  XeeTrackQueue.swift
//  XeeSDK
//

import Foundation

private let log = Log.events

/// Whether the person opted out of `Xee.track`, kept across launches.
final class OptOutFlag: @unchecked Sendable {
    private static let key = "XeeSDK_TrackingOptedOut"
    private let lock = NSLock()
    private let defaults: UserDefaults?
    private var value: Bool

    /// `defaults: nil` keeps it in memory (tests).
    init(defaults: UserDefaults?) {
        self.defaults = defaults
        value = defaults?.bool(forKey: Self.key) ?? false
    }

    var isOn: Bool {
        lock.lock()
        defer { lock.unlock() }
        return value
    }

    func set(_ on: Bool) {
        lock.lock()
        value = on
        lock.unlock()
        defaults?.set(on, forKey: Self.key)
    }
}

/// `Xee.track` calls, in call order, on their way to the event queue. One task sends them one after
/// another, so they reach the queue in the order they were made. Calls made before `Xee.activate`
/// are held (the newest `maxHeld`) and sent once it starts.
final class XeeTrackQueue: @unchecked Sendable {
    static let maxHeld = 200

    static let shared = XeeTrackQueue(
        isActivated: { await Xee.isActivated },
        send: { parameters, date in try? await Xee.trackEvent(.track(parameters), date: date) },
        optOut: OptOutFlag(defaults: .standard)
    )

    let optOut: OptOutFlag
    private let isActivated: @Sendable () async -> Bool
    private let send: @Sendable (XeeTrackParameters, Date) async -> Void
    private let lock = NSLock()
    private var held: [(XeeTrackParameters, Date)] = []
    private var draining: Task<Void, Never>?

    init(
        isActivated: @escaping @Sendable () async -> Bool,
        send: @escaping @Sendable (XeeTrackParameters, Date) async -> Void,
        optOut: OptOutFlag
    ) {
        self.isActivated = isActivated
        self.send = send
        self.optOut = optOut
    }

    var heldCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return held.count
    }

    func enqueue(_ parameters: XeeTrackParameters, at date: Date) {
        guard !optOut.isOn else { return }
        lock.lock()
        held.append((parameters, date))
        if held.count > Self.maxHeld {
            held.removeFirst(held.count - Self.maxHeld)
            log.warn("Xee.track: more than \(Self.maxHeld) events before Xee.activate; the oldest are dropped")
        }
        lock.unlock()
        drain()
    }

    /// Xee.activate started: send what was held.
    func activated() {
        drain()
    }

    /// Drops what is held (opt-out).
    func clear() {
        lock.lock()
        held.removeAll()
        lock.unlock()
    }

    /// Waits for the current drain to finish (tests).
    func drained() async {
        await currentDrain()?.value
    }

    private func currentDrain() -> Task<Void, Never>? {
        lock.lock()
        defer { lock.unlock() }
        return draining
    }

    private func drain() {
        lock.lock()
        defer { lock.unlock() }
        guard draining == nil else { return }
        draining = Task.detached(priority: .utility) { [self] in
            while true {
                if await !isActivated() { break }
                guard let next = takeFirst() else { break }
                if optOut.isOn { continue }
                await send(next.0, next.1)
            }
            finishDrain()
        }
    }

    private func takeFirst() -> (XeeTrackParameters, Date)? {
        lock.lock()
        defer { lock.unlock() }
        return held.isEmpty ? nil : held.removeFirst()
    }

    /// Ends this drain; starts another when something arrived meanwhile and can be sent.
    private func finishDrain() {
        lock.lock()
        draining = nil
        let more = !held.isEmpty
        lock.unlock()
        if more {
            Task.detached(priority: .utility) { [self] in
                if await isActivated() { drain() }
            }
        }
    }
}
