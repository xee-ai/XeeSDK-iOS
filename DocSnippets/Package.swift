// swift-tools-version: 6.0
import PackageDescription

// The code samples the docs show, compiled against this SDK so a changed API breaks the build instead
// of the docs. A separate package so the SDK's own package stays exactly what apps install.
// Build it for iOS from this folder:
//   xcodebuild -scheme XeeDocSnippets -destination 'generic/platform=iOS' build
let package = Package(
    name: "XeeDocSnippets",
    platforms: [.iOS(.v15)],
    products: [.library(name: "XeeDocSnippets", targets: ["XeeDocSnippets"])],
    dependencies: [.package(name: "Xee", path: "..")],
    targets: [
        .target(
            name: "XeeDocSnippets",
            dependencies: [.product(name: "Xee", package: "Xee"), .product(name: "XeeLogger", package: "Xee")],
            path: "Snippets"
        ),
    ]
)
