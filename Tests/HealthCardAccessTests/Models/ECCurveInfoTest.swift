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

import ASN1Kit
import Foundation
@testable import HealthCardAccess
import Nimble
import XCTest

final class ECCurveInfoTest: XCTestCase {
    typealias ECCurveNormalizeTest = (test: String, curve: ECCurveInfo, signature: String, normalized: String)
    let normalizingCases: [ECCurveNormalizeTest] = [
        (test: "ansix9p256r1", curve: ansix9p256r1, signature: "ansix9p256r1_signature",
         normalized: "ansix9p256r1_signature_normalized"),
        (test: "ansix9p384r1", curve: ansix9p384r1, signature: "ansix9p384r1_signature",
         normalized: "ansix9p384r1_signature_normalized"),
        (test: "brainpoolP256r1", curve: brainpoolP256r1, signature: "brainpoolP256r1_signature",
         normalized: "brainpoolP256r1_signature_normalized"),
        (test: "brainpoolP384r1", curve: brainpoolP384r1, signature: "brainpoolP384r1_signature",
         normalized: "brainpoolP384r1_signature_normalized"),
        (test: "brainpoolP512r1", curve: brainpoolP512r1, signature: "brainpoolP512r1_signature",
         normalized: "brainpoolP512r1_signature_normalized"),
    ]

    let normalizingCasesExpectFailure: [ECCurveNormalizeTest] = [
        (test: "signature sequence too long",
         curve: ansix9p256r1,
         signature: "ansix9p256r1_signature_invalid_toolongsequence",
         normalized: "ansix9p256r1_signature_normalized"),
    ]

    func testNormalizingSignature() throws {
        normalizingCases.forEach { (testCase: ECCurveNormalizeTest) in
            let testName = testCase.test
            let signature = ResourceLoader.loadResourceAsData(
                resource: testCase.signature,
                withExtension: "dat",
                directory: "DSA"
            )
            let signatureNormalized = ResourceLoader.loadResourceAsData(
                resource: testCase.normalized,
                withExtension: "dat",
                directory: "DSA"
            )
            let errors = Nimble.gatherFailingExpectations(silently: true) {
                expect { try testCase.curve.normalize(signature: signature) } == signatureNormalized
            }
            if !errors.isEmpty {
                Nimble.fail("Test (DSA-Normalize): [\(testName)] failed!")
                errors.forEach { assertion in
                    Nimble.fail(String(describing: assertion))
                }
            }
        }
    }

    func testNormalizingSignature_expectFailure() {
        normalizingCasesExpectFailure.forEach { (testCase: ECCurveNormalizeTest) in
            let testName = testCase.test
            let signature = ResourceLoader.loadResourceAsData(
                resource: testCase.signature,
                withExtension: "dat",
                directory: "DSA"
            )
            let errors = Nimble.gatherFailingExpectations(silently: false) {
                expect {
                    try testCase.curve.normalize(signature: signature)
                }.to(throwError())
            }
            if !errors.isEmpty {
                Nimble.fail("Test (DSA-Normalize): [\(testName)] Should have failed, but succeeded!")
                errors.forEach { assertion in
                    Nimble.fail(String(describing: assertion))
                }
            }
        }
    }
}
