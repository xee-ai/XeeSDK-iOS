import Foundation
import Xee

private func identifyAtActivation(user: AppUser) async throws {
    // snippet: identify-at-activation
    let configuration = XeeConfiguration
        .builder(withAPIKey: "xee_YOUR_SDK_KEY")
        .with(customerUserId: user.id, withAppAccountToken: user.appAccountToken)
        .build()

    try await Xee.activate(with: configuration)
    // end snippet
}

private func identifyAfterLoginAsync(user: AppUser) async {
    // snippet: identify-after-login-async
    do {
        try await Xee.identify(user.id, withAppAccountToken: user.appAccountToken)
    } catch {
        // error is a XeeError
    }
    // end snippet
}

private func identifyAfterLoginCompletion(user: AppUser) {
    // snippet: identify-after-login-completion
    Xee.identify(user.id, withAppAccountToken: user.appAccountToken) { error in
        if let error {
            // handle the XeeError
        }
    }
    // end snippet
}

private func logoutAsync() async {
    // snippet: logout-async
    do {
        try await Xee.logout()
    } catch {
        // error is a XeeError
    }
    // end snippet
}

private func logoutCompletion() {
    // snippet: logout-completion
    Xee.logout { error in
        if error == nil {
            // logged out
        }
    }
    // end snippet
}
