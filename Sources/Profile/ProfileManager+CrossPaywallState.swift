// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  ProfileManager+CrossPaywallState.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 02.04.2025.
//

private extension Xee {
    func syncCrossPaywallState(userId: XeeUserId) async throws(XeeError) {
        let state: CrossPaywallState

        do {
            state = try await httpSession.fetchCrossPaywallState(userId: userId)
        } catch {
            throw error.asXeeError
        }

        guard let manager = try profileManager(withProfileId: userId) else {
            throw .profileWasChanged()
        }
        manager.saveCrossPaywallState(state)
    }
}

extension ProfileManager {
    func syncCrossPaywallState() async throws(XeeError) {
        try await Xee.activatedSDK.syncCrossPaywallState(userId: userId)
    }

    func saveCrossPaywallState(_ newState: CrossPaywallState) {
        let oldState = crossPlacmentStorage.state

        guard newState.isNewerThan(oldState) else { return }

        Log.crossAB.verbose("updateProfile version = \(newState.version), newValue = \(newState.variationIdByPaywalls), oldValue = \(oldState?.variationIdByPaywalls.description ?? "DISABLED")")

        crossPlacmentStorage.setState(newState)
    }
}
