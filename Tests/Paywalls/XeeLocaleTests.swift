#if canImport(Testing)

@testable import Xee
import Testing

/// The same table as server/tests/locales.rs: the server and the fallback file pick the same language.
struct XeeLocaleTests {
    @Test func resolvesThePlanTable() {
        let cases: [(String, [String], String?)] = [
            ("fr_FR", ["fr"], "fr"), ("fr-CA", ["fr", "fr-CA"], "fr-CA"), ("pt-PT", ["pt-BR"], "pt-BR"),
            ("es-MX", ["es", "es-419"], "es-419"), ("es-MX", ["es", "es-419", "es-MX"], "es-MX"),
            ("es-ES", ["es", "es-419"], "es"), ("zh-Hant-TW", ["zh-Hans", "zh-Hant"], "zh-Hant"),
            ("zh-HK", ["zh-Hans", "zh-HK"], "zh-HK"), ("zh-TW", ["zh-Hans"], nil), ("de", ["fr"], nil),
            ("en", ["fr"], nil), ("fr-CA-u-ca-gregory", ["fr-CA"], "fr-CA"), ("garbage!!", ["fr"], nil),
        ]
        for (req, list, want) in cases {
            #expect(XeeLocale.resolve(XeeLocale(req), offered: list.map { XeeLocale($0) })?.id == want, "\(req) in \(list)")
        }
    }

    @Test func normalizes() {
        #expect(XeeLocale("ZH-hant-tw").normalized?.id == "zh-Hant-TW")
        #expect(XeeLocale("fr_FR").normalized?.id == "fr-FR")
        #expect(XeeLocale("garbage!!").normalized == nil)
    }
}

#endif
