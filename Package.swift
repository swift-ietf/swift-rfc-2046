// swift-tools-version: 6.4

import PackageDescription

let package = Package(
    name: "swift-rfc-2046",
    platforms: [
        .macOS(.v27),
        .iOS(.v27),
        .tvOS(.v27),
        .watchOS(.v27),
        .visionOS(.v27),
    ],
    products: [
        .library(
            name: "RFC 2046",
            targets: ["RFC 2046"]
        ),
        .library(
            name: "RFC 2046 Foundation Integration",
            targets: ["RFC 2046 Foundation Integration"]
        ),
    ],
    traits: [
        .trait(name: "Coder", description: "Byte-level parsing and serialization of multipart bodies")
    ],
    dependencies: [
        .package(
            url: "https://github.com/swift-atoms/swift-ascii.git",
            branch: "main",
            traits: [
                .trait(name: "Parser", condition: .when(traits: ["Coder"])),
                .trait(name: "Serializer", condition: .when(traits: ["Coder"])),
            ]
        ),
        .package(url: "https://github.com/swift-atoms/swift-byte.git", branch: "main"),
        .package(url: "https://github.com/swift-atoms/swift-coder.git", branch: "main"),
        .package(url: "https://github.com/swift-atoms/swift-cursor.git", branch: "main"),
        .package(
            url: "https://github.com/swift-atoms/swift-parser.git",
            branch: "main",
            traits: [
                .trait(name: "Append", condition: .when(traits: ["Coder"])),
                .trait(name: "IteratorLeaves", condition: .when(traits: ["Coder"])),
                .trait(name: "Map", condition: .when(traits: ["Coder"])),
                .trait(name: "Product", condition: .when(traits: ["Coder"])),
                .trait(name: "Skip", condition: .when(traits: ["Coder"])),
                .trait(name: "Either", condition: .when(traits: ["Coder"])),
                .trait(name: "Iterator", condition: .when(traits: ["Coder"])),
            ]
        ),
        .package(url: "https://github.com/swift-atoms/swift-serializer.git", branch: "main"),
        .package(
            url: "https://github.com/swift-atoms/swift-binary.git",
            branch: "main",
            traits: [.trait(name: "Serializer", condition: .when(traits: ["Coder"]))]
        ),
        .package(
            url: "https://github.com/swift-incits/swift-incits-4-1986.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-ietf/swift-rfc-2045.git",
            branch: "main",
            traits: [.trait(name: "Coder", condition: .when(traits: ["Coder"]))]
        ),
        .package(
            url: "https://github.com/swift-ietf/swift-rfc-2183.git",
            branch: "main",
            traits: [.trait(name: "Coder", condition: .when(traits: ["Coder"]))]
        ),
        .package(url: "https://github.com/swift-ietf/swift-rfc-4648.git", branch: "main"),
        .package(url: "https://github.com/swift-ietf/swift-rfc-5322.git", branch: "main"),
    ],
    targets: [
        .target(
            name: "RFC 2046",
            dependencies: [
                .product(name: "Byte", package: "swift-byte"),
                .product(name: "INCITS 4 1986", package: "swift-incits-4-1986"),
                .product(name: "RFC 2045", package: "swift-rfc-2045"),
                .product(name: "RFC 2183", package: "swift-rfc-2183"),
                .product(name: "RFC 5322", package: "swift-rfc-5322"),
                .product(name: "ASCII", package: "swift-ascii"),
                .product(name: "Coder", package: "swift-coder", condition: .when(traits: ["Coder"])),
                .product(name: "Cursor", package: "swift-cursor", condition: .when(traits: ["Coder"])),
                .product(name: "Parser", package: "swift-parser", condition: .when(traits: ["Coder"])),
                .product(name: "Serializer", package: "swift-serializer", condition: .when(traits: ["Coder"])),
                .product(name: "Binary", package: "swift-binary", condition: .when(traits: ["Coder"])),
                .product(name: "RFC 4648", package: "swift-rfc-4648", condition: .when(traits: ["Coder"])),
            ]
        ),
        .target(
            name: "RFC 2046 Foundation Integration",
            dependencies: [
                .target(name: "RFC 2046"),
                .product(name: "Byte", package: "swift-byte"),
                .product(name: "RFC 2045", package: "swift-rfc-2045"),
                .product(
                    name: "RFC 2045 Foundation Integration",
                    package: "swift-rfc-2045"
                ),
                .product(name: "RFC 2183", package: "swift-rfc-2183"),
                .product(
                    name: "RFC 2183 Foundation Integration",
                    package: "swift-rfc-2183"
                ),
                .product(name: "RFC 5322", package: "swift-rfc-5322"),
                .product(
                    name: "RFC 5322 Foundation Integration",
                    package: "swift-rfc-5322"
                ),
            ]
        ),
        .testTarget(
            name: "RFC 2046 Tests",
            dependencies: [
                .target(name: "RFC 2046"),
                .product(name: "Byte", package: "swift-byte"),
                .product(name: "INCITS 4 1986", package: "swift-incits-4-1986"),
                .product(name: "RFC 2045", package: "swift-rfc-2045"),
                .product(name: "RFC 2183", package: "swift-rfc-2183"),
                .product(name: "RFC 5322", package: "swift-rfc-5322"),
                .product(name: "ASCII", package: "swift-ascii"),
                .product(name: "Coder", package: "swift-coder", condition: .when(traits: ["Coder"])),
                .product(name: "Cursor", package: "swift-cursor", condition: .when(traits: ["Coder"])),
                .product(name: "Binary", package: "swift-binary", condition: .when(traits: ["Coder"])),
            ]
        ),
        .testTarget(
            name: "RFC 2046 Foundation Integration Tests",
            dependencies: [
                .target(name: "RFC 2046"),
                .target(name: "RFC 2046 Foundation Integration"),
                .product(name: "Byte", package: "swift-byte"),
                .product(name: "RFC 2045", package: "swift-rfc-2045"),
                .product(name: "RFC 2183", package: "swift-rfc-2183"),
                .product(name: "RFC 5322", package: "swift-rfc-5322"),
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)

for target in package.targets where ![.system, .binary, .plugin, .macro].contains(target.type) {
    target.swiftSettings =
        (target.swiftSettings ?? []) + [
            .strictMemorySafety(),
            .enableUpcomingFeature("ExistentialAny"),
            .enableUpcomingFeature("InternalImportsByDefault"),
            .enableUpcomingFeature("MemberImportVisibility"),
            .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
            .enableUpcomingFeature("InferIsolatedConformances"),
            .enableExperimentalFeature("Lifetimes"),
            .treatAllWarnings(as: .error),
        ]
}
