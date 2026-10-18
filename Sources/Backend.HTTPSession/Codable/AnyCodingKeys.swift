// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  AnyCodingKeys.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 05.04.2023
//

import Foundation

struct AnyCodingKeys: CodingKey {
    var stringValue: String
    var intValue: Int?

    init(stringValue: String) {
        self.stringValue = stringValue
    }

    init?(intValue: Int) {
        self.init(stringValue: "\(intValue)")
        self.intValue = intValue
    }
}
