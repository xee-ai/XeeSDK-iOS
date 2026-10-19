import Foundation
import Xee

private func verboseLogsWhileTesting() async throws {
    // snippet: sandbox-verbose-logs
    let configuration = XeeConfiguration.builder(withAPIKey: "xee_YOUR_SDK_KEY")
        .with(serverUrl: URL(string: "https://xee.example.test")!)
        .with(logLevel: .verbose)
        .build()
    try await Xee.activate(with: configuration)
    // end snippet
}
