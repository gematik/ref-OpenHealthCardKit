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

import Foundation
@testable import HealthCardControl
import Nimble
import XCTest

final class KeyAgreementTest: XCTestCase {

    //swiftlint:disable force_try
    func testExtractNonceZ() {
        let nonceZResponse = try! Data(hex: "7C1280101F73E8CE8CF49E4B4BFF301F2BB0D5D4")
        let expected = try! Data(hex: "1F73E8CE8CF49E4B4BFF301F2BB0D5D4")

        expect {
            try KeyAgreement.extractPrimitive(constructedAsn1: nonceZResponse)
        } == expected
    }

    func testExtractProtocolIdentifier() {
        let efAccessResponse = try! Data(hex: "31143012060A04007F0007020204020202010202010D")
        let expected = try! Data(hex: "04007F00070202040202")

        expect {
            try KeyAgreement.extractProtocolIdentifier(from: efAccessResponse)
        } == expected
    }

    func testExtractPublicKeyData() {
        // swiftlint:disable line_length
        let publicKeyResponse = try! Data(hex: "7C438241042AAFEB6F92346132330D8EE421406CBFE14F86C3351FCAC0056F1B29E4BD489214DC6769542FF340DD3EFD65526B99A03A08A58982815DDC11EF6B3A86586671")
        let expected = try! Data(hex: "042AAFEB6F92346132330D8EE421406CBFE14F86C3351FCAC0056F1B29E4BD489214DC6769542FF340DD3EFD65526B99A03A08A58982815DDC11EF6B3A86586671")
        // swiftlint:enable line_length

        expect {
            try KeyAgreement.extractPrimitive(constructedAsn1: publicKeyResponse)
        } == expected
    }

    func testPaceKeyKeyMac() {

        guard let theirPublicKey = try? ECPoint.parse(encoded: try! Data(hex: "0402E66D08A89A0AB2967D5CA4B1D0B90E9520D097CA3627BFBF714E987C575A3401ECA80189CCC27AD80E48D0FCBCFCAC3C29E6D481177D03542578A2A4AF1511"))
                // swiftlint:disable:previous line_length
                else {
            Nimble.fail("Could not create ")
            return
        }
        let myKeyPair = EcdhKeyPairGenerator(seed: 1).generateKeyPair()
        let expected = try! Data(hex: "0842D303FF8B33102027238607D44D49")

        expect {
            let paceKey = try KeyAgreement.derivePaceKeyEcdhAes128(publicKey: theirPublicKey, keyPair: myKeyPair)
            return paceKey.mac
        } == expected

    }

    static let allTests = [
        ("testExtractNonceZ", testExtractNonceZ),
        ("testExtractProtocolIdentifier", testExtractProtocolIdentifier),
        ("testExtractPublicKeyData", testExtractPublicKeyData),
        ("testPaceKeyKeyMac", testPaceKeyKeyMac)
    ]
}
