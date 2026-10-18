// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  RegistrationInstallResponse.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 12.06.2025.
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
