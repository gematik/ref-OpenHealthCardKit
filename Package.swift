// swift-tools-version: 5.8
//
// Copyright (Change Date see Readme), gematik GmbH
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
// *******
//
// For additional notes and disclaimer from gematik and in case of changes by gematik find details in the "Readme" file.
//

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
