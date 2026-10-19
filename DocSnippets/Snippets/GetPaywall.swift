import Foundation
import Xee

// The sample opens with `import Xee`, which cannot sit inside a function: the statements below are
// wrapped by hidden lines and left flush with the import so a page shows them as written.

// snippet: get-paywall-async
import Xee

private func getPaywallAsync() async { // docs:hide
do {
    let paywall = try await Xee.getPaywallVariant(paywallId: "main")
    // Read the values and products from `paywall`.
} catch {
    // Show the paywall with the defaults in your code.
}
} // docs:hide
// end snippet

// snippet: get-paywall-completion
import Xee

private func getPaywallCompletion() { // docs:hide
Xee.getPaywallVariant(paywallId: "main") { result in
    switch result {
    case let .success(paywall):
        // Read the values and products from `paywall`.
        _ = paywall
    case .failure:
        // Show the paywall with the defaults in your code.
        break
    }
}
} // docs:hide
// end snippet

private func fetchPolicy() async throws {
    // snippet: get-paywall-fetch-policy
    let paywall = try await Xee.getPaywallVariant(
        paywallId: "main",
        fetchPolicy: .returnCacheDataIfNotExpiredElseLoad(maxAge: 3600),
        loadTimeout: 3
    )
    // end snippet
}

private func readValuesFromDictionary(paywall: XeePaywallVariant) {
    // snippet: read-values-dictionary
    let headline = paywall.remoteConfig?.dictionary?["headline"] as? String ?? "Unlock Unlimited Shorts"
    let showTrialToggle = paywall.remoteConfig?.dictionary?["show_trial_toggle"] as? Bool ?? true
    // end snippet
}

private func decodeValues(paywall: XeePaywallVariant) {
    var values = PaywallValues() // docs:hide
    // snippet: read-values-decode
    if let json = paywall.remoteConfig?.jsonString.data(using: .utf8) {
        values = (try? JSONDecoder().decode(PaywallValues.self, from: json)) ?? PaywallValues()
    }
    // end snippet
}

private func getProductsAsync(paywall: XeePaywallVariant) async {
    // snippet: get-products-async
    do {
        let products = try await Xee.getPaywallVariantProducts(paywallVariant: paywall)
        // Show one row or button per product.
    } catch {
        // StoreKit could not load the products.
    }
    // end snippet
}

private func getProductsCompletion(paywall: XeePaywallVariant) {
    // snippet: get-products-completion
    Xee.getPaywallVariantProducts(paywallVariant: paywall) { result in
        switch result {
        case let .success(products):
            // Show one row or button per product.
            _ = products
        case .failure:
            // StoreKit could not load the products.
            break
        }
    }
    // end snippet
}
