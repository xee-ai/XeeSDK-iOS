// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
#if canImport(Testing)

@testable import Xee
import Foundation
import Testing

/// Records every request the SDK sends and answers with just enough JSON for the profile calls.
final class RecordingURLProtocol: URLProtocol, @unchecked Sendable {
    nonisolated(unsafe) private static var recorded: [URLRequest] = []
    private static let lock = NSLock()

    static func snapshot() -> [URLRequest] {
        lock.lock()
        defer { lock.unlock() }
        return recorded
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    /// What the SDK decodes from each endpoint on activation. The shapes come from the SDK's decoders.
    static func answer(for request: URLRequest) -> [String: Any] {
        let path = request.url?.path ?? ""
        switch true {
        case path.contains("/sdk/analytics/profiles/"):
            return ["data": [
                "type": "xee_profile_response",
                "id": "11111111-1111-4111-8111-111111111111",
                "attributes": [
                    "profile_id": "11111111-1111-4111-8111-111111111111",
                    "segment_hash": "segment",
                    "paid_access_levels": [String: Any](),
                    "subscriptions": [String: Any](),  // an object keyed by store product id
                    "non_subscriptions": [String: Any](),  // an object of arrays keyed by product id
                    "timestamp": 1,
                ] as [String: Any],
            ] as [String: Any]]
        case path.contains("/products/app_store"):  // URL.path drops the trailing slash
            return ["data": [Any]()]
        case path.contains("/cross-paywall-info"):
            return ["data": ["paywall_with_variation_map": [String: Any](), "version": 1]]
        case path.hasSuffix("/net-config.json"):
            return ["data": [
                "event_blacklist": [String](),
                "api_endpoints": ["default": ["https://server.example.test/api/v1"]],
                "expires_in": 3_600_000,
                "retry_interval": 1_800_000,
            ] as [String: Any]]
        case path.hasSuffix("/attribution/install"):
            return ["data": ["install_id": "install-1"]]
        default:
            return ["data": [String: Any]()]
        }
    }

    override func startLoading() {
        Self.lock.lock()
        Self.recorded.append(request)
        Self.lock.unlock()

        let body = (try? JSONSerialization.data(withJSONObject: Self.answer(for: request))) ?? Data()
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: 200,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "application/json"]
        )!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: body)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

@Suite(.serialized)
struct WireTests {
    @Test(.timeLimit(.minutes(1)))
    func activateIdentifyAndGetProfileSpeakTheXeeWire() async throws {
        let key = "xee_0123456789abcdef0123456789abcdef"
        let configuration = XeeConfiguration
            .builder(withAPIKey: key)
            .with(serverUrl: URL(string: "https://server.example.test")!)
            .with(urlProtocolClasses: [RecordingURLProtocol.self])
            .build()

        try await Xee.activate(with: configuration)
        try await Xee.identify("customer-1")
        _ = try await Xee.getProfile()

        let seen = RecordingURLProtocol.snapshot()
        let profileCalls = seen.filter { $0.url?.path.contains("/sdk/analytics/profiles/") == true }
        #expect(!profileCalls.isEmpty, "the SDK made no profile request: \(seen.map { $0.url?.absoluteString ?? "" })")
        #expect(profileCalls.contains { $0.httpMethod == "POST" }, "no create-profile call")

        for request in seen {
            #expect(request.url?.host == "server.example.test", "\(request.url?.absoluteString ?? "")")
            #expect(request.value(forHTTPHeaderField: "Authorization") == "Api-Key \(key)", "\(request.httpMethod ?? "") \(request.url?.absoluteString ?? "")")
            let names = (request.allHTTPHeaderFields ?? [:]).keys.map { $0.lowercased() }
            #expect(names.contains("xee-sdk-version"), "\(request.url?.absoluteString ?? "") headers: \(names)")
            let forbidden = ["adap", "ty-"].joined()
            #expect(!names.contains { $0.hasPrefix(forbidden) }, "headers: \(names)")
        }
    }
}

#endif
