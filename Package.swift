// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "swift-rfc-2046",
    platforms: [
        .macOS(.v15),
        .iOS(.v18),
        .tvOS(.v18),
        .watchOS(.v11),
    ],
    products: [
        .library(
            name: "RFC 2046",
            targets: ["RFC 2046"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/swift-standards/swift-rfc-2045", from: "0.3.0"),
        .package(url: "https://github.com/swift-standards/swift-rfc-2183", from: "0.4.0"),
        .package(url: "https://github.com/swift-standards/swift-rfc-4648", from: "0.3.0"),
        .package(url: "https://github.com/swift-standards/swift-rfc-5322", from: "0.6.0"),
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
            name: "RFC 2046".tests,
            dependencies: ["RFC 2046"]
        ),
    ],
    swiftLanguageModes: [.v6]
)

extension String {
    var tests: Self { self + " Tests" }
    var foundation: Self { self + " Foundation" }
}

for target in package.targets where ![.system, .binary, .plugin].contains(target.type) {
    let existing = target.swiftSettings ?? []
    target.swiftSettings =
        existing + [
            .enableUpcomingFeature("ExistentialAny"),
            .enableUpcomingFeature("InternalImportsByDefault"),
            .enableUpcomingFeature("MemberImportVisibility"),
        ]
}
