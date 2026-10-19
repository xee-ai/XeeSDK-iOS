import Foundation
import Xee

// snippet: make-purchase-async
import Xee

func buy(_ product: XeePaywallVariantProduct) async {
    do {
        let result = try await Xee.makePurchase(product: product)
        switch result {
        case .userCancelled:
            // The user closed the App Store sheet. Leave the paywall open.
            break
        case .pending:
            // Waiting on something outside the app, such as Ask to Buy.
            break
        case let .success(profile, _):
            if profile.accessLevels["premium"]?.isActive ?? false {
                // Unlock the paid features and close the paywall.
            } else if await waitForPremium() {
                // Access arrived a moment later. Unlock and close the paywall.
            } else {
                // Paid, but access is not on yet. Say it may take a moment.
            }
        }
    } catch {
        // Show the error and let the user try again.
    }
}

/// Polls the profile until `premium` is on. It waits for Apple's notification when Xee could not check the purchase itself.
func waitForPremium() async -> Bool {
    for _ in 0..<10 {
        if let profile = try? await Xee.getProfile(),
           profile.accessLevels["premium"]?.isActive ?? false {
            return true
        }
        try? await Task.sleep(nanoseconds: 2_000_000_000)
    }
    return false
}
// end snippet

// snippet: make-purchase-completion
import Xee

func buy(_ product: XeePaywallVariantProduct) {
    Xee.makePurchase(product: product) { result in
        switch result {
        case let .success(purchase):
            switch purchase {
            case .userCancelled, .pending:
                break
            case let .success(profile, _):
                if profile.accessLevels["premium"]?.isActive ?? false {
                    // Unlock the paid features and close the paywall.
                } else {
                    // Not on yet: refresh the profile until `premium` is on.
                    Task { _ = await waitForPremium() }
                }
            }
        case let .failure(error):
            // Show the error and let the user try again.
            print("Purchase failed: \(error)")
        }
    }
}
// end snippet

private func offers(product: XeePaywallVariantProduct) {
    // snippet: purchase-offers
    if let offer = product.subscriptionOffer, offer.offerType == .introductory {
        // For example "3 days free, then $9.99/week".
        let length = offer.localizedNumberOfPeriods ?? ""
        let price = product.localizedPrice ?? ""
    }
    // end snippet
}

private func restoreAsync() async {
    // snippet: restore-async
    do {
        let profile = try await Xee.restorePurchases()
        if profile.accessLevels["premium"]?.isActive ?? false {
            // Access is back. Close the paywall.
        } else {
            // Nothing to restore. Tell the user.
        }
    } catch {
        // Show the error.
    }
    // end snippet
}

private func restoreCompletion() {
    // snippet: restore-completion
    Xee.restorePurchases { result in
        switch result {
        case let .success(profile):
            if profile.accessLevels["premium"]?.isActive ?? false {
                // Access is back. Close the paywall.
            }
        case let .failure(error):
            print("Restore failed: \(error)")
        }
    }
    // end snippet
}

// snippet: promoted-purchase-delegate
import Xee

final class PurchaseDelegate: XeeDelegate {
    func didLoadLatestProfile(_ profile: XeeProfile) {}

    func shouldAddStorePayment(for product: XeeDeferredProduct) -> Bool {
        // Keep `product` somewhere, then return false to wait.
        false
    }
}

// Later, when the app is ready:
func resume(_ product: XeeDeferredProduct) async {
    do {
        _ = try await Xee.makePurchase(product: product)
    } catch {
        // Show the error.
    }
}
// end snippet
