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
@testable import HealthCardAccess
import Nimble
import XCTest

final class Format2PinTest: XCTestCase {
    func testValidPin() {
        // Test min valid length
        let expected = "241234FFFFFFFFFF"
        expect {
            try Format2Pin(pincode: "1234").pin.hexString()
        } == expected

        // Test max valid length
        let expected2 = "2C123456789012FF"
        expect {
            try Format2Pin(pincode: "123456789012").pin.hexString()
        } == expected2
    }

    func testInvalidCharacterPin() {
        let invalidPin = "abc123"
        expect {
            try Format2Pin(pincode: invalidPin)
        }.to(throwError(
            Format2Pin.Error.illegalArgument("Invalid pin: [\(invalidPin)] does not conform to regex: [^[0-9]{4,12}$]")
        ))
    }

    func testTooShortPin() {
        let shortPin = "123"
        expect {
            try Format2Pin(pincode: shortPin)
        }.to(throwError(
            Format2Pin.Error.illegalArgument("Invalid pin: [\(shortPin)] does not conform to regex: [^[0-9]{4,12}$]")
        ))
    }

    func testTooLongPin() {
        let longPin = "1234567890123"
        expect {
            try Format2Pin(pincode: longPin)
        }.to(throwError(
            Format2Pin.Error.illegalArgument("Invalid pin: [\(longPin)] does not conform to regex: [^[0-9]{4,12}$]")
        ))
    }

    func testPinFromLiteral() {
        expect {
            ("123456" as Format2Pin).pin.hexString()
        } == "26123456FFFFFFFF"
    }

    static let allTests = [
        ("testValidPin", testValidPin),
        ("testInvalidCharacterPin", testInvalidCharacterPin),
        ("testTooShortPin", testTooShortPin),
        ("testTooLongPin", testTooLongPin),
    ]
}
