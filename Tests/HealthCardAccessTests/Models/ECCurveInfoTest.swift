//
//  Copyright (c) 2023 gematik GmbH
//
//  Licensed under the Apache License, Version 2.0 (the License);
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an 'AS IS' BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import ASN1Kit
import DataKit
@testable import HealthCardAccess
import Nimble
import XCTest

final class ECCurveInfoTest: XCTestCase {
    typealias ECCurveNormalizeTest = (test: String, curve: ECCurveInfo, signature: String, normalized: String)
    let normalizingCases: [ECCurveNormalizeTest] = [
        (test: "ansix9p256r1", curve: ansix9p256r1, signature: "ansix9p256r1_signature.dat",
         normalized: "ansix9p256r1_signature_normalized.dat"),
        (test: "ansix9p384r1", curve: ansix9p384r1, signature: "ansix9p384r1_signature.dat",
         normalized: "ansix9p384r1_signature_normalized.dat"),
        (test: "brainpoolP256r1", curve: brainpoolP256r1, signature: "brainpoolP256r1_signature.dat",
         normalized: "brainpoolP256r1_signature_normalized.dat"),
        (test: "brainpoolP384r1", curve: brainpoolP384r1, signature: "brainpoolP384r1_signature.dat",
         normalized: "brainpoolP384r1_signature_normalized.dat"),
        (test: "brainpoolP512r1", curve: brainpoolP512r1, signature: "brainpoolP512r1_signature.dat",
         normalized: "brainpoolP512r1_signature_normalized.dat"),
    ]

    let normalizingCasesExpectFailure: [ECCurveNormalizeTest] = [
        (test: "signature sequence too long", curve: ansix9p256r1, signature:
            "ansix9p256r1_signature_invalid_toolongsequence.dat",
            normalized: "ansix9p256r1_signature_normalized.dat"),
    ]

    func testNormalizingSignature() {
        let bundle = Bundle(for: ECCurveInfoTest.self)
        let path = "DSA"
        normalizingCases.forEach { (testCase: ECCurveNormalizeTest) in
            let testName = testCase.test
            let errors = Nimble.gatherFailingExpectations(silently: true) {
                expect {
                    try testCase.curve.normalize(signature: testCase.signature.loadAsResource(at: path, bundle: bundle))
                } == testCase.normalized.loadAsResource(at: path, bundle: bundle)
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
        let bundle = Bundle(for: ECCurveInfoTest.self)
        let path = "DSA"
        normalizingCasesExpectFailure.forEach { (testCase: ECCurveNormalizeTest) in
            let testName = testCase.test
            let errors = Nimble.gatherFailingExpectations(silently: false) {
                expect {
                    try testCase.curve.normalize(signature: testCase.signature.loadAsResource(at: path, bundle: bundle))
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

    static let allTests = [
        ("testNormalizingSignature", testNormalizingSignature),
        ("testNormalizingSignature_expectFailure", testNormalizingSignature_expectFailure),
    ]
}
