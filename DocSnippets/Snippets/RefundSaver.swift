import Foundation
import Xee

private func consentAsync() async {
    // snippet: refund-consent-async
    do {
        // true: the customer agreed. false: the customer declined or withdrew consent.
        try await Xee.updateCollectingRefundDataConsent(true)
    } catch {
        // Retry later. Until it is saved, Xee treats the customer as not consenting.
    }
    // end snippet
}

private func consentCompletion() {
    // snippet: refund-consent-completion
    Xee.updateCollectingRefundDataConsent(true) { error in
        if let error {
            print("Could not save consent: \(error)")
        }
    }
    // end snippet
}

private func preferenceAsync() async {
    // snippet: refund-preference-async
    do {
        try await Xee.updateRefundPreference(.decline)
    } catch {
        // Retry later.
    }
    // end snippet
}

private func preferenceCompletion() {
    // snippet: refund-preference-completion
    Xee.updateRefundPreference(.decline) { error in
        if let error {
            print("Could not save preference: \(error)")
        }
    }
    // end snippet
}
