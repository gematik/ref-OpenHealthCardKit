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

import CommonCrypto
@testable import HealthCardControl
import Nimble
import XCTest

final class AESTests: XCTestCase {
    // swiftlint:disable force_try
    func testAes128Decipher() {
        let encKey = Data([0x66, 0x3E, 0xAB, 0xAB, 0xA9, 0x9E, 0x95, 0x4E, 0x8D, 0x22, 0x88, 0x95, 0x40, 0xED,
                           0xC6, 0x6C])
        let nonceZ = Data([0x5B, 0x46, 0x16, 0x16, 0x5A, 0x08, 0xE7, 0xD9, 0x01, 0x6B, 0x0B, 0xE1, 0xCE, 0xB5,
                           0x3F, 0x9E])
        let expected = Data([0x9F, 0xFB, 0x42, 0xA2, 0x24, 0x68, 0x0F, 0x72, 0x1A, 0x3A, 0xDE, 0x59, 0x93, 0xC0,
                             0xFD, 0x11])

        expect {
            try AES.CBC128.decrypt(data: nonceZ, key: encKey)
        } == expected
    }

    func testAes128Decipher2() {
        let encKey = Data([0x66, 0x3E, 0xAB, 0xAB, 0xA9, 0x9E, 0x95, 0x4E, 0x8D, 0x22, 0x88, 0x95, 0x40, 0xED,
                           0xC6, 0x6C])

        let nonceZ = try! Data(hex: "A18957E11BF5F8ECD4B752DF7A87C43D")
        let expected = try! Data(hex: "85E02B606D2EF6CEA79077156C5F670D")

        expect {
            try AES.CBC128.decrypt(data: nonceZ, key: encKey)
        } == expected
    }

    func testAes128Encipher() {
        let encKey = Data([0x66, 0x3E, 0xAB, 0xAB, 0xA9, 0x9E, 0x95, 0x4E, 0x8D, 0x22, 0x88, 0x95, 0x40, 0xED,
                           0xC6, 0x6C])
        let expected = Data([0x5B, 0x46, 0x16, 0x16, 0x5A, 0x08, 0xE7, 0xD9, 0x01, 0x6B, 0x0B, 0xE1, 0xCE, 0xB5,
                             0x3F, 0x9E])
        let nonceS = Data([0x9F, 0xFB, 0x42, 0xA2, 0x24, 0x68, 0x0F, 0x72, 0x1A, 0x3A, 0xDE, 0x59, 0x93, 0xC0,
                           0xFD, 0x11])

        expect {
            try AES.CBC128.encrypt(data: nonceS, key: encKey)
        } == expected
    }

    func testAes128Encipher2() {
        let encKey = Data([0x66, 0x3E, 0xAB, 0xAB, 0xA9, 0x9E, 0x95, 0x4E,
                           0x8D, 0x22, 0x88, 0x95, 0x40, 0xED, 0xC6, 0x6C])
        let nonceS = try! Data(hex: "85E02B606D2EF6CEA79077156C5F670D")
        let expected = try! Data(hex: "A18957E11BF5F8ECD4B752DF7A87C43D")

        expect {
            try AES.CBC128.encrypt(data: nonceS, key: encKey)
        } == expected
    }

    func testAes128CBCEncipherWithInitVector() {
        let encKey = try! Data(hex: "68406B4162100563D9C901A6154D2901")
        let initVector = try! Data(hex: "7E2796A6F180223866E9DDB94F3E69A4")
        let input = try! Data(hex: "05060708090A80000000000000000000")
        let expected = try! Data(hex: "496C26D36306679609665A385C54DB37")
        expect {
            try AES.CBC128.encrypt(data: input, key: encKey, initVector: initVector)
        } == expected
    }

    static let allTests = [
        ("testAes128Decipher", testAes128Decipher),
        ("testAes128Decipher2", testAes128Decipher2),
        ("testAes128Encipher", testAes128Encipher),
        ("testAes128Encipher2", testAes128Encipher2),
    ]
}
