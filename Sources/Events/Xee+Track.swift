//
//  Xee+Track.swift
//  XeeSDK
//

import Foundation

private let log = Log.events

public extension Xee {
    /// Sends an analytics event, such as `onboarding_finished`, for the current profile. Xee keeps it
    /// for view tests (as their goal), a view's funnel and the profile page.
    ///
    /// It never throws and never waits: the event is saved on the device and sent in the background,
    /// with retries. A name that is not snake case (`^[a-z][a-z0-9_]{0,63}$`) drops the event; a bad
    /// property is dropped on its own. Events sent before `Xee.activate` are dropped.
    ///
    /// - Parameters:
    ///   - name: The event's name, for example `onboarding_step_viewed`.
    ///   - properties: Up to 20 values, for example `["screen": "goals", "step": 2]`.
    nonisolated static func track(_ name: String, properties: [String: XeeProperty] = [:]) {
        let now = Date()
        let duration = XeeEventTimers.shared.take(name, at: now)
        guard let parameters = XeeTrackParameters.make(name: name, properties: properties, durationMs: duration) else {
            return
        }
        Task.detached(priority: .utility) {
            guard await isActivated else {
                log.warn("Xee.track(\"\(name)\") was called before Xee.activate; the event is dropped")
                return
            }
            try? await trackEvent(.track(parameters), date: now)
        }
    }

    /// Starts a timer for an event. The next `track` of the same name carries `duration_ms`, the
    /// milliseconds since this call, and clears the timer. Timers live in memory only.
    nonisolated static func time(_ name: String) {
        XeeEventTimers.shared.start(name, at: Date())
    }
}
