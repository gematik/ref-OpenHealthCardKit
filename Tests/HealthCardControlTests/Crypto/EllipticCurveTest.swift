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

final class EllipticCurveTest: XCTestCase {

    let ecBrainpoolP256r1 = EllipticCurve.brainpoolP256r1

    func testContainsBasePoint() {
        expect {
            self.ecBrainpoolP256r1.contains(point: self.ecBrainpoolP256r1.g)
        }.to(beTrue())
    }

    func testNegateBasePoint() {

        let basePointNegated = ecBrainpoolP256r1.negate(self.ecBrainpoolP256r1.g)
        // swiftlint:disable force_unwrapping
        let expected = ECPoint.finite((BigInt("8bd2aeb9cb7e57cb2c4b482ffc81b7afb9de27e1e3bd23c23a4453bd9ace3262",
                                              radix: 16)!,
                                              BigInt("557c5fa5de13e4bea66dc47689226fa8abc4b110a73891d3c3f5f355f069e9e0",
                                                     radix: 16)!))
        // swiftlint:enable force_unwrapping
        expect {
            basePointNegated
        } == expected

    }

    func testAddPoints() {
        let basePointAdded = ecBrainpoolP256r1.addPoints(ecPoint1: self.ecBrainpoolP256r1.g,
                                                         ecPoint2: self.ecBrainpoolP256r1.g)
        // swiftlint:disable force_unwrapping
        let expected = ECPoint.finite((BigInt("743cf1b8b5cd4f2eb55f8aa369593ac436ef044166699e37d51a14c2ce13ea0e",
                                              radix: 16)!,
                                              BigInt("36ed163337deba9c946fe0bb776529da38df059f69249406892ada097eeb7cd4",
                                                     radix: 16)!))
        // swiftlint:enable force_unwrapping
        expect {
            basePointAdded
        } == expected
    }

    func testScalarMultiplication() {
        expect {
            self.ecBrainpoolP256r1.scalarMult(k: self.ecBrainpoolP256r1.n, ecPoint: self.ecBrainpoolP256r1.g)
        } == ECPoint.infinite

        expect {
            self.ecBrainpoolP256r1.scalarMult(k: 1234, ecPoint: .infinite)
        } == ECPoint.infinite

        // swiftlint:disable force_unwrapping line_length
        let expectedTimesMinus3 = ECPoint.finite((BigInt("a8f217b77338f1d4d6624c3ab4f6cc16d2aa843d0c0fca016b91e2ad25cae39d", radix: 16)!, BigInt("5eb18cdf2442830133c3640b93684c7c737ae7de4bf19070a1ad7bc71cb703da", radix: 16)!))
        let expectedTimes24 = ECPoint.finite((BigInt("7f7d0f4947bd1b50d2e4495485544ee1c057c92c0ed5afa317ec71934fa8a072", radix: 16)!, BigInt("5482da7cde57d164b8b9c5a71c28f7f3fa7c7588c2e73e72a12f4573687c5814", radix: 16)!))
        let expectedTimes25 = ECPoint.finite((BigInt("4e71767e126fd5f72185ad28fb5fa0faca2fbfe7d1cf4e00f2cf3ad83fa052c9", radix: 16)!, BigInt("6827f6a39886c9f82c9eb4b82368af89b6d936b56f8ac707c7164f4db751f8f4", radix: 16)!))
        // swiftlint:enable force_unwrapping line_length

        expect {
            self.ecBrainpoolP256r1.scalarMult(k: -3, ecPoint: self.ecBrainpoolP256r1.g)
        } == expectedTimesMinus3

        expect {
            self.ecBrainpoolP256r1.scalarMult(k: 24, ecPoint: self.ecBrainpoolP256r1.g)
        } == expectedTimes24

        expect {
            self.ecBrainpoolP256r1.scalarMult(k: 25, ecPoint: self.ecBrainpoolP256r1.g)
        } == expectedTimes25
    }

    func testScalarMultiplicationHuge() {
        guard let huge1 = BigInt("f0137be5b13c32fe328198c3b66301d466207bac9b4ebb226abdffa447942c21", radix: 16),
              let huge2 = BigInt("d1ff6afe11bab7cc12e3508128493ee0346c94f22b02ab662acc4056eb10b5bf", radix: 16) else {
            Nimble.fail("Could not create BigInteger")
            return
        }
        // swiftlint:disable force_unwrapping  line_length
        let expectedHuge1 = ECPoint.finite((BigInt("1ed52def6f656cc167cdb95635d58525587eae84b36b860b6c1268a86b1ae1dd",
                                                   radix: 16)!, BigInt("24462b130d3ee58240e8beacf6f93edbf2869a7e9453033227b33cc4d22d5536", radix: 16)!))
        let expectedHuge2 = ECPoint.finite((BigInt("1ea9b0e86ff433b43a86e12f3bb63a47d0d84b8be9afd7190fa59e0397f2f1c7",
                                                   radix: 16)!, BigInt("a3d7605d41a512b017ebb055a57259cc5d425947c5db9970db5a88c836356d79", radix: 16)!))
        // swiftlint:enable force_unwrapping line_length

        expect {
            self.ecBrainpoolP256r1.scalarMult(k: huge1, ecPoint: self.ecBrainpoolP256r1.g)
        } == expectedHuge1

        expect {
            self.ecBrainpoolP256r1.scalarMult(k: huge2, ecPoint: self.ecBrainpoolP256r1.g)
        } == expectedHuge2
    }

    func testInverseModular() {
        expect {
            // (10 * 50) % 499 == 1
            EllipticCurve.inverseModular(k: 50, p: 499)
        }.to(equal(10))
    }

    static let allTests = [
        ("testContainsBasePoint", testContainsBasePoint),
        ("testNegateBasePoint", testNegateBasePoint),
        ("testAddPoints", testAddPoints),
        ("testScalarMultiplication", testScalarMultiplication),
        ("testScalarMultiplicationHuge", testScalarMultiplicationHuge),
        ("testInverseModular", testInverseModular)
    ]
}
