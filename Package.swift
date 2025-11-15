// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "swift-rfc-2046",
    platforms: [
        .macOS(.v14),
        .iOS(.v17),
        .tvOS(.v17),
        .watchOS(.v10)
    ],
    products: [
        .library(
            name: "RFC 2046",
            targets: ["RFC 2046"]
        )
    ],
    dependencies: [
        .package(path: "/Users/coen/Developer/swift-standards/swift-rfc-2045"),
        .package(path: "/Users/coen/Developer/swift-standards/swift-rfc-2183")
    ],
    targets: [
        .target(
            name: "RFC 2046",
            dependencies: [
                .product(name: "RFC 2045", package: "swift-rfc-2045"),
                .product(name: "RFC 2183", package: "swift-rfc-2183")
            ]
        ),
        .testTarget(
            name: "RFC 2046 Tests",
            dependencies: ["RFC 2046"]
        )
    ]
)

for target in package.targets {
    target.swiftSettings?.append(
        contentsOf: [
            .enableUpcomingFeature("MemberImportVisibility")
        ]
    )
}
