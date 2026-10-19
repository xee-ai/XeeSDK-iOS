import SwiftUI
import UIKit
import Xee

// snippet: log-view-swiftui
import SwiftUI
import Xee

struct PaywallScreen: View {
    let paywall: XeePaywallVariant
    let values: PaywallValues

    var body: some View {
        PaywallView(values: values)
            .task {
                try? await Xee.logShowPaywallVariant(paywall)
            }
    }
}
// end snippet

// snippet: log-view-uikit
import UIKit
import Xee

final class PaywallScreenViewController: UIViewController {
    private let paywall: XeePaywallVariant

    init(paywall: XeePaywallVariant) {
        self.paywall = paywall
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Task { try? await Xee.logShowPaywallVariant(paywall) }
    }
}
// end snippet

private func logViewCompletion(paywall: XeePaywallVariant) {
    // snippet: log-view-completion
    Xee.logShowPaywallVariant(paywall) { error in
        if let error {
            print("Could not log the view: \(error)")
        }
    }
    // end snippet
}
