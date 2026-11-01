//  HTTPConfiguration.swift
//  XeeSDK
//
//  Created by Xee team.
//

import Foundation

protocol HTTPConfiguration: Sendable {
    var sessionConfiguration: URLSessionConfiguration { get }
    /// After this long without an answer, a quick read (`HTTPRequest.isQuickRead`) is sent again on its own connection
    /// and the first answer wins. Nil: never.
    var hedgeReadsAfter: TaskDuration? { get }
}

extension HTTPConfiguration {
    var sessionConfiguration: URLSessionConfiguration { .ephemeral }
    var hedgeReadsAfter: TaskDuration? { nil }
}
