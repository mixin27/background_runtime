// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "background_runtime_ios",
    platforms: [
        .iOS("13.0")
    ],
    products: [
        .library(name: "background-runtime-ios", targets: ["background_runtime_ios"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "background_runtime_ios",
            dependencies: [],
            resources: [
                // .process("PrivacyInfo.xcprivacy"),
            ]
        )
    ]
)
