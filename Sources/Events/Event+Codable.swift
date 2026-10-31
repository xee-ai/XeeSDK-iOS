//  Event+Codable.swift
//  XeeSDK
//
//  Created by Xee team.
//

import Foundation

extension Event {
    static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .formatted(Backend.inUTCDateFormatter)
        encoder.dataEncodingStrategy = .base64
        return encoder
    }()

    static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(Backend.inUTCDateFormatter)
        decoder.dataDecodingStrategy = .base64
        return decoder
    }()
}
