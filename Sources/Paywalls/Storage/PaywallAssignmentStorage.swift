//
//  PaywallAssignmentStorage.swift
//  XeeSDK
//

import Foundation

private let log = Log.storage

/// The server's arm for each paywall, per profile: asked for once per test, then kept (Xee+Paywalls.swift).
@XeeActor
enum PaywallAssignmentStorage {
    private static let key = "XeeSDK_Paywall_Assignments"
    private static let userDefaults = Storage.userDefaults

    private static var byKey: [String: PaywallAssignment] = {
        do {
            return try userDefaults.getJSON([String: PaywallAssignment].self, forKey: key) ?? [:]
        } catch {
            log.error(error.localizedDescription)
            return [:]
        }
    }()

    private static func id(_ profileId: String, _ paywallId: String) -> String { "\(profileId)/\(paywallId)" }

    static func assignment(profileId: String, paywallId: String) -> PaywallAssignment? {
        byKey[id(profileId, paywallId)]
    }

    static func set(_ value: PaywallAssignment, profileId: String, paywallId: String) {
        byKey[id(profileId, paywallId)] = value
        save()
    }

    static func clear(profileId: String, paywallId: String) {
        byKey[id(profileId, paywallId)] = nil
        save()
    }

    private static func save() {
        do {
            try userDefaults.setJSON(byKey, forKey: key)
        } catch {
            log.error("Saving paywall assignment fail. \(error.localizedDescription)")
        }
    }
}
