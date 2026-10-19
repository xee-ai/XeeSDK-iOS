import Foundation
import Xee

// The samples of the "Migrate from Adapty or another SDK" page. They show only Xee's side: the Adapty
// calls they replace are plain text on the page, because this package has no Adapty dependency.
// Lines ending in `docs:hide` wrap the statements so they compile; a page does not show them.

private func track(_ name: String, _ value: Bool) {} // The reader's own analytics call.

// snippet: migrate-activate
private func activateForMigration(user: AppUser) async throws { // docs:hide
let configuration = XeeConfiguration
    .builder(withAPIKey: "xee_YOUR_SDK_KEY")
    .with(serverUrl: URL(string: "https://xee.example.test")!)
    .with(customerUserId: user.id, withAppAccountToken: user.appAccountToken)
    .with(observerMode: true) // While Adapty still sells. Remove this line when Xee takes over purchases.
    .build()

try await Xee.activate(with: configuration)
} // docs:hide
// end snippet

// snippet: migrate-paywall
private func showPaywall() async throws { // docs:hide
// Adapty's placement ID is now the paywall ID you created in Xee.
let paywall = try await Xee.getPaywallVariant(paywallId: "onboarding")
let products = try await Xee.getPaywallVariantProducts(paywallVariant: paywall)

// The values you had in the remote config are the paywall's variables.
let headline = paywall.remoteConfig?.dictionary?["headline"] as? String ?? "Go premium"

// Once the paywall is on screen:
try? await Xee.logShowPaywallVariant(paywall)
} // docs:hide
// end snippet

private func productRow(_ product: XeePaywallVariantProduct) {
    // snippet: migrate-product-helpers
    let price = product.localizedPrice ?? ""          // "$9.99"
    let amount = product.price                        // Decimal, for your own formatting
    let unit = product.subscriptionPeriod?.unit       // .day, .week, .month or .year
    let count = product.subscriptionPeriod?.numberOfUnits
    let locale = product.priceLocale                  // the storefront's locale
    let storeKit2 = product.sk2Product                // StoreKit 2 Product, iOS 15 and later
    let storeKit1 = product.sk1Product                // StoreKit 1 SKProduct, iOS 14 and earlier

    // The intro offer, set only when this user is eligible for it.
    if let offer = product.subscriptionOffer,
       offer.offerType == .introductory,
       offer.paymentMode == .freeTrial {
        let trialLength = offer.localizedNumberOfPeriods ?? ""
        let trialPeriod = offer.localizedSubscriptionPeriod ?? ""
    }
    // end snippet
}

// snippet: migrate-buy
func buyWithXee(_ product: XeePaywallVariantProduct) async {
    do {
        let result = try await Xee.makePurchase(product: product)
        if result.isPurchaseCancelled || result.isPurchasePending {
            return // Nothing was bought.
        }
        if result.profile?.accessLevels["premium"]?.isActive ?? false {
            // Unlock the paid features.
        }
    } catch {
        // Show the error and let the user try again.
    }
}
// end snippet

// snippet: migrate-both-access
func xeePremium() async -> Bool {
    guard let profile = try? await Xee.getProfile() else { return false }
    return profile.accessLevels["premium"]?.isActive ?? false
}

// Premium if either service says so. `adaptyPremium` is what your Adapty code reads today.
func isPro(adaptyPremium: Bool) async -> Bool {
    await xeePremium() || adaptyPremium
}
// end snippet

// snippet: migrate-restore-subscribers
func bringSubscriberIntoXee(adaptyPremium: Bool) async {
    // Only when Adapty knows a subscriber that Xee does not yet.
    guard adaptyPremium, !(await xeePremium()) else { return }
    do {
        let profile = try await Xee.restorePurchases()
        // Record the outcome in your own analytics: these counts tell you when to stop using Adapty.
        track("xee_restore_found_premium", profile.accessLevels["premium"]?.isActive ?? false)
    } catch {
        // Offline, or the server could not be reached. Try again at the next launch.
    }
}
// end snippet

// snippet: migrate-trial-used
func usedTrialBefore(productIds: Set<String>) async -> Bool {
    guard let profile = try? await Xee.getProfile() else { return false }
    // `subscriptions` is keyed by product ID and keeps expired ones.
    return !productIds.isDisjoint(with: profile.subscriptions.keys)
}
// end snippet
