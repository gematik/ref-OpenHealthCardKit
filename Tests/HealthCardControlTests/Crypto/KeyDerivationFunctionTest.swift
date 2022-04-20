//
//  Copyright (c) 2022 gematik GmbH
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

import DataKit
@testable import HealthCardControl
import Nimble
import XCTest

final class KeyDerivationFunctionTest: XCTestCase {
    // swiftlint:disable force_try
    private let secretK = try! Data(hex: "2ECA74E72CD6C1E0DA235093569984987C34A9F4D34E4E60FB0AD87B983CDC62")

    func testAes128KeyDerivation() {
        let sharedSecret = Data([0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38]) // =Data("12345678".utf8)
        let expected = Data([0x66, 0x3E, 0xAB, 0xAB, 0xA9, 0x9E, 0x95, 0x4E, 0x8D, 0x22, 0x88, 0x95, 0x40,
                             0xED, 0xC6, 0x6C])

        expect {
            KeyDerivationFunction.deriveKey(from: sharedSecret, funcType: .aes128, mode: .password)
        } == expected
    }

    func testAES128KeyModeEnc() {
        let expected = try! Data(hex: "AB5541629D18E5F33EE2B13DBDCDBE84")
        expect {
            KeyDerivationFunction.deriveKey(from: self.secretK, mode: .enc)
        } == expected
    }

    func testAES128KeyModeMac() {
        let expected = try! Data(hex: "E13D3757C7D9073794A3D7CA94B22D30")
        expect {
            KeyDerivationFunction.deriveKey(from: self.secretK, mode: .mac)
        } == expected
    }

    func testAES128KeyModePassword() {
        let expected = try! Data(hex: "74C1F5E712B53BAAA3B02B182E0961B9")
        expect {
            KeyDerivationFunction.deriveKey(from: self.secretK, mode: .password)
        } == expected
    }

    static let allTests = [
        ("testAes128KeyDerivation", testAes128KeyDerivation),
        ("testAES128KeyModeEnc", testAES128KeyModeEnc),
        ("testAES128KeyModeMac", testAES128KeyModeMac),
        ("testAES128KeyModePassword", testAES128KeyModePassword),
    ]
}
