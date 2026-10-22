import SwiftUI
import UIKit
import Xee

private func getProfileAsync() async {
    // snippet: get-profile-async
    do {
        let profile = try await Xee.getProfile()
        if profile.accessLevels["premium"]?.isActive ?? false {
            // unlock paid features
        }
    } catch {
        // error is a XeeError
    }
    // end snippet
}

private func getProfileMaxAge() async throws {
    // snippet: get-profile-max-age
    // Always ask the server, for example right before selling.
    let profile = try await Xee.getProfile(maxAge: 0)
    let premium = profile.accessLevels["premium"]?.isActive ?? false
    // end snippet
    _ = premium
}

private func getProfileCompletion() {
    // snippet: get-profile-completion
    Xee.getProfile { result in
        if let profile = try? result.get(),
           profile.accessLevels["premium"]?.isActive ?? false {
            // unlock paid features
        }
    }
    // end snippet
}

// snippet: profile-delegate
import Xee

final class SubscriptionManager: XeeDelegate {
    func didLoadLatestProfile(_ profile: XeeProfile) {
        let hasAccess = profile.accessLevels["premium"]?.isActive ?? false
        // store hasAccess and update your UI
    }
}

func setProfileDelegate() { // docs:hide
let subscriptionManager = SubscriptionManager() // docs:hide
// After Xee.activate has finished:
Xee.delegate = subscriptionManager
} // docs:hide
// end snippet

private struct PremiumGateView: View {
    @State private var showPaywall = false // docs:hide
    // The lines of the sample are not indented as the compiler would like: a page shows them flush left. // docs:hide
    // snippet: has-premium-swiftui
    func hasPremium() async -> Bool {
        do {
            let profile = try await Xee.getProfile()
            return profile.accessLevels["premium"]?.isActive ?? false
        } catch {
            return false
        }
    }

    // In your view:
    var body: some View { // docs:hide
    Text("Paid content") // docs:hide
    .task {
        if !(await hasPremium()) {
            showPaywall = true
        }
    }
    } // docs:hide
    // end snippet
}

private final class PremiumGateViewController: UIViewController {
    private func presentPaywall() {} // docs:hide
    // snippet: has-premium-uikit
    func hasPremium() async throws -> Bool {
        let profile = try await Xee.getProfile()
        return profile.accessLevels["premium"]?.isActive ?? false
    }

    // In your view controller:
    override func viewDidLoad() { // docs:hide
    Task {
        if !(try await hasPremium()) {
            presentPaywall()
        }
    }
    } // docs:hide
    // end snippet
}
