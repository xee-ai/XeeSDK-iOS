//  HTTPConfiguration.swift
//  XeeSDK
//
//  Created by Xee team.
//

import Foundation

protocol HTTPConfiguration: Sendable {
    var sessionConfiguration: URLSessionConfiguration { get }
}

extension HTTPConfiguration {
    var sessionConfiguration: URLSessionConfiguration { .ephemeral }
}
