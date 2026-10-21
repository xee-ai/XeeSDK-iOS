import Foundation

/// What the person did with the store and how it ended: a purchase or a restore, and its result.
/// The server keeps these on the profile so the dashboard can show them.
struct XeeActivityParameters: Sendable {
    enum Kind: String, Sendable, Codable {
        case purchase
        case restore
    }

    enum Result: String, Sendable, Codable {
        case success
        case cancelled
        case pending
        case failed
    }

    let kind: Kind
    let result: Result
    let productId: String?
    let variationId: String?
    /// The error's description when `result` is `failed`.
    let error: String?
}

extension XeeActivityParameters: Codable {
    enum CodingKeys: String, CodingKey {
        case kind = "activity_kind"
        case result = "activity_result"
        case productId = "product_id"
        case variationId = "variation_id"
        case error = "activity_error"
    }
}
