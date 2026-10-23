// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  EventsStorage.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 07.10.2022.
//

import Foundation

private let log = Log.storage

/// The per-kind event counters (sent as `counter`), in UserDefaults. The events themselves are in
/// `EventsDatabase`; the queue that older SDK versions kept in UserDefaults is moved there once.
@EventsManagerActor
enum EventsStorage {
    private static let userDefaults = Storage.userDefaults

    private static func counterKey(_ kind: EventsDatabase.Kind) -> String {
        "XeeSDK_\(prefix(kind))Event_Counter"
    }

    private static func legacyEventsKey(_ kind: EventsDatabase.Kind) -> String {
        "XeeSDK_Cached_\(prefix(kind))Events"
    }

    private static func prefix(_ kind: EventsDatabase.Kind) -> String {
        switch kind {
        case .default: ""
        case .sysLog: "SysLog"
        }
    }

    /// The next counter value for `kind`, saved.
    static func nextCounter(_ kind: EventsDatabase.Kind) -> Int {
        let value = userDefaults.integer(forKey: counterKey(kind))
        userDefaults.set(value + 1, forKey: counterKey(kind))
        return value
    }

    /// Moves the queue an older SDK version kept in UserDefaults into `database`, in order, once.
    static func moveLegacyEvents(into database: EventsDatabase) {
        for kind in EventsDatabase.Kind.allCases {
            guard let events = userDefaults.object(forKey: legacyEventsKey(kind)) as? [Data] else { continue }
            for data in events {
                guard let packed = try? Event.Packed(from: data) else { continue }
                database.insert(kind: kind, name: packed.name, data: data)
            }
            userDefaults.removeObject(forKey: legacyEventsKey(kind))
            log.debug("Moved \(events.count) \(prefix(kind))events from UserDefaults to the events database.")
        }
    }

    static func clearAll() {
        for kind in EventsDatabase.Kind.allCases {
            userDefaults.removeObject(forKey: counterKey(kind))
            userDefaults.removeObject(forKey: legacyEventsKey(kind))
        }
        EventsDatabase.shared.deleteAll()
    }
}
