//  HTTPEncodableRequest.swift
//  XeeSDK
//
//  Created by Xee team.
//

import Foundation

protocol HTTPEncodableRequest: HTTPDataRequest, Encodable {}

extension HTTPEncodableRequest {
    func getData(configuration: HTTPConfiguration) throws -> Data? {
        let encoder = JSONEncoder()
        (configuration as? HTTPCodableConfiguration)?.configure(jsonEncoder: encoder)
        return try encoder.encode(self)
    }
}
