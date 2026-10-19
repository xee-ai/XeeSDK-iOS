import SwiftUI
import UIKit
import Xee

// snippet: activate-swiftui
import SwiftUI
import Xee

@main
struct YourApp: App {
    init() {
        Task {
            do {
                try await Xee.activate(withAPIKey: "xee_YOUR_SDK_KEY")
            } catch {
                // error is a XeeError: log it and keep the app usable
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
// end snippet

// snippet: activate-uikit
import UIKit
import Xee

final class AppDelegate: UIResponder, UIApplicationDelegate {
    // Activate here, or in scene(_:willConnectTo:options:) if you use a SceneDelegate.
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        Task {
            do {
                try await Xee.activate(withAPIKey: "xee_YOUR_SDK_KEY")
            } catch {
                // error is a XeeError: log it and keep the app usable
            }
        }
        return true
    }
}
// end snippet

private func activateWithCompletion() {
    // snippet: activate-completion
    Xee.activate(withAPIKey: "xee_YOUR_SDK_KEY") { error in
        if let error {
            // error is a XeeError: log it and keep the app usable
        }
    }
    // end snippet
}

private func activateWithConfiguration() {
    // snippet: activate-with-configuration
    let configuration = XeeConfiguration
        .builder(withAPIKey: "xee_YOUR_SDK_KEY")
        .with(logLevel: .verbose) // for development; remove or lower for release
        .build()

    Task {
        do {
            try await Xee.activate(with: configuration)
        } catch {
            // error is a XeeError: log it and keep the app usable
        }
    }
    // end snippet
}

private func logLevelAtAnyTime() {
    // snippet: log-level
    Xee.logLevel = .verbose
    // end snippet
}

private func logHandler() {
    // snippet: log-handler
    Xee.setLogHandler { record in
        writeToLogFile("Xee \(record.level): \(record.message)")
    }
    // end snippet
}

private func dataCollection() {
    // snippet: data-collection
    let configuration = XeeConfiguration
        .builder(withAPIKey: "xee_YOUR_SDK_KEY")
        .with(idfaCollectionDisabled: true)
        .with(ipAddressCollectionDisabled: true)
        .build()
    // end snippet
}
