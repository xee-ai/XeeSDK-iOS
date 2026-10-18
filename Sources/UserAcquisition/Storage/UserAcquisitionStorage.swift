// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  UserAcquisitionStorage.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 18.06.2025.
//

import Foundation

private let log = Log.storage

@XeeActor
final class UserAcquisitionStorage {
    private enum Constants {
        static let version = "XeeSDK_User_Acquisition_Version"
        static let registrationInstallSaved = "XeeSDK_User_Acquisition_saved"
        static let registrationInstallId = "XeeSDK_User_Acquisition_install_id"
        static let registrationInstallPayload = "XeeSDK_User_Acquisition_install_payload"
    }

    private static let userDefaults = Storage.userDefaults

    private static var version: Int = {
        let version = userDefaults.integer(forKey: Constants.version)
        guard version == 0, let installTime = Environment.Application.installationTime else {
            return version
        }
        userDefaults.set(Xee.userAcquisitionVersion, forKey: Constants.version)
        return Xee.userAcquisitionVersion
    }()

    private static var hasRegistrationInstallResponse: Bool = userDefaults.bool(forKey: Constants.registrationInstallSaved)

    private static var registrationInstallResponse: RegistrationInstallResponse? {
        guard hasRegistrationInstallResponse,
              let id = userDefaults.string(forKey: Constants.registrationInstallId)
        else {
            return nil
        }

        let payload: XeeInstallationDetails.Payload? = userDefaults.string(forKey: Constants.registrationInstallPayload)
            .map { .init(jsonString: $0) }

        return .init(id: id, payload: payload)
    }

    private static func setRegistrationInstallResponse(_ response: RegistrationInstallResponse?) {
        hasRegistrationInstallResponse = true
        userDefaults.set(true, forKey: Constants.registrationInstallSaved)
        if let id = response?.id {
            userDefaults.set(id, forKey: Constants.registrationInstallId)
        } else {
            userDefaults.removeObject(forKey: Constants.registrationInstallId)
        }
        if let payload = response?.payload?.jsonString {
            userDefaults.set(payload, forKey: Constants.registrationInstallPayload)
        } else {
            userDefaults.removeObject(forKey: Constants.registrationInstallPayload)
        }
    }

    static func clear() {
        hasRegistrationInstallResponse = false
        userDefaults.removeObject(forKey: Constants.registrationInstallSaved)
        userDefaults.removeObject(forKey: Constants.registrationInstallId)
        userDefaults.removeObject(forKey: Constants.registrationInstallPayload)
    }
}

@XeeActor
extension UserAcquisitionStorage {
    var version: Int { Self.version }

    var hasRegistrationInstallResponse: Bool {
        Self.hasRegistrationInstallResponse
    }

    var registrationInstallResponse: RegistrationInstallResponse? {
        Self.registrationInstallResponse
    }

    func setRegistrationInstallResponse(_ response: RegistrationInstallResponse?) {
        Self.setRegistrationInstallResponse(response)
    }
}
