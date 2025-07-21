// swift-tools-version: 5.8

import PackageDescription

let package = Package(
    name: "Openhealthcardkit",
    platforms: [
        .iOS(.v14),
        .macOS(.v12)
    ],
    products: [
        .library(name: "HealthCardControl", targets: ["HealthCardControl"]),
        .library(name: "NFCCardReaderProvider", targets: ["NFCCardReaderProvider"]),
        .library(name: "HealthCardAccess", targets: ["HealthCardAccess"]),
        .library(name: "CardReaderProviderApi", targets: ["CardReaderProviderApi"]),
        .library(name: "Helper", targets: ["Helper"]),    
        // TODO: Remove this (and the .target) at a later time. For now it's only needed for the CardSimulationTests
        .library(name: "CardReaderAccess", targets: ["CardReaderAccess"]),
    ],
    dependencies: [
        .package(url: "https://github.com/gematik/ASN1Kit.git", from: "1.2.0"),
        .package(url: "https://github.com/gematik/OpenSSL-Swift", from: "4.2.0"),
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.3.0"),
        .package(url: "https://github.com/Quick/Nimble", from: "12.0.0"),
    ],
    targets: [
        .target(
            name: "NFCCardReaderProvider",
            dependencies: [
                "HealthCardControl",
                "HealthCardAccess",
                "Helper",
            ]
        ),
        .target(
            name: "HealthCardControl",
            dependencies: [
                "HealthCardAccess",
                "Helper",
                "OpenSSL-Swift"
            ]
        ),
        .target(
            name: "HealthCardAccess",
            dependencies: ["CardReaderProviderApi", "ASN1Kit"]
        ),
        .target(
            name: "CardReaderAccess",
            dependencies: ["CardReaderProviderApi", "Helper"]
        ),    
        .target(
            name: "CardReaderProviderApi",
            dependencies: ["Helper",]
        ),   
        .target(
            name: "Helper"
        ),
        .testTarget(
            name: "HealthCardControlTests",
            dependencies: ["HealthCardControl", "Nimble"],
            resources: [
                .process("Resources.bundle")
            ]
        ),
        .testTarget(
            name: "HealthCardAccessTests",
            dependencies: ["HealthCardAccess", "Nimble"],
            resources: [
                .process("Resources.bundle")
            ]
        ),
        .testTarget(
            name: "CardReaderAccessTests",
            dependencies: ["CardReaderAccess", "Nimble"]
        ),
        .testTarget(
            name: "CardReaderProviderApiTests",
            dependencies: ["CardReaderProviderApi", "Nimble"]
        ),
    ]
)
