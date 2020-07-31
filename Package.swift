// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "OpenHealthCardKit",
    platforms: [
        // specify each minimum deployment requirement,
        //otherwise the platform default minimum is used.
       .macOS(.v10_15),
       .iOS(.v13),
       .tvOS(.v9),
       .watchOS(.v2)
    ],
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "CardReaderProviderApi",
            targets: ["CardReaderProviderApi"]),
        .library(
            name: "CardReaderAccess",
            targets: ["CardReaderAccess"]),
        .library(
            name: "HealthCardAccess",
            targets: ["HealthCardAccess"]),
        .library(
            name: "HealthCardControl",
            targets: ["HealthCardControl"]),
        .library(
            name: "NFCCardReaderProvider",
            targets: ["NFCCardReaderProvider"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url: "http://github.com/Quick/Nimble", from: "8.0.1"),
        .package(url: "http://github.com/SwiftCommon/DataKit", from: "1.0.2"),
        .package(url: "http://github.com/attaswift/BigInt", from: "5.0.0"),
        .package(name: "ASN1Kit", url: "https://build.top.local/source/git/refImpl/mobszen/iOS/ASN1Kit.git", .branch("R1.0.9")),
        .package(name: "GemCommonsKit", url: "https://build.top.local/source/git/refImpl/mobszen/iOS/ref-GemCommonsKit.git", .branch("R1.1.2"))
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "CardReaderProviderApi",
            dependencies: ["GemCommonsKit"]),
        .testTarget(
            name: "CardReaderProviderApiTests",
            dependencies: ["CardReaderProviderApi", "Nimble"]),
        .target(
            name: "CardReaderAccess",
            dependencies: ["CardReaderProviderApi"]),
        .testTarget(
            name: "CardReaderAccessTests",
            dependencies: ["CardReaderAccess", "Nimble"]),
        .target(
            name: "HealthCardAccess",
            dependencies: ["ASN1Kit", "CardReaderAccess", "CardReaderProviderApi", "DataKit"]),
        .testTarget(
            name: "HealthCardAccessTests",
            dependencies: ["HealthCardAccess", "Nimble"]),
        .target(
            name: "HealthCardControl",
            dependencies: ["HealthCardAccess", "BigInt"]),
        .testTarget(
            name: "HealthCardControlTests",
            dependencies: ["HealthCardControl", "Nimble"]),
        .target(
            name: "NFCCardReaderProvider",
            dependencies: ["HealthCardAccess"]),
        .testTarget(
            name: "NFCCardReaderProviderTests",
            dependencies: ["NFCCardReaderProvider", "Nimble"]),
    ],
    swiftLanguageVersions: [.v5]
)
