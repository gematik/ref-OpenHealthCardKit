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

import BigInt
import DataKit
@testable import HealthCardControl
import Nimble
import XCTest

final class ECPointTest: XCTestCase {

    let ecBrainpoolP256r1 = EllipticCurve.brainpoolP256r1

    func testECPointEncodingUncompressedBasePoint() {
        // swiftlint:disable:next force_try
        let expectedG = try! Data(hex: "048bd2aeb9cb7e57cb2c4b482ffc81b7afb9de27e1e3bd23c23a4" +
                                       "453bd9ace3262547ef835c3dac4fd97f8461a14611dc9c2774513" +
                                       "2ded8e545c1d54c72f046997")

        expect {
            self.ecBrainpoolP256r1.g.encodedUncompressed32Bytes
        } == expectedG

    }

    func testECPointEncodingUncompressedOthers() {
        // randomly generated multipliers
        guard let multiplier1 = BigInt("b0decc1c794d99eb6f8f0120ca331e5749d742068c4b268f4fea98b901b320ec", radix: 16),
              let multiplier2 = BigInt("a6ed9849f2d5bcd5b20411e77c78a684212486d9e976379d8eaef5a1a303bf3a", radix: 16),
              let multiplier3 = BigInt("771b23598414c9035554020b1f6184d7900120136ca84dda28ab3b7d9a81ba3a", radix: 16)
                else {
            Nimble.fail("Could not create BigInteger")
            return
        }

        // swiftlint:disable force_try
        let expected1 = try! Data(hex: "043554f1067b69c7be780316346c3d6cc4bae39461f3d3568e6dbd496f4684eac" +
                                       "a5a1401a291df5af7ac1a2b4c1fcdab34883b86284cb7d0b25537b8e197b768b5")
        let expected2 = try! Data(hex: "0491cf5fb1ea61f90281263583d761674cc1a99b3dae3d3d36d1b3a803b377b5e" +
                                       "da455f7d99d87591cc650a83be18ba881fe549777bfb9e129b78b0894ec08832b")
        let expected3 = try! Data(hex: "0497aad24f7a234f90b4fe5767aedd36bf1dbe4d852e058aa34cbbb897f7311b8" +
                                       "892991adecc8c2b7d26066ef1733b8a936bdbdaf57177c30e98ab265ee8bfa6b0")
        // swiftlint:enable force_try

        expect {
            self.ecBrainpoolP256r1
                    .scalarMult(k: multiplier1, ecPoint: self.ecBrainpoolP256r1.g)
                    .encodedUncompressed32Bytes
        } == expected1
        expect {
            self.ecBrainpoolP256r1
                    .scalarMult(k: multiplier2, ecPoint: self.ecBrainpoolP256r1.g)
                    .encodedUncompressed32Bytes
        } == expected2
        expect {
            self.ecBrainpoolP256r1
                    .scalarMult(k: multiplier3, ecPoint: self.ecBrainpoolP256r1.g)
                    .encodedUncompressed32Bytes
        } == expected3

    }

    func testParseFromEncoded() {
        // swiftlint:disable force_try force_unwrapping
        let encoded1 = try! Data(hex: "042AAFEB6F92346132330D8EE421406CBFE14F86C3351FCAC0056F1B29E4BD489" +
                                      "214DC6769542FF340DD3EFD65526B99A03A08A58982815DDC11EF6B3A86586671")
        let encoded2 = try! Data(hex: "0425c5f065d44380b77b7bb4257e248f6d4d6afc16e92d4879ca83acb51d1e8d1" +
                                      "174233d0b00719a0c6ffdfad4c6ff12a49729f553bdb7b4fa29db87e7a7e9b79e")
        let expected1 = ECPoint.finite(
                (
                        BigInt("2AAFEB6F92346132330D8EE421406CBFE14F86C3351FCAC0056F1B29E4BD4892", radix: 16)!,
                        BigInt("14DC6769542FF340DD3EFD65526B99A03A08A58982815DDC11EF6B3A86586671", radix: 16)!
                )
        )
        let expected2 = ECPoint.finite(
                (
                        BigInt("25c5f065d44380b77b7bb4257e248f6d4d6afc16e92d4879ca83acb51d1e8d11", radix: 16)!,
                        BigInt("74233d0b00719a0c6ffdfad4c6ff12a49729f553bdb7b4fa29db87e7a7e9b79e", radix: 16)!
                )
        )
        // swiftlint:enable force_try, force_unwrapping

        expect {
            try ECPoint.parse(encoded: encoded1)
        } == expected1

        expect {
            try ECPoint.parse(encoded: encoded2)
        } == expected2
    }

    static let allTests = [
        ("testECPointEncodingUncompressedBasePoint", testECPointEncodingUncompressedBasePoint),
        ("testECPointEncodingUncompressedOthers", testECPointEncodingUncompressedOthers)
    ]
}
