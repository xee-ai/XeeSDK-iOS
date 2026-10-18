// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  HTTPConfiguration.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 08.09.2022.
//

import Foundation

protocol HTTPConfiguration: Sendable {
    var sessionConfiguration: URLSessionConfiguration { get }
}

extension HTTPConfiguration {
    var sessionConfiguration: URLSessionConfiguration { .ephemeral }
}
