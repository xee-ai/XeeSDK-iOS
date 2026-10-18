// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  UserAcquisitionManager.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 16.06.2025.
//

import Foundation

@XeeActor
final class UserAcquisitionManager {
    private let storage: UserAcquisitionStorage
    private let executor: Backend.UAExecutor
    private let installTime: Date
    private let appLaunchCount: Int

    private var registerInstallStarted = false

    private init?(_ sdk: Xee) {
        let storage = UserAcquisitionStorage()
        guard
            let installTime = Environment.Application.installationTime,
            let appLaunchCount = Environment.Application.appLaunchCount,
            storage.version > 0
        else { return nil }

        self.storage = storage
        self.executor = sdk.backend.createUAExecutor()
        self.installTime = installTime
        self.appLaunchCount = appLaunchCount

        if storage.hasRegistrationInstallResponse {
            let response = storage.registrationInstallResponse
            let details = response.asXeeInstallationDetails(
                installTime: installTime,
                appLaunchCount: appLaunchCount
            )
            Xee.callDelegate { $0.onInstallationDetailsSuccess(details) }

        } else {
            startRegisterInstallTaskIfNeeded()
        }
    }

    func startRegisterInstallTaskIfNeeded(maxRetries: Int = 10) {
        guard
            !storage.hasRegistrationInstallResponse,
            !registerInstallStarted,
            let sdk = Xee.optionalSDK
        else { return }

        registerInstallStarted = true

        let installTime = installTime
        let appLaunchCount = appLaunchCount

        Task { @XeeActor in
            defer { registerInstallStarted = false }

            let installInfo = await Environment.InstallInfo(
                installTime: installTime,
                appLaunchCount: appLaunchCount,
                includedAnalyticIds: true
            )

            do throws(HTTPError) {
                let response = try await executor.registerInstall(
                    userId: sdk.profileStorage.userId,
                    installInfo: installInfo,
                    maxRetries: maxRetries
                )
                storage.setRegistrationInstallResponse(response)

                let details = response.asXeeInstallationDetails(
                    installTime: installInfo.installTime,
                    appLaunchCount: installInfo.appLaunchCount
                )

                Xee.callDelegate { $0.onInstallationDetailsSuccess(details) }

            } catch {
                guard !error.isCancelled else { return }
                Xee.callDelegate { $0.onInstallationDetailsFail(error: error.asXeeError) }
            }
        }
    }

    func getCurrentInstallationStatus() async -> XeeInstallationStatus {
        guard
            let installTime = Environment.Application.installationTime,
            let appLaunchCount = Environment.Application.appLaunchCount
        else { return .notAvailable }

        guard storage.hasRegistrationInstallResponse
        else { return .notDetermined }

        let response = storage.registrationInstallResponse

        return .determined(response.asXeeInstallationDetails(
            installTime: installTime,
            appLaunchCount: appLaunchCount
        ))
    }
}

@XeeActor
extension UserAcquisitionManager {
    static var shared: UserAcquisitionManager?
    static func activate(_ sdk: Xee) { shared = .init(sdk) }
}

private extension RegistrationInstallResponse? {
    func asXeeInstallationDetails(installTime: Date, appLaunchCount: Int) -> XeeInstallationDetails {
        let response = self
        return .init(
            id: response?.id,
            installTime: installTime,
            appLaunchCount: appLaunchCount,
            payload: response?.payload
        )
    }
}
