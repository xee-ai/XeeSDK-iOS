import Foundation
import Xee

private func logsBeforeActivation() async throws {
    // snippet: troubleshooting-verbose-logs
    Xee.logLevel = .verbose
    try await Xee.activate(withAPIKey: "xee_YOUR_SDK_KEY")
    // end snippet
}

private func keepLogsYourself() {
    // snippet: troubleshooting-log-handler
    Xee.setLogHandler { record in
        MyLogFile.append("\(record.date) [\(record.level)] \(record.message)")
    }
    // end snippet
}

private func handleErrors() async {
    // snippet: handle-errors
    do {
        let paywall = try await Xee.getPaywallVariant(paywallId: "main")
        let products = try await Xee.getPaywallVariantProducts(paywallVariant: paywall)
        // Show the paywall.
    } catch let error as XeeError {
        switch error.xeeErrorCode {
        case .networkFailed:
            // Offline or the server is unreachable. Offer a retry.
            break
        case .badRequest:
            // The paywall ID is wrong, or the paywall is not live.
            break
        default:
            print("Xee: \(error), caused by: \(String(describing: error.originalError))")
        }
    } catch {
        print("Unexpected: \(error)")
    }
    // end snippet
}
