import Foundation
import Xee

private func readTheDrawnPaywall() async throws {
    // snippet: ab-test-read-paywall
    let paywall = try await Xee.getPaywallVariant(paywallId: "main")
    // paywall.paywall.abTestName is the test's name, or "default" when none is running.
    // paywall.variationId is "main.v4.B" for arm B on version 4, "main.v4" with no test.
    let products = try await Xee.getPaywallVariantProducts(paywallVariant: paywall)
    try? await Xee.logShowPaywallVariant(paywall)
    // end snippet
}
