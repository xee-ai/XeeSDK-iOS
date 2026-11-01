#if canImport(Testing)

@testable import Xee
import Foundation
import Testing

/// A server that stalls: the host's name says how. `stall-*`: the first request never answers. `slow-*`: the first
/// answers after 0.6 s. Every other request answers at once. Each test uses its own host, so the counts do not mix.
private final class StallingProtocol: URLProtocol, @unchecked Sendable {
    private static let lock = NSLock()
    nonisolated(unsafe) private static var seen: [String: [URLRequest]] = [:]

    static func requests(to host: String) -> [URLRequest] {
        lock.lock()
        defer { lock.unlock() }
        return seen[host] ?? []
    }

    override class func canInit(with request: URLRequest) -> Bool { request.url?.host?.hasSuffix(".hedge.test") == true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let url = request.url, let host = url.host else { return }
        Self.lock.lock()
        Self.seen[host, default: []].append(request)
        let number = Self.seen[host]!.count
        Self.lock.unlock()

        if host.hasPrefix("stall"), number == 1 { return }  // never answers; the cancel arrives in stopLoading
        let delay = host.hasPrefix("slow") && number == 1 ? 0.6 : 0
        DispatchQueue.global().asyncAfter(deadline: .now() + delay) { [self] in
            let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: [:])!
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: Data("{}".utf8))
            client?.urlProtocolDidFinishLoading(self)
        }
    }

    override func stopLoading() {}
}

private struct StubConfiguration: HTTPCodableConfiguration {
    let sessionConfiguration: URLSessionConfiguration
    let hedgeReadsAfter: TaskDuration?

    init(hedgeAfter: TaskDuration?) {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StallingProtocol.self]
        sessionConfiguration = configuration
        hedgeReadsAfter = hedgeAfter
    }
}

private struct Read: HTTPRequest {
    let endpoint: HTTPEndpoint
    let isQuickRead: Bool
    let stamp = "test"
    init(method: HTTPMethod = .get, quick: Bool) {
        endpoint = HTTPEndpoint(method: method, path: "/profile")
        isQuickRead = quick
    }
}

struct HedgedSessionTests {
    private func session(hedgeAfter: TaskDuration? = .milliseconds(150)) -> HTTPSession {
        HTTPSession(configuration: StubConfiguration(hedgeAfter: hedgeAfter))
    }

    private func send(_ session: HTTPSession, _ request: Read, _ host: String) async throws -> HTTPDataResponse {
        try await session.perform(request, withBaseUrl: URL(string: "https://\(host)")!, withDecoder: HTTPDataResponse.dataDecoder)
    }

    @Test func aQuickReadThatStallsIsAnsweredByASecondRequest() async throws {
        let host = "stall-1.hedge.test"
        let start = Date()
        let response = try await send(session(), Read(quick: true), host)
        #expect(response.statusCode == 200)
        #expect(Date().timeIntervalSince(start) < 2)
        #expect(StallingProtocol.requests(to: host).count == 2)
    }

    @Test func aQuickReadThatAnswersInTimeSendsOneRequest() async throws {
        let host = "fast-1.hedge.test"
        _ = try await send(session(), Read(quick: true), host)
        try await Task.sleep(nanoseconds: 400_000_000)
        #expect(StallingProtocol.requests(to: host).count == 1)
    }

    @Test func aRequestThatIsNotAQuickReadIsNeverSentTwice() async throws {
        let host = "slow-1.hedge.test"
        let start = Date()
        _ = try await send(session(), Read(method: .patch, quick: false), host)
        #expect(Date().timeIntervalSince(start) >= 0.5)
        #expect(StallingProtocol.requests(to: host).count == 1)
    }

    @Test func withoutAHedgeDelayNothingIsSentTwice() async throws {
        let host = "slow-2.hedge.test"
        _ = try await send(session(hedgeAfter: nil), Read(quick: true), host)
        #expect(StallingProtocol.requests(to: host).count == 1)
    }

    @Test func theConnectionThatWonTheHedgeBecomesTheMainOneForEveryRequest() async throws {
        let host = "stall-3.hedge.test"
        let http = session()
        #expect(http.hedgeWins == 0)
        _ = try await send(http, Read(quick: true), host)
        #expect(http.hedgeWins == 1)
        // Reads and writes now go out on the connection that answered; nothing stalls on the old one.
        let start = Date()
        _ = try await send(http, Read(quick: true), host)
        _ = try await send(http, Read(method: .patch, quick: false), host)
        #expect(Date().timeIntervalSince(start) < 0.3)
        #expect(http.hedgeWins == 1)
    }

    @Test func aQuickReadThatAnswersInTimeChangesNothing() async throws {
        let http = session()
        _ = try await send(http, Read(quick: true), "fast-3.hedge.test")
        try await Task.sleep(nanoseconds: 300_000_000)
        #expect(http.hedgeWins == 0)
    }

    @Test func aQuickReadWaitsAtMostFiveSecondsAndOtherRequestsKeepTheirTimeout() async throws {
        let host = "fast-2.hedge.test"
        _ = try await send(session(), Read(quick: true), host)
        _ = try await send(session(), Read(method: .patch, quick: false), host)
        let timeouts = StallingProtocol.requests(to: host).map(\.timeoutInterval)
        #expect(timeouts == [5, 60])
    }
}

#endif
