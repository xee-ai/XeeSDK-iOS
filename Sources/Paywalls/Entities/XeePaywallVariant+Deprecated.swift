//  XeePaywallVariant+Deprecated.swift
//  XeeSDK
//
//  Created by Xee team.
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
