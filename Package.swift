// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Xee",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
        .visionOS(.v1),
    ],
    products: [
        .library(name: "XeeLogger", targets: ["XeeLogger"]),
        .library(name: "Xee", targets: ["Xee"]),
    ],
    targets: [
        .target(
            name: "XeeLogger",
            dependencies: [],
            path: "Sources.Logger"
        ),
        .target(
            name: "Xee",
            dependencies: ["XeeLogger"],
            path: "Sources",
            resources: [.copy("PrivacyInfo.xcprivacy")]
        ),
        .testTarget(
            name: "XeeTests",
            dependencies: ["Xee", "XeeLogger"],
            path: "Tests",
            resources: [
                .process("Paywalls/fallback.json"),
                .process("Paywalls/fallback_large.json"),
            ]
        ),
    ]
)
