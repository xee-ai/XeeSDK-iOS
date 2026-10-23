//
//  Xee+Track.swift
//  XeeSDK
//

import Foundation

public extension Xee {
    /// Sends an analytics event, such as `onboarding_finished`, for the current profile. Xee keeps it
    /// for view tests (as their goal), a view's funnel and the profile page.
    ///
    /// It never throws and never waits. Events keep the order of the calls. They are saved on the
    /// device and sent in the background, in gzipped batches, again later if the network fails, and at
    /// once when the app goes to the background. A name that is not snake case
    /// (`^[a-z][a-z0-9_]{0,63}$`) drops the event; a bad property is dropped on its own. Events sent
    /// before `Xee.activate` are held (up to 200) and sent once it is called. Nothing is sent while
    /// the person has opted out (`optOutTracking()`).
    ///
    /// - Parameters:
    ///   - name: The event's name, for example `onboarding_step_viewed`.
    ///   - properties: Up to 20 values, for example `["screen": "goals", "step": 2]`.
    nonisolated static func track(_ name: String, properties: [String: XeeProperty] = [:]) {
        guard !XeeTrackQueue.shared.optOut.isOn else { return }
        let now = Date()
        let duration = XeeEventTimers.shared.take(name, at: now)
        guard let parameters = XeeTrackParameters.make(name: name, properties: properties, durationMs: duration) else {
            return
        }
        XeeTrackQueue.shared.enqueue(parameters, at: now)
    }

    /// Starts a timer for an event. The next `track` of the same name carries `duration_ms`, the
    /// milliseconds since this call, and clears the timer. Timers live in memory only.
    nonisolated static func time(_ name: String) {
        XeeEventTimers.shared.start(name, at: Date())
    }

    /// Stops `track` for this person, on this device, until `optInTracking()`: new events are not
    /// kept, and events not sent yet are deleted. Remembered across launches. Paywall views and
    /// purchases, which A/B tests and access need, are not affected.
    nonisolated static func optOutTracking() {
        XeeTrackQueue.shared.optOut.set(true)
        XeeTrackQueue.shared.clear()
        XeeEventTimers.shared.clearAll()
        Task.detached(priority: .utility) { @EventsManagerActor in
            Xee.eventsManager.removeEvents(named: Event.track(.init(name: "x", properties: [:])).name)
        }
    }

    /// Lets `track` send events again after `optOutTracking()`.
    nonisolated static func optInTracking() {
        XeeTrackQueue.shared.optOut.set(false)
    }

    /// Whether `optOutTracking()` is in effect.
    nonisolated static var hasOptedOutTracking: Bool {
        XeeTrackQueue.shared.optOut.isOn
    }
}
