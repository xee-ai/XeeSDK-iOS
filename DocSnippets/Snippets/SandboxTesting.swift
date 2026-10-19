import Foundation
import Xee

private func verboseLogsWhileTesting() async throws {
    // snippet: sandbox-verbose-logs
    Xee.logLevel = .verbose
    try await Xee.activate(withAPIKey: "xee_YOUR_SDK_KEY")
    // end snippet
}
