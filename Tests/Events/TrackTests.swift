#if canImport(Testing)

@testable import Xee
import Foundation
import Testing

struct TrackTests {
    private func make(_ name: String, _ properties: [String: XeeProperty] = [:], duration: Int? = nil) -> XeeTrackParameters? {
        XeeTrackParameters.make(name: name, properties: properties, durationMs: duration)
    }

    @Test func propertiesAreWrittenAsLiterals() {
        let p: [String: XeeProperty] = ["screen": "goals", "step": 2, "ratio": 0.5, "skipped": false]
        #expect(p["screen"] == .string("goals"))
        #expect(p["step"] == .int(2))
        #expect(p["ratio"] == .double(0.5))
        #expect(p["skipped"] == .bool(false))
    }

    @Test func aBadNameDropsTheEvent() {
        #expect(make("OnboardingStarted") == nil)
        #expect(make("") == nil)
        #expect(make("1st_step") == nil)
        #expect(make("on-boarding") == nil)
        #expect(make(String(repeating: "a", count: 65)) == nil)
        #expect(make(String(repeating: "a", count: 64)) != nil)
    }

    @Test func badPropertiesAreDroppedOneByOne() {
        let p = make("onboarding_finished", [
            "Screen": "x",
            "ok": "y",
            "long": .string(String(repeating: "x", count: 256)),
            "fits": .string(String(repeating: "x", count: 255)),
        ])
        #expect(p?.properties.keys.sorted() == ["fits", "ok"])
    }

    @Test func aNumberThatIsNotFiniteIsDropped() {
        let p = make("onboarding_finished", [
            "nan": .double(.nan),
            "inf": .double(.infinity),
            "neg": .double(-.infinity),
            "ok": .double(1.5),
        ])
        #expect(p?.properties.keys.sorted() == ["ok"], "JSON cannot carry them, and one would fail a whole batch")
    }

    @Test func moreThanTwentyKeepsTheFirstTwentyByKey() {
        var props: [String: XeeProperty] = [:]
        for i in 0 ..< 25 { props[String(format: "k%02d", i)] = .int(i) }
        let p = make("onboarding_finished", props)
        #expect(p?.properties.count == 20)
        #expect(p?.properties["k19"] == .int(19))
        #expect(p?.properties["k20"] == nil)
    }

    @Test func aDurationReplacesTheCallersAndKeepsItsPlace() {
        var props: [String: XeeProperty] = ["duration_ms": 5]
        for i in 0 ..< 25 { props[String(format: "k%02d", i)] = .int(i) }
        let p = make("onboarding_finished", props, duration: 1500)
        #expect(p?.properties["duration_ms"] == .int(1500))
        #expect(p?.properties.count == 20, "19 of the caller's, plus duration_ms")
        #expect(make("onboarding_finished", ["duration_ms": 5])?.properties["duration_ms"] == .int(5), "kept without a timer")
    }

    @Test func aTimerGivesTheElapsedMillisecondsOnce() {
        let timers = XeeEventTimers()
        let t0 = Date(timeIntervalSince1970: 1000)
        timers.start("onboarding_finished", at: t0)
        #expect(timers.take("onboarding_finished", at: t0.addingTimeInterval(1.5)) == 1500)
        #expect(timers.take("onboarding_finished", at: t0.addingTimeInterval(2)) == nil, "cleared after one use")
        #expect(timers.take("never_started", at: t0) == nil)
        timers.start("restarted", at: t0)
        timers.start("restarted", at: t0.addingTimeInterval(1))
        #expect(timers.take("restarted", at: t0.addingTimeInterval(1.25)) == 250, "a second start replaces the first")
    }

    @Test func timingAnEmptyNameDoesNothing() {
        let timers = XeeEventTimers()
        timers.start("", at: Date(timeIntervalSince1970: 1000))
        #expect(timers.take("", at: Date(timeIntervalSince1970: 1001)) == nil)
    }

    @Test func theEventEncodesAsTheServerReadsIt() throws {
        let p = try #require(make("onboarding_step_viewed", ["screen": "goals", "step": 2]))
        #expect(Event.track(p).name == "xee_track")
        let data = try Event.encoder.encode(Event.track(p))
        let json = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        #expect(json["track_name"] as? String == "onboarding_step_viewed")
        let props = try #require(json["track_properties"] as? [String: Any])
        #expect(props["screen"] as? String == "goals")
        #expect(props["step"] as? Int == 2)
    }
}

#endif
