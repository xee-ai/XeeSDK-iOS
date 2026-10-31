//  AnyCodingKeys.swift
//  XeeSDK
//
//  Created by Xee team.
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
