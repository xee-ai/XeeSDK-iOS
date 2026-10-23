//
//  XeeView.swift
//  XeeSDK
//

import Foundation

private let log = Log.default

/// A view (a screen or a flow without products, such as onboarding) as the app reads it: its values
/// for this user. In Xee a view is a paywall without products, so it is served the same way.
public struct XeeView: Sendable {
    /// The view's ID, as passed to `Xee.getView`.
    public let id: String
    /// The variation this user got, such as `onboarding.v2.B`. `nil` when the view could not load and
    /// `config` is `.empty`; such a user is not counted in a test.
    public let variationId: String?
    /// The view's values. Read each one with the code's default: `config.string("title", default: "Hi")`.
    public let config: XeePaywallConfig
}

public extension Xee {
    /// The view's values for this user. It never throws: when the view cannot load in `loadTimeout`
    /// (no network at first launch, no version pushed yet, the SDK not activated), it returns a view
    /// whose getters all return the code's defaults, so the screens always show.
    ///
    /// - Parameters:
    ///   - id: The view's ID, such as `onboarding`.
    ///   - loadTimeout: Seconds to wait for the server, at least 1. Views default to 2 because they
    ///     often run at first launch.
    nonisolated static func getView(_ id: String, loadTimeout: TimeInterval = 2) async -> XeeView {
        await view(id) { try await getPaywallVariant(paywallId: id, loadTimeout: loadTimeout) }
    }

    /// Tells Xee the view is on screen. Call it once, when its first screen appears: view tests count
    /// a user from their first view. It never throws; a view that could not load logs nothing.
    nonisolated static func logShowView(_ view: XeeView) async {
        guard let variationId = view.variationId else { return }
        let now = Date()
        do {
            try await withActivatedSDK(methodName: .logShowView) { _ throws(XeeError) in
                try await trackEvent(
                    .paywallShowed(.init(variationId: variationId, viewConfigurationId: nil)),
                    date: now
                )
            }
        } catch {
            log.error("Xee.logShowView(\"\(view.id)\") failed: \(error)")
        }
    }
}

extension Xee {
    /// `getView` with the loading passed in, so the fallback is tested without the shared SDK.
    nonisolated static func view(_ id: String, load: () async throws -> XeePaywallVariant) async -> XeeView {
        do {
            let variant = try await load()
            return XeeView(id: id, variationId: variant.variationId, config: variant.config)
        } catch {
            log.warn("Xee.getView(\"\(id)\") could not load (\(error)); the view uses the code's defaults")
            return XeeView(id: id, variationId: nil, config: .empty)
        }
    }
}
