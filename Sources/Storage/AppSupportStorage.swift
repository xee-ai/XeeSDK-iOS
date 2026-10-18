// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  AppSupportStorage.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 22.12.2025.
//

import Foundation

private let log = Log.storage

enum AppSupportStorage {
    private enum Constants {
        static let fileName = "xee.sdk"
    }

    private struct SDKInfo: Codable {
        let installIdentifier: String

        enum CodingKeys: String, CodingKey {
            case installIdentifier = "install_identifier"
        }
    }

    @XeeActor
    static func getTnstallIdentifier() -> String? {
        do {
            guard let data = try AppDirectory.applicationSupport(fileName: Constants.fileName) else { return nil }
            return try JSONDecoder().decode(SDKInfo.self, from: data).installIdentifier
        } catch {
            log.error("Load \(Constants.fileName) error: \(error)")
            return nil
        }
    }

    @XeeActor
    static func setInstallIdentifier(_ value: String) -> Bool {
        log.debug("AppSupportStorage setInstallIdentifier = \(value)")

        do {
            let data = try JSONEncoder().encode(SDKInfo(installIdentifier: value))
            try AppDirectory.setApplicationSupport(data: data, fileName: Constants.fileName)
            return true
        } catch {
            log.error("AppSupportStorage Save \(Constants.fileName) error: \(error)")
            return false
        }
    }
}
