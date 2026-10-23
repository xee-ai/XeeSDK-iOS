import SwiftUI
import Xee

// snippet: view-onboarding-swiftui
struct OnboardingFlow: View {
    @State private var onboarding: XeeView?

    var body: some View {
        Group {
            if let onboarding {
                WelcomeScreen(config: onboarding.config)
                    .task {
                        await Xee.logShowView(onboarding)
                        Xee.time("onboarding_finished")
                        Xee.track("onboarding_started")
                    }
            } else {
                ProgressView()
            }
        }
        .task { onboarding = await Xee.getView("onboarding") }
    }
}

struct WelcomeScreen: View {
    let config: XeePaywallConfig

    var body: some View {
        VStack(spacing: 16) {
            Text(config.string("welcome_title", default: String(localized: "Trade smarter")))
                .font(.largeTitle.bold())
            if config.bool("show_skip", default: true) {
                Button("Skip") { Xee.track("onboarding_skipped") }
            }
        }
    }
}
// end snippet

private func screens(of view: XeeView) -> [String] {
    // snippet: view-screen-order
    let order = view.config.stringList("screen_order", default: ["welcome", "goals", "notifications"])
    // end snippet
    return order
}
