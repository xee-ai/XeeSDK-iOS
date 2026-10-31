//  RegistrationInstallResponse.swift
//  XeeSDK
//
//  Created by Xee team.
//

import Foundation

struct RegistrationInstallResponse: Sendable, Hashable, Identifiable {
    let id: String
    let payload: XeeInstallationDetails.Payload?
}

extension RegistrationInstallResponse: CustomStringConvertible {
    public var description: String {
        "(id: \(id), payload: \(payload?.jsonString ?? "nil")"
    }
}

extension RegistrationInstallResponse: Codable {
    enum CodingKeys: String, CodingKey {
        case id = "install_id"
        case payload
    }
}
