// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  XeeProfileParameters.Builder.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 26.09.2022.
//

import Foundation

public extension XeeProfileParameters {
    final class Builder {
        var parameters: XeeProfileParameters

        public convenience init() {
            self.init(XeeProfileParameters())
        }

        init(_ values: XeeProfileParameters) {
            self.parameters = values
        }

        public func build() -> XeeProfileParameters { parameters }
    }
}

public extension XeeProfileParameters.Builder {
    @discardableResult
    func with(firstName value: String?) -> Self {
        parameters.firstName = value.trimmed.nonEmptyOrNil
        return self
    }

    @discardableResult
    func with(lastName value: String?) -> Self {
        parameters.lastName = value.trimmed.nonEmptyOrNil
        return self
    }

    @discardableResult
    func with(gender value: XeeProfile.Gender?) -> Self {
        parameters.gender = value
        return self
    }

    @discardableResult
    func with(birthday value: Date?) -> Self {
        guard let value else {
            parameters.birthday = nil
            return self
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "YYYY-MM-dd"
        parameters.birthday = formatter.string(from: value)
        return self
    }

    @discardableResult
    func with(email value: String?) -> Self {
        parameters.email = value.trimmed.nonEmptyOrNil
        return self
    }

    @discardableResult
    func with(phoneNumber value: String?) -> Self {
        parameters.phoneNumber = value.trimmed.nonEmptyOrNil
        return self
    }

    @discardableResult
    func with(analyticsDisabled value: Bool?) -> Self {
        parameters.analyticsDisabled = value
        return self
    }

    @discardableResult
    func withRemoved(customAttributeForKey key: String) throws(XeeError) -> Self {
        try with(customAttribute: .none, forKey: key)
    }

    @discardableResult
    func with(customAttribute value: String, forKey key: String) throws(XeeError) -> Self {
        guard let value = value.trimmed.nonEmptyOrNil else {
            return try with(customAttribute: .none, forKey: key)
        }
        return try with(customAttribute: .string(value), forKey: key)
    }

    @discardableResult
    func with(customAttribute value: Double, forKey key: String) throws(XeeError) -> Self {
        try with(customAttribute: .double(value), forKey: key)
    }

    private func with(customAttribute value: XeeProfile.CustomAttributeValue, forKey key: String) throws(XeeError) -> Self {
        let key = key.trimmed
        try XeeProfile.CustomAttributes.validateKey(key)
        try value.validateLenght()
        var attributes = parameters.codableCustomAttributes ?? XeeProfile.CustomAttributes()
        attributes.updateValue(value, forKey: key)
        try attributes.validateCount()
        parameters.codableCustomAttributes = attributes
        return self
    }
}

extension XeeProfileParameters.Builder: Decodable {
    public convenience init(from decoder: any Decoder) throws {
        var parameters = XeeProfileParameters()
        let container = try decoder.container(keyedBy: XeeProfileParameters.CodingKeys.self)

        parameters.firstName = try container.decodeIfPresent(String.self, forKey: .firstName).trimmed.nonEmptyOrNil
        parameters.lastName = try container.decodeIfPresent(String.self, forKey: .lastName).trimmed.nonEmptyOrNil
        parameters.gender = try container.decodeIfPresent(XeeProfile.Gender.self, forKey: .gender)
        parameters.birthday = try container.decodeIfPresent(String.self, forKey: .birthday).trimmed.nonEmptyOrNil
        parameters.email = try container.decodeIfPresent(String.self, forKey: .email).trimmed.nonEmptyOrNil
        parameters.phoneNumber = try container.decodeIfPresent(String.self, forKey: .phoneNumber).trimmed.nonEmptyOrNil
        parameters.appTrackingTransparencyStatus = try container.decodeIfPresent(XeeProfileParameters.AppTrackingTransparencyStatus.self, forKey: .appTrackingTransparencyStatus)
        parameters.analyticsDisabled = try container.decodeIfPresent(Bool.self, forKey: .analyticsDisabled)

        if let customAttributes = try container.decodeIfPresent(XeeProfile.CustomAttributes.self, forKey: .codableCustomAttributes) {
            try customAttributes.validateCount()
            parameters.codableCustomAttributes = customAttributes
        }

        self.init(parameters)
    }
}

#if !XEE_KIDS_MODE && canImport(AppTrackingTransparency)
import AppTrackingTransparency

public extension XeeProfileParameters.Builder {
    @available(iOS 14, macOS 11.0, visionOS 1.0, *)
    @discardableResult
    func with(appTrackingTransparencyStatus value: ATTrackingManager.AuthorizationStatus?) -> Self {
        guard let value else {
            parameters.appTrackingTransparencyStatus = nil
            return self
        }
        parameters.appTrackingTransparencyStatus = XeeProfileParameters.AppTrackingTransparencyStatus(from: Int(value.rawValue))
        return self
    }
}
#endif
