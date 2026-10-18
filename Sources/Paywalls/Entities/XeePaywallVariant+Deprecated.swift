// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  XeePaywallVariant+Deprecated.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 01.07.2025.
//

public extension XeePaywallVariant {
    @available(*, deprecated, renamed: "paywall.id")
    var paywallId: String { paywall.id }

    @available(*, deprecated, renamed: "paywall.audienceName")
    var audienceName: String { paywall.audienceName }

    @available(*, deprecated, renamed: "paywall.revision")
    var revision: Int { paywall.revision }

    @available(*, deprecated, renamed: "paywall.abTestName")
    var abTestName: String { paywall.abTestName }
}
