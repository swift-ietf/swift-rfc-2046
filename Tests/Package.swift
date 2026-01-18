// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "swift-rfc-2046-tests",
    platforms: [
        .macOS(.v26),
        .iOS(.v26),
        .tvOS(.v26),
        .watchOS(.v26),
        .visionOS(.v26),
    ],
    dependencies: [
        // Parent package
        .package(path: "../"),
        // Testing framework
        .package(path: "../../../swift-foundations/swift-testing"),
        // Test primitives (for test utilities)
        .package(path: "../../../swift-primitives/swift-test-primitives"),
    ],
    targets: [
        .testTarget(
            name: "RFC 2046 Tests",
            dependencies: [
                .product(name: "RFC 2046", package: "swift-rfc-2046"),
                .product(name: "Testing", package: "swift-testing"),
                .product(name: "Test Primitives", package: "swift-test-primitives"),
            ],
            path: "Sources/RFC 2046 Tests"
        )
    ],
    swiftLanguageModes: [.v6]
)

for target in package.targets where ![.system, .binary, .plugin, .macro].contains(target.type) {
    let settings: [SwiftSetting] = [
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility"),
    ]
    target.swiftSettings = (target.swiftSettings ?? []) + settings
}
