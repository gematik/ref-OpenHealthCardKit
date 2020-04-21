//
//  Copyright (c) 2020 gematik GmbH
//  
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//  
//     http://www.apache.org/licenses/LICENSE-2.0
//  
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import DataKit
import HealthCardAccess
@testable import HealthCardControl
import Nimble
import XCTest

final class EcdhKeyPairGeneratorTest: XCTestCase {

    let nonceZ = try! Data(hex: "7C128010660CE51081F866C170B76F3A9404D5B8") //swiftlint:disable:this force_try
    let cardAccessNumber = try! CAN.from(Data("12345678".utf8)) //swiftlint:disable:this force_try
    let brainpoolP256r1 = EllipticCurve.brainpoolP256r1

    func testEcdhKeyPairGenerator_init() {

        let ecdhEphemeralKey = EcdhKeyPairGenerator()

        expect {
            ecdhEphemeralKey.generateKeyPair()
        }.toNot(beNil())
    }

    func testEcdhKeyPairGenerator_seeded() {

        let ecdhEphemeralKeyPair = EcdhKeyPairGenerator(ellipticCurve: brainpoolP256r1,
                                                                 seed: 1).generateKeyPair()

        // If (seed == privateKey == 1) then (curve.g * privateKey == publicKey == 1)
        expect {
            ecdhEphemeralKeyPair.publicKey
        } == brainpoolP256r1.g

        let ecdhEphemeralKeyPairCopy = EcdhKeyPairGenerator(ellipticCurve: brainpoolP256r1,
                                                                     seed: 1).generateKeyPair()
        expect {
            ecdhEphemeralKeyPair
        } == ecdhEphemeralKeyPairCopy
    }

    func testEcdhKeyPairGenerator_random() {
        let ecdhEphemeralKeyPair1 = EcdhKeyPairGenerator(ellipticCurve: brainpoolP256r1).generateKeyPair()
        let ecdhEphemeralKeyPair2 = EcdhKeyPairGenerator(ellipticCurve: brainpoolP256r1).generateKeyPair()

        // Note: Equality is highly unlikely, but not impossible.
        expect {
            ecdhEphemeralKeyPair1
        } != ecdhEphemeralKeyPair2
    }

    static let allTests = [
        ("testEcdhKeyPairGenerator_init", testEcdhKeyPairGenerator_init),
        ("testEcdhKeyPairGenerator_seeded", testEcdhKeyPairGenerator_seeded),
        ("testEcdhKeyPairGenerator_random", testEcdhKeyPairGenerator_random)
    ]
}
