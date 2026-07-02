// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "background_runtime_macos",
    platforms: [
        .macOS("10.15")
    ],
    products: [
        .library(name: "background-runtime-macos", targets: ["background_runtime_macos"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "background_runtime_macos",
            dependencies: [],
            resources: [
                .process("PrivacyInfo.xcprivacy"),
            ]
        )
    ]
)
