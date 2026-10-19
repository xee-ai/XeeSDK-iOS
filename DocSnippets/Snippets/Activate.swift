import SwiftUI
import Xee

private func activateQuick() async {
    // snippet: activate-quick
    do {
        try await Xee.activate(withAPIKey: "xee_YOUR_SDK_KEY")
    } catch {
        // error is a XeeError: log it and keep the app usable
    }
    // end snippet
}
