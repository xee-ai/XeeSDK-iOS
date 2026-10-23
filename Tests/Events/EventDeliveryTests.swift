#if canImport(Testing)

@testable import Xee
import Foundation
import Testing
import zlib

/// The event queue on disk, how a failed send is handled, the gzipped body, and the order and
/// opt-out of `Xee.track`.
@EventsManagerActor
struct EventDeliveryTests {
    private func database() -> EventsDatabase {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("xee-events-\(UUID().uuidString).sqlite")
        return EventsDatabase(url: url)
    }

    private func blob(_ n: Int) -> Data { Data(repeating: 0x61, count: n) }

    // MARK: - queue on disk

    @Test func rowsComeBackInOrderDefaultEventsFirst() {
        let db = database()
        db.insert(kind: .sysLog, name: "system_log", data: blob(1))
        db.insert(kind: .default, name: "a", data: blob(1))
        db.insert(kind: .default, name: "b", data: blob(1))
        let rows = db.rows(maxCount: 10, maxBytes: 1000)
        #expect(rows.map(\.name) == ["a", "b", "system_log"])
        db.delete(ids: rows.prefix(2).map(\.id))
        #expect(db.rows(maxCount: 10, maxBytes: 1000).map(\.name) == ["system_log"])
    }

    @Test func aBatchStopsAtTheCountOrTheBytesButTakesAtLeastOne() {
        let db = database()
        for i in 0 ..< 5 { db.insert(kind: .default, name: "e\(i)", data: blob(100)) }
        #expect(db.rows(maxCount: 3, maxBytes: 10_000).count == 3)
        #expect(db.rows(maxCount: 10, maxBytes: 250).count == 2)
        #expect(db.rows(maxCount: 10, maxBytes: 10).count == 1, "one event larger than the budget still goes alone")
    }

    @Test func theQueueKeepsTheNewestRowsPerKind() {
        let db = database()
        for i in 0 ..< 6 { db.insert(kind: .default, name: "e\(i)", data: blob(1)) }
        db.insert(kind: .sysLog, name: "s", data: blob(1))
        #expect(db.trim(kind: .default, keep: 4) == 2)
        #expect(db.rows(maxCount: 10, maxBytes: 1000).map(\.name) == ["e2", "e3", "e4", "e5", "s"])
    }

    @Test func rowsCanBeRemovedByNameOrAll() {
        let db = database()
        db.insert(kind: .default, name: "xee_track", data: blob(1))
        db.insert(kind: .default, name: "paywall_showed", data: blob(1))
        db.delete(name: "xee_track")
        #expect(db.rows(maxCount: 10, maxBytes: 1000).map(\.name) == ["paywall_showed"])
        db.deleteAll()
        #expect(db.isEmpty)
    }

    @Test func theQueueSurvivesReopening() {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("xee-events-\(UUID().uuidString).sqlite")
        EventsDatabase(url: url).insert(kind: .default, name: "kept", data: blob(3))
        #expect(EventsDatabase(url: url).rows(maxCount: 10, maxBytes: 1000).map(\.data) == [blob(3)])
    }

    // MARK: - send policy

    @Test func failuresBackOffExponentiallyUpToTenMinutes() {
        var p = EventsSendPolicy()
        let delays = (0 ..< 8).map { _ in p.failed(status: 503, retryAfter: nil, eventCount: 1, gzipped: false, jitter: 0) }
        #expect(delays == [20, 40, 80, 160, 320, 600, 600, 600].map { .backoff($0) })
        p.succeeded()
        #expect(p.failed(status: nil, retryAfter: nil, eventCount: 1, gzipped: false, jitter: 0) == .backoff(20), "a success resets it")
        #expect(p.failed(status: 503, retryAfter: nil, eventCount: 1, gzipped: false, jitter: 1) == .backoff(50), "up to a quarter more of jitter")
    }

    @Test func retryAfterIsHonoured() {
        var p = EventsSendPolicy()
        #expect(p.failed(status: 429, retryAfter: 300, eventCount: 1, gzipped: false, jitter: 0) == .backoff(300))
        #expect(p.failed(status: 429, retryAfter: 5, eventCount: 1, gzipped: false, jitter: 0) == .backoff(40), "never sooner than the backoff")
    }

    @Test func aBatchTooLargeIsHalvedThenDropped() {
        var p = EventsSendPolicy()
        #expect(p.failed(status: 413, retryAfter: nil, eventCount: 10, gzipped: true, jitter: 0) == .shrink)
        #expect(p.byteBudget == EventsSendPolicy.maxBytes / 2)
        #expect(p.failed(status: 413, retryAfter: nil, eventCount: 1, gzipped: true, jitter: 0) == .drop, "one event the server cannot take")
        p.succeeded()
        #expect(p.byteBudget == EventsSendPolicy.maxBytes, "the budget grows back after a success")
    }

    @Test func aRefusedGzippedBodyIsSentPlainOnceThenDropped() {
        var p = EventsSendPolicy()
        #expect(p.gzip)
        #expect(p.failed(status: 400, retryAfter: nil, eventCount: 3, gzipped: true, jitter: 0) == .resendPlain)
        #expect(!p.gzip)
        #expect(p.failed(status: 400, retryAfter: nil, eventCount: 3, gzipped: false, jitter: 0) == .drop)
        #expect(p.failed(status: 401, retryAfter: nil, eventCount: 3, gzipped: false, jitter: 0) == .backoff(20), "a key problem is kept, not dropped")
    }

    // MARK: - gzip

    @Test func theBodyIsGzip() throws {
        let plain = Data(String(repeating: #"{"event_name":"xee_track"},"#, count: 200).utf8)
        let packed = try #require(plain.gzipped())
        #expect(packed.prefix(2) == Data([0x1F, 0x8B]))
        #expect(packed.count < plain.count / 5)
        #expect(gunzip(packed) == plain)
        #expect(gunzip(try #require(Data().gzipped())) == Data())
    }

    @Test func theRequestSaysItIsGzipped() throws {
        let user = XeeUserId(profileId: "33333333-cccc-4ccc-8ccc-333333333333", customerId: nil)
        let events = [Data(#"{"event_name":"a"}"#.utf8)]
        let packed = SendEventsRequest(userId: user, events: events, gzip: true)
        #expect(packed.headers["Content-Encoding"] == "gzip")
        let plain = SendEventsRequest(userId: user, events: events, gzip: false)
        #expect(plain.headers["Content-Encoding"] == nil)
        let body = try #require(try plain.getData(configuration: HTTPConfigurationStub()))
        #expect(gunzip(try #require(try packed.getData(configuration: HTTPConfigurationStub()))) == body)
    }

    private func gunzip(_ data: Data) -> Data? {
        var stream = z_stream()
        guard inflateInit2_(&stream, MAX_WBITS + 16, ZLIB_VERSION, Int32(MemoryLayout<z_stream>.size)) == Z_OK else { return nil }
        defer { inflateEnd(&stream) }
        var out = Data()
        var buffer = [UInt8](repeating: 0, count: 16384)
        var status: Int32 = Z_OK
        data.withUnsafeBytes { (input: UnsafeRawBufferPointer) in
            stream.next_in = UnsafeMutablePointer(mutating: input.bindMemory(to: Bytef.self).baseAddress)
            stream.avail_in = uInt(input.count)
            repeat {
                buffer.withUnsafeMutableBufferPointer { b in
                    stream.next_out = b.baseAddress
                    stream.avail_out = uInt(b.count)
                    status = inflate(&stream, Z_NO_FLUSH)
                    out.append(b.baseAddress!, count: b.count - Int(stream.avail_out))
                }
            } while status == Z_OK
        }
        return status == Z_STREAM_END ? out : nil
    }

    // MARK: - Xee.track order, before activation, opt-out

    @Test func trackedEventsReachTheQueueInCallOrderOnceActivated() async {
        let sink = Sink()
        let gate = Gate()
        let queue = XeeTrackQueue(
            isActivated: { await gate.isOpen },
            send: { p, _ in await sink.add(p.name) },
            optOut: OptOutFlag(defaults: nil)
        )
        for i in 0 ..< 50 { queue.enqueue(XeeTrackParameters(name: "e\(i)", properties: [:]), at: Date()) }
        await queue.drained()
        #expect(await sink.names.isEmpty, "held until Xee.activate")
        await gate.open()
        queue.activated()
        await queue.drained()
        #expect(await sink.names == (0 ..< 50).map { "e\($0)" })
    }

    @Test func eventsHeldBeforeActivationAreCapped() async {
        let sink = Sink()
        let queue = XeeTrackQueue(isActivated: { false }, send: { p, _ in await sink.add(p.name) }, optOut: OptOutFlag(defaults: nil))
        for i in 0 ..< (XeeTrackQueue.maxHeld + 5) { queue.enqueue(XeeTrackParameters(name: "e\(i)", properties: [:]), at: Date()) }
        #expect(queue.heldCount == XeeTrackQueue.maxHeld, "the oldest are dropped")
    }

    @Test func anOptedOutUserSendsNothing() async {
        let sink = Sink()
        let flag = OptOutFlag(defaults: nil)
        let queue = XeeTrackQueue(isActivated: { true }, send: { p, _ in await sink.add(p.name) }, optOut: flag)
        flag.set(true)
        queue.enqueue(XeeTrackParameters(name: "hidden", properties: [:]), at: Date())
        await queue.drained()
        flag.set(false)
        queue.enqueue(XeeTrackParameters(name: "shown", properties: [:]), at: Date())
        await queue.drained()
        #expect(await sink.names == ["shown"])
    }
}

private struct HTTPConfigurationStub: HTTPConfiguration {}

private actor Sink {
    var names: [String] = []
    func add(_ name: String) { names.append(name) }
}

private actor Gate {
    var isOpen = false
    func open() { isOpen = true }
}

#endif
