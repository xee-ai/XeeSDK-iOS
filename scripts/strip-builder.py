#!/usr/bin/env python3
"""Removes the paywall builder from the imported Adapty 3.17.3 core. Run once, after the import."""
import pathlib

ROOT = pathlib.Path(__file__).resolve().parent.parent
S = ROOT / "Sources"

DELETE = [
    "Placements/UIBuilder/AdaptyPaywall+UIBuilder.swift",
    "Placements/UIBuilder/AdaptyPaywall+UIConfiguration.swift",
    "Placements/Entities/AdaptyPaywall.ViewConfiguration.swift",
    "Backend/Fallback+Backend/Requests/FetchFallbackUISchemaRequest.swift",
    "Backend/Main+Backend/Requests/FetchUISchemaRequest.swift",
]


def edit(rel, pairs):
    path = S / rel
    text = path.read_text()
    for old, new in pairs:
        count = text.count(old)
        assert count == 1, f"{rel}: expected 1 occurrence, found {count}: {old[:70]!r}"
        text = text.replace(old, new)
    path.write_text(text)


for rel in DELETE:
    (S / rel).unlink()
ui_dir = S / "Placements/UIBuilder"
if ui_dir.exists() and not any(ui_dir.iterdir()):
    ui_dir.rmdir()

# The version constants are sent in request hashes and headers, so keep their values.
(S / "Versions.swift").write_text('''//
//  Versions.swift
//  AdaptySDK
//
//  Created by Aleksei Valiano on 11.08.2022.
//

import Foundation

extension Adapty {
    public nonisolated static let SDKVersion = "0.1.0"
    nonisolated static let fallbackFormatVersion = 9
    nonisolated static let userAcquisitionVersion = 1

    // The paywall builder is not part of this SDK. These values stay because they are part of the
    // request hashes and headers that the server matches.
    nonisolated static let uiSchemaVersion = "4.4.0"
    nonisolated static let uiBuilderVersion = "4_4"
}

extension AdaptyOnboarding.ViewConfiguration {
    nonisolated static let uiVersion = "2.0.0"
}
''')

edit("Placements/Adapty+Placements.swift", [
    ("import AdaptyUIBuilder\n", ""),
    ("            AdaptyUIBuilder.sendImageUrlsToObserver(paywall)\n\n", ""),
])
edit("Placements/Adapty+PlacementForDefaultAudience.swift", [
    ("import AdaptyUIBuilder\n", ""),
    ("            AdaptyUIBuilder.sendImageUrlsToObserver(paywall)\n", ""),
])

edit("Placements/Entities/AdaptyPaywall.swift", [
    ("""    /// If `true`, it is possible to fetch the view ``AdaptyUIConfiguration`` object and use it with ``AdaptyUI`` library.
    public var hasViewConfiguration: Bool { viewConfiguration != nil }

    let viewConfiguration: ViewConfiguration?

""", ""),
    (", hasViewConfiguration: \\(hasViewConfiguration)", ""),
    ('        case viewConfiguration = "paywall_builder"\n', ""),
    ("        viewConfiguration = try container.decodeIfPresent(ViewConfiguration.self, forKey: .viewConfiguration)\n", ""),
    ("        try container.encodeIfPresent(viewConfiguration, forKey: .viewConfiguration)\n", ""),
])

edit("Placements/Entities/PlacementContent.swift", [
    ("""    var viewConfigurationLocale: AdaptyLocale? {
        guard let paywall = self as? AdaptyPaywall else { return nil }
        return paywall.viewConfiguration?.locale
    }

""", ""),
    ("""        var viewConfigurationLocale = viewConfigurationLocale

        if viewConfigurationLocale?.equalLanguageCode(.defaultPlacementLocale) ?? false {
            viewConfigurationLocale = nil
        }

        return switch (remoteConfigLocale, viewConfigurationLocale) {
        case (nil, nil): nil
        case let (locale?, _),
             let (_, locale?): locale
        }
""", "        return remoteConfigLocale\n"),
])

edit("Placements/Storage/PlacementStorage.swift", [
    ("              cached.viewConfigurationLocale == content.viewConfigurationLocale,\n", ""),
])

edit("Events/Adapty+Events.swift", [
    ("                viewConfigurationId: paywall.viewConfiguration?.id,\n", "                viewConfigurationId: nil,\n"),
])
edit("Events/AdaptyUI+Events.swift", [
    ("""    nonisolated static func logShowPaywallViaAdaptyUI(_ paywall: AdaptyPaywall) async throws(AdaptyError) {
        try await trackEvent(
            .paywallShowed(.init(
                variationId: paywall.variationId,
                viewConfigurationId: paywall.viewConfiguration?.id
            ))
        )
    }

""", ""),
])
print("builder stripped")
