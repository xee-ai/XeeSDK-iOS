//  Environment.Application.swift
//  XeeSDK
//
//  Created by Xee team.
//

import Foundation

extension Environment {
    enum Application {
        static let sessionIdentifier = UUID().uuidString.lowercased()

        static let bundleIdentifier: String? = Bundle.main.bundleIdentifier
        static let version: String? = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        static let build: String? = Bundle.main.infoDictionary?["CFBundleVersion"] as? String
    }
}
