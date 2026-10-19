import SwiftUI
import UIKit
import Xee

// snippet: paywall-values-swiftui
import Xee

struct PaywallValues: Decodable {
    var headline = "Unlock Unlimited Shorts"
    var cta = "Try for FREE"
    var showTrialToggle = true

    enum CodingKeys: String, CodingKey {
        case headline, cta
        case showTrialToggle = "show_trial_toggle"
    }

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = PaywallValues()
        headline = try c.decodeIfPresent(String.self, forKey: .headline) ?? d.headline
        cta = try c.decodeIfPresent(String.self, forKey: .cta) ?? d.cta
        showTrialToggle = try c.decodeIfPresent(Bool.self, forKey: .showTrialToggle) ?? d.showTrialToggle
    }
}

@MainActor
final class PaywallModel: ObservableObject {
    @Published var values = PaywallValues()
    @Published var products: [XeePaywallVariantProduct] = []

    func load() async {
        do {
            let paywall = try await Xee.getPaywallVariant(paywallId: "main")
            if let json = paywall.remoteConfig?.jsonString.data(using: .utf8) {
                values = (try? JSONDecoder().decode(PaywallValues.self, from: json)) ?? PaywallValues()
            }
            products = try await Xee.getPaywallVariantProducts(paywallVariant: paywall)
            try? await Xee.logShowPaywallVariant(paywall)
        } catch {
            // Keep the defaults; the paywall still works offline.
        }
    }
}
// end snippet

// snippet: paywall-values-uikit
import UIKit
import Xee

final class PaywallViewController: UIViewController {
    private var values = PaywallValues()

    override func viewDidLoad() {
        super.viewDidLoad()
        Task {
            guard let paywall = try? await Xee.getPaywallVariant(paywallId: "main") else { return }
            if let json = paywall.remoteConfig?.jsonString.data(using: .utf8) {
                values = (try? JSONDecoder().decode(PaywallValues.self, from: json)) ?? PaywallValues()
            }
            try? await Xee.logShowPaywallVariant(paywall)
            render()
        }
    }

    private func render() {
        // Set the labels and button from `values`.
    }
}
// end snippet
