//  ProfileManager+SentEnvironment.swift
//  XeeSDK
//
//  Created by Xee team.
//

import StoreKit

extension ProfileManager {
    enum SentEnvironment: Sendable, Hashable { // TODO: need refactoring
        case none
        case withIdfa
        case withoutIdfa
    }
}

extension Environment.Meta {
    var sentEnvironment: ProfileManager.SentEnvironment {
        idfa == nil ? .withoutIdfa : .withIdfa
    }
}

extension ProfileManager.SentEnvironment {
    func needSend(analyticsDisabled: Bool) async -> Bool {
        switch self {
        case .none:
            return true
        case .withIdfa:
            return false
        case .withoutIdfa:
            guard !analyticsDisabled else { return false }
            return await Environment.Device.idfaRetrievalStatus == .allowed
        }
    }

    @XeeActor
    func getValueIfNeedSend(analyticsDisabled: Bool) async -> Environment.Meta? {
        guard await needSend(analyticsDisabled: analyticsDisabled) else { return nil }

        let meta = await Environment.Meta(includedAnalyticIds: !analyticsDisabled)

        if meta.idfa == nil, self == .withoutIdfa {
            return nil
        }

        return meta
    }
}
