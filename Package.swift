// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "swift-rfc-2046",
    platforms: [
        .macOS(.v15),
        .iOS(.v18),
        .tvOS(.v18),
        .watchOS(.v11)
    ],
    products: [
        .library(
            name: "RFC 2046",
            targets: ["RFC 2046"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/swift-standards/swift-rfc-2045", from: "0.1.0"),
        .package(url: "https://github.com/swift-standards/swift-rfc-2183", from: "0.1.0"),
        .package(url: "https://github.com/swift-standards/swift-rfc-4648", from: "0.1.0"),
        .package(url: "https://github.com/swift-standards/swift-rfc-5322", from: "0.1.0"),
    ],
    targets: [
        .target(
            name: "RFC 2046",
            dependencies: [
                .product(name: "RFC 2045", package: "swift-rfc-2045"),
                .product(name: "RFC 2183", package: "swift-rfc-2183"),
                .product(name: "RFC 4648", package: "swift-rfc-4648"),
                .product(name: "RFC 5322", package: "swift-rfc-5322"),
            ]
        ),
        .testTarget(
            name: "RFC 2046 Tests",
            dependencies: ["RFC 2046"]
        )
    ]
)

for target in package.targets {
    var settings = target.swiftSettings ?? []
    settings.append(
        .enableUpcomingFeature("MemberImportVisibility")
    )
    target.swiftSettings = settings
}
